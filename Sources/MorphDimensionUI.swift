import AppKit
import WebKit

@MainActor
enum MorphController {
    static let key = "NovaOS.MorphRules.v1"
    static func remembered(for url: URL) -> [MorphEffect] {
        guard let origin = MorphEffect.origin(url),
              let rules = UserDefaults.standard.dictionary(forKey: key),
              let raw = rules[origin] as? [String] else { return [] }
        return raw.compactMap(MorphEffect.init(rawValue:))
    }
    static func remember(_ effects: [MorphEffect], for url: URL) {
        guard let origin = MorphEffect.origin(url) else { return }
        var rules = UserDefaults.standard.dictionary(forKey: key) ?? [:]
        if effects.isEmpty { rules.removeValue(forKey: origin) }
        else {
            if rules.count >= 100 && rules[origin] == nil { return }
            rules[origin] = effects.map(\.rawValue)
        }
        UserDefaults.standard.set(rules, forKey: key)
    }

    /// Pass only constant CSS as a structured argument in a separate JS world.
    static func apply(_ effects: [MorphEffect], to webView: WKWebView, pageURL: URL,
                      completion: @escaping (Bool) -> Void = { _ in }) {
        guard webView.url == pageURL, let origin = MorphEffect.origin(pageURL) else { completion(false); return }
        let script = #"""
        if (location.origin !== expectedOrigin || location.href !== expectedURL) return false;
        const id = 'nova-os-morph-reviewed-css-v1';
        const previous = document.getElementById(id);
        if (previous && previous.tagName === 'STYLE') previous.remove();
        if (css.length) {
          const style = document.createElement('style');
          style.id = id;
          style.textContent = css;
          (document.head || document.documentElement).appendChild(style);
        }
        return true;
        """#
        webView.callAsyncJavaScript(script, arguments: [
            "expectedOrigin": origin, "expectedURL": pageURL.absoluteString,
            "css": MorphEffect.stylesheet(effects)
        ], in: nil, in: .defaultClient) { result in
            switch result {
            case .success(let value): completion((value as? Bool) == true)
            case .failure: completion(false)
            }
        }
    }

    static func show(for webView: WKWebView) {
        guard let url = webView.url, MorphEffect.origin(url) != nil else { return }
        let alert = NSAlert()
        alert.messageText = "NOVA Morph"
        alert.informativeText = "Describe a change, or choose a preset. Morph uses reviewed local styles, never sends the page to AI, and leaves website controls intact. You can reset at any time."
        let box = NSStackView()
        box.orientation = .vertical
        box.alignment = .width
        box.spacing = 8
        box.frame = NSRect(x: 0, y: 0, width: 410, height: 118)
        let field = NSTextField(string: "")
        field.placeholderString = "e.g. larger text and dim recommendations"
        let picker = NSPopUpButton()
        picker.addItems(withTitles: ["Interpret my instruction"] + MorphEffect.allCases.map(\.title))
        let rememberBox = NSButton(checkboxWithTitle: "Remember for this exact site", target: nil, action: nil)
        rememberBox.state = remembered(for: url).isEmpty ? .off : .on
        box.addArrangedSubview(field)
        box.addArrangedSubview(picker)
        box.addArrangedSubview(rememberBox)
        alert.accessoryView = box
        alert.addButton(withTitle: "Apply")
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertThirdButtonReturn { return }
        if response == .alertSecondButtonReturn {
            apply([], to: webView, pageURL: url) { success in
                if success { remember([], for: url) }
            }
            return
        }
        guard response == .alertFirstButtonReturn else { return }
        let index = picker.indexOfSelectedItem
        let effects = index > 0 && index <= MorphEffect.allCases.count
            ? [MorphEffect.allCases[index-1]] : MorphEffect.interpret(field.stringValue)
        guard !effects.isEmpty else {
            let explanation = NSAlert()
            explanation.messageText = "Choose a supported transformation"
            explanation.informativeText = "Try larger text, high contrast, native typography, spotlight video, or dim recommendations. Morph does not execute arbitrary instructions."
            explanation.runModal()
            return
        }
        let persist = rememberBox.state == .on
        apply(effects, to: webView, pageURL: url) { success in
            guard success else {
                let error = NSAlert()
                error.messageText = "Morph could not apply this change"
                error.informativeText = "The page may have changed or may restrict custom styles. Try again on the loaded page."
                error.runModal()
                return
            }
            remember(persist ? effects : [], for: url)
        }
    }
}

private final class DimensionCanvas: NSView {
    override var isFlipped: Bool { true }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath(rect: dirtyRect).fill()
        NSColor.secondaryLabelColor.withAlphaComponent(0.16).setFill()
        let startX = Int(dirtyRect.minX / 24) * 24
        let startY = Int(dirtyRect.minY / 24) * 24
        for x in stride(from: startX, through: Int(dirtyRect.maxX), by: 24) {
            for y in stride(from: startY, through: Int(dirtyRect.maxY), by: 24) {
                NSBezierPath(ovalIn: NSRect(x: CGFloat(x), y: CGFloat(y), width: 1.5, height: 1.5)).fill()
            }
        }
    }
}

private final class DimensionDragHandle: NSView {
    var onMove: ((NSPoint, Bool) -> Void)?
    override func hitTest(_ point: NSPoint) -> NSView? { super.hitTest(point) == nil ? nil : self }
    private var offset: NSPoint = .zero
    override func mouseDown(with event: NSEvent) {
        guard let card = superview, let canvas = card.superview else { return }
        let point = canvas.convert(event.locationInWindow, from: nil)
        offset = NSPoint(x: point.x - card.frame.minX, y: point.y - card.frame.minY)
    }
    override func mouseDragged(with event: NSEvent) { move(event, finished: false) }
    override func mouseUp(with event: NSEvent) { move(event, finished: true) }
    private func move(_ event: NSEvent, finished: Bool) {
        guard let canvas = superview?.superview else { return }
        let point = canvas.convert(event.locationInWindow, from: nil)
        onMove?(NSPoint(x: point.x-offset.x, y: point.y-offset.y), finished)
    }
}

@MainActor
final class DimensionController: NSObject, NSWindowDelegate, WKNavigationDelegate {
    struct Link {
        let title: String
        let url: URL
    }
    private var panel: NSPanel?
    private var canvas: DimensionCanvas?
    private var scroll: NSScrollView?
    private var status: NSTextField?
    private var boards = DimensionStore.load()
    private var spaceID: UUID?
    private var links: [Link] = []
    private var live: [UUID: WKWebView] = [:]
    private var openInBrowser: ((URL) -> Void)?
    private var board: DimensionBoard {
        get { spaceID.flatMap { boards[$0] } ?? DimensionBoard() }
        set { if let spaceID { boards[spaceID] = newValue; DimensionStore.save(boards) } }
    }

    func close() {
        live.values.forEach { $0.stopLoading(); $0.navigationDelegate = nil }
        live.removeAll()
        panel?.close()
        panel = nil
        canvas = nil
    }

    func windowWillClose(_ notification: Notification) {
        live.values.forEach { $0.stopLoading(); $0.navigationDelegate = nil; $0.removeFromSuperview() }
        live.removeAll()
        panel = nil
        canvas = nil
    }

    func show(space: UUID, name: String, validSpaces: Set<UUID>, links: [Link],
              open: @escaping (URL) -> Void) {
        close()
        boards = boards.filter { validSpaces.contains($0.key) }
        spaceID = space
        self.links = links
        openInBrowser = open
        let window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 1050, height: 720),
                             styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "NOVA Dimension — \(name)"
        window.minSize = NSSize(width: 760, height: 450)
        window.isReleasedWhenClosed = false
        window.delegate = self
        let shell = NSView()
        let bar = NSStackView()
        bar.orientation = .horizontal
        bar.spacing = 8
        bar.alignment = .centerY
        bar.translatesAutoresizingMaskIntoConstraints = false
        let heading = NSTextField(labelWithString: "DIMENSION")
        heading.font = .systemFont(ofSize: 15, weight: .bold)
        bar.addArrangedSubview(heading)
        for (name, action) in [("Import tabs", #selector(importTabs)), ("Add URL", #selector(addURL)), ("Add note", #selector(addNote)), ("−", #selector(zoomOut)), ("+", #selector(zoomIn))] {
            let b = NSButton(title: name, target: self, action: action)
            b.bezelStyle = .rounded
            bar.addArrangedSubview(b)
        }
        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingTail
        bar.addArrangedSubview(label)
        status = label
        let scroller = NSScrollView()
        scroller.translatesAutoresizingMaskIntoConstraints = false
        scroller.hasVerticalScroller = true
        scroller.hasHorizontalScroller = true
        scroller.allowsMagnification = true
        scroller.minMagnification = 0.35
        scroller.maxMagnification = 1.5
        let surface = DimensionCanvas(frame: NSRect(x: 0, y: 0, width: DimensionBoard.width, height: DimensionBoard.height))
        scroller.documentView = surface
        scroll = scroller
        canvas = surface
        shell.addSubview(bar)
        shell.addSubview(scroller)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: shell.leadingAnchor, constant: 12),
            bar.trailingAnchor.constraint(equalTo: shell.trailingAnchor, constant: -12),
            bar.topAnchor.constraint(equalTo: shell.topAnchor, constant: 12),
            scroller.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 10),
            scroller.leadingAnchor.constraint(equalTo: shell.leadingAnchor),
            scroller.trailingAnchor.constraint(equalTo: shell.trailingAnchor),
            scroller.bottomAnchor.constraint(equalTo: shell.bottomAnchor)
        ])
        window.contentView = shell
        panel = window
        redraw()
        window.center()
        window.makeKeyAndOrderFront(nil)
        scroller.contentView.scroll(to: .zero)
        scroller.reflectScrolledClipView(scroller.contentView)
    }

    private func redraw() {
        guard let canvas else { return }
        live.values.forEach { $0.removeFromSuperview() }
        canvas.subviews.forEach { $0.removeFromSuperview() }
        for tile in board.tiles { canvas.addSubview(makeCard(tile)) }
        status?.stringValue = "\(board.tiles.count)/40 cards · Drag header · Scroll / zoom · \(live.count)/4 live"
    }

    private func makeCard(_ tile: DimensionTile) -> NSView {
        let card = NSView(frame: NSRect(x: tile.x, y: tile.y, width: DimensionBoard.tileWidth, height: DimensionBoard.tileHeight))
        card.wantsLayer = true
        card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        card.layer?.cornerRadius = 12
        card.layer?.borderColor = NSColor.separatorColor.cgColor
        card.layer?.borderWidth = 1
        let handle = DimensionDragHandle(frame: NSRect(x: 0, y: 224, width: 360, height: 36))
        handle.wantsLayer = true
        handle.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor
        handle.onMove = { [weak self, weak card] point, finished in
            guard let self, let card else { return }
            let pos = DimensionBoard.position(Double(point.x), Double(point.y))
            card.setFrameOrigin(NSPoint(x: pos.0, y: pos.1))
            if finished {
                var current = self.board
                if let index = current.tiles.firstIndex(where: { $0.id == tile.id }) {
                    current.tiles[index].x = pos.0
                    current.tiles[index].y = pos.1
                    self.board = current
                }
            }
        }
        // A non-interactive drawn title keeps the whole header draggable.
        let title = NSTextField(labelWithString: "↕  " + (tile.title.isEmpty ? "Untitled" : tile.title))
        title.frame = NSRect(x: 12, y: 8, width: 334, height: 20)
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.lineBreakMode = .byTruncatingTail
        handle.addSubview(title)
        card.addSubview(handle)

        func button(_ name: String, _ selector: Selector, x: CGFloat, width: CGFloat) {
            let b = NSButton(title: name, target: self, action: selector)
            b.frame = NSRect(x: x, y: 7, width: width, height: 28)
            b.bezelStyle = .rounded
            b.identifier = NSUserInterfaceItemIdentifier(tile.id.uuidString)
            card.addSubview(b)
        }
        if let url = tile.safeURL {
            button(live[tile.id] == nil ? "Load live" : "Pause", #selector(toggleLive(_:)), x: 8, width: 84)
            button("Open tab", #selector(openTile(_:)), x: 94, width: 82)
            if let web = live[tile.id] {
                web.frame = NSRect(x: 8, y: 40, width: 344, height: 179)
                card.addSubview(web)
            } else {
                let detail = NSTextField(wrappingLabelWithString: "◉  \(url.host ?? "Website")\n\n\(url.absoluteString)\n\nLive preview is paused. Click Load live to connect.")
                detail.font = .systemFont(ofSize: 12)
                detail.textColor = .secondaryLabelColor
                detail.frame = NSRect(x: 16, y: 52, width: 327, height: 148)
                card.addSubview(detail)
            }
        } else {
            button("Edit note", #selector(editNote(_:)), x: 8, width: 84)
            let content = NSTextField(wrappingLabelWithString: tile.note)
            content.frame = NSRect(x: 16, y: 48, width: 327, height: 164)
            content.font = .systemFont(ofSize: 14)
            content.maximumNumberOfLines = 9
            card.addSubview(content)
        }
        button("Remove", #selector(removeTile(_:)), x: 266, width: 84)
        return card
    }

    private func tileID(_ sender: NSButton) -> UUID? { sender.identifier.flatMap { UUID(uuidString: $0.rawValue) } }
    @objc private func importTabs() {
        var current = board
        for link in links where !current.tiles.contains(where: { $0.url == link.url.absoluteString }) {
            _ = current.add(url: link.url, title: link.title)
        }
        board = current
        redraw()
    }
    @objc private func addURL() {
        guard let input = prompt("Add website", message: "Enter an HTTP or HTTPS address. The card will not load until you choose Load live.", current: ""),
              case .website(let url)? = NovaNavigation.resolve(input), MorphEffect.origin(url) != nil else { return }
        var current = board
        if current.add(url: url, title: url.host ?? "Website") { board = current; redraw() }
        else { warn("Canvas is full or the URL is too long.") }
    }
    @objc private func addNote() {
        guard let note = prompt("Add note", message: "Notes are saved locally in this Space.", current: ""), !note.isEmpty else { return }
        var current = board
        if current.add(url: nil, title: "Note", note: note) { board = current; redraw() }
        else { warn("Canvas is full.") }
    }
    @objc private func editNote(_ sender: NSButton) {
        guard let id = tileID(sender) else { return }
        var current = board
        guard let index = current.tiles.firstIndex(where: { $0.id == id }),
              let note = prompt("Edit note", message: "Your note stays on this Mac.", current: current.tiles[index].note) else { return }
        current.tiles[index].note = String(note.prefix(2000))
        board = current
        redraw()
    }
    @objc private func removeTile(_ sender: NSButton) {
        guard let id = tileID(sender) else { return }
        if let web = live.removeValue(forKey: id) { web.stopLoading(); web.navigationDelegate = nil }
        var current = board
        current.tiles.removeAll { $0.id == id }
        board = current
        redraw()
    }
    @objc private func openTile(_ sender: NSButton) {
        guard let id = tileID(sender), let url = board.tiles.first(where: { $0.id == id })?.safeURL else { return }
        openInBrowser?(url)
    }
    @objc private func toggleLive(_ sender: NSButton) {
        guard let id = tileID(sender), let url = board.tiles.first(where: { $0.id == id })?.safeURL else { return }
        if let web = live.removeValue(forKey: id) {
            web.stopLoading()
            web.navigationDelegate = nil
        } else {
            guard live.count < 4 else { warn("Pause a live card before loading another. Up to four may run at once."); return }
            let config = WKWebViewConfiguration()
            config.websiteDataStore = .nonPersistent()
            let web = WKWebView(frame: .zero, configuration: config)
            web.navigationDelegate = self
            live[id] = web
            web.load(URLRequest(url: url))
        }
        redraw()
    }
    @objc private func zoomOut() { if let scroll { scroll.magnification = max(scroll.minMagnification, scroll.magnification - 0.15) } }
    @objc private func zoomIn() { if let scroll { scroll.magnification = min(scroll.maxMagnification, scroll.magnification + 0.15) } }

    private func prompt(_ title: String, message: String, current: String) -> String? {
        let dialog = NSAlert()
        dialog.messageText = title
        dialog.informativeText = message
        let field = NSTextField(string: current)
        field.frame = NSRect(x: 0, y: 0, width: 380, height: 25)
        dialog.accessoryView = field
        dialog.addButton(withTitle: "Save")
        dialog.addButton(withTitle: "Cancel")
        return dialog.runModal() == .alertFirstButtonReturn ? field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) : nil
    }
    private func warn(_ message: String) {
        let a = NSAlert(); a.messageText = message; a.runModal()
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, MorphEffect.origin(url) != nil,
              navigationAction.targetFrame != nil, !navigationAction.shouldPerformDownload else {
            decisionHandler(.cancel); return
        }
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .cancel)
    }
}
