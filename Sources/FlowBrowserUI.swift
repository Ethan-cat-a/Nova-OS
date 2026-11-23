import AppKit
import WebKit

/// Native drag source. Only tab UUIDs are placed on the drag pasteboard.
final class FlowDraggableTabButton: NSButton, NSDraggingSource {
    static let tabPasteboardType = NSPasteboard.PasteboardType("com.novaos.flow.tab-id")
    private var draggingTab = false

    override func mouseDragged(with event: NSEvent) {
        guard !draggingTab, let identifier, bounds.width > 0 else { return }
        let item = NSPasteboardItem()
        item.setString(identifier.rawValue, forType: Self.tabPasteboardType)
        let symbol = NSImage(systemSymbolName: "square.on.square", accessibilityDescription: "Move Tab")
        let picture = NSImage(size: NSSize(width: 195, height: 35))
        picture.lockFocus()
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 195, height: 35), xRadius: 9, yRadius: 9).fill()
        symbol?.draw(in: NSRect(x: 10, y: 8, width: 18, height: 18))
        String(title.prefix(25)).draw(in: NSRect(x: 36, y: 10, width: 154, height: 22),
                                      withAttributes: [.font: NSFont.systemFont(ofSize: 12),
                                                       .foregroundColor: NSColor.labelColor])
        picture.unlockFocus()

        let drag = NSDraggingItem(pasteboardWriter: item)
        drag.setDraggingFrame(NSRect(origin: .zero, size: picture.size), contents: picture)
        draggingTab = true
        beginDraggingSession(with: [drag], event: event, source: self)
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        .move
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        draggingTab = false
    }
}

struct FlowGalleryItem {
    let id: UUID
    let title: String
    let detail: String
    let pinned: Bool
    let webView: WKWebView?
    let isLoaded: Bool
}

/// Live, in-memory tab snapshots. Never saves snapshots to disk or preloads dormant tabs.
@MainActor
final class FlowGalleryController: NSObject {
    private var panel: NSPanel?
    private var onSelect: ((UUID) -> Void)?
    private var ids: [String: UUID] = [:]

    func show(items: [FlowGalleryItem], onSelect: @escaping (UUID) -> Void) {
        self.onSelect = onSelect
        panel?.close()
        ids.removeAll()

        let screen = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 865, height: 590),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false
        )
        screen.title = "NOVA Flow — Tab Gallery"
        screen.minSize = NSSize(width: 610, height: 370)
        screen.isReleasedWhenClosed = false
        screen.appearance = nil

        let shell = NSView()
        let heading = NSTextField(labelWithString: "YOUR TABS  ·  \(items.count) OPEN")
        heading.font = .systemFont(ofSize: 12, weight: .semibold)
        heading.textColor = .secondaryLabelColor
        heading.translatesAutoresizingMaskIntoConstraints = false

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        let grid = NSStackView()
        grid.orientation = .vertical
        grid.alignment = .leading
        grid.distribution = .fill
        grid.spacing = 12
        grid.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        grid.translatesAutoresizingMaskIntoConstraints = false

        for start in stride(from: 0, to: items.count, by: 3) {
            let row = NSStackView()
            row.orientation = .horizontal
            row.alignment = .top
            row.spacing = 12
            for index in start..<min(start + 3, items.count) {
                let item = items[index]
                let title = String((item.pinned ? "📌 " : "") + item.title)
                let card = NSButton(
                    title: String(title.prefix(36)), target: self, action: #selector(selectCard(_:))
                )
                let token = UUID().uuidString
                card.identifier = NSUserInterfaceItemIdentifier(token)
                ids[token] = item.id
                card.bezelStyle = .rounded
                card.imagePosition = .imageAbove
                card.imageScaling = .scaleProportionallyDown
                card.font = .systemFont(ofSize: 12, weight: .medium)
                card.image = NSImage(systemSymbolName: item.isLoaded ? "globe" : "moon.zzz",
                                     accessibilityDescription: "Tab preview")
                card.toolTip = item.detail
                card.widthAnchor.constraint(equalToConstant: 246).isActive = true
                card.heightAnchor.constraint(equalToConstant: 164).isActive = true
                row.addArrangedSubview(card)

                // Snapshot only the previously loaded page. Snapshot failures retain an icon.
                if item.isLoaded, let webView = item.webView, !webView.isLoading {
                    let config = WKSnapshotConfiguration()
                    config.rect = CGRect(origin: .zero,
                                         size: CGSize(width: max(webView.bounds.width, 300),
                                                      height: max(webView.bounds.height, 250)))
                    config.snapshotWidth = NSNumber(value: 240)
                    webView.takeSnapshot(with: config) { [weak card] image, _ in
                        guard let image, let card else { return }
                        card.image = image
                    }
                }
            }
            grid.addArrangedSubview(row)
        }

        if items.isEmpty {
            let empty = NSTextField(labelWithString: "No tabs in this space yet.")
            empty.textColor = .secondaryLabelColor
            grid.addArrangedSubview(empty)
        }
        scroll.documentView = grid
        shell.addSubview(heading)
        shell.addSubview(scroll)
        NSLayoutConstraint.activate([
            heading.topAnchor.constraint(equalTo: shell.topAnchor, constant: 20),
            heading.leadingAnchor.constraint(equalTo: shell.leadingAnchor, constant: 22),
            scroll.leadingAnchor.constraint(equalTo: shell.leadingAnchor, constant: 12),
            scroll.trailingAnchor.constraint(equalTo: shell.trailingAnchor, constant: -12),
            scroll.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 12),
            scroll.bottomAnchor.constraint(equalTo: shell.bottomAnchor, constant: -12),
            grid.widthAnchor.constraint(greaterThanOrEqualTo: scroll.contentView.widthAnchor)
        ])
        screen.contentView = shell
        screen.center()
        panel = screen
        screen.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func selectCard(_ sender: NSButton) {
        guard let raw = sender.identifier?.rawValue, let id = ids[raw] else { return }
        panel?.close()
        onSelect?(id)
    }
}

/// Text-only, local Focus Reader. The existing page stays loaded and untouched.
@MainActor
final class FlowReaderController: NSObject {
    private var panel: NSPanel?
    private var textView: NSTextView?
    private var fontSize: CGFloat = 17

    func show(title: String, body: String, source: URL) {
        panel?.close()
        fontSize = 17
        let reader = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 790, height: 710),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered, defer: false
        )
        reader.title = "NOVA Focus Reader — \(String(title.prefix(90)))"
        reader.minSize = NSSize(width: 490, height: 380)
        reader.isReleasedWhenClosed = false
        reader.appearance = nil

        let shell = NSView()
        let vertical = NSStackView()
        vertical.orientation = .vertical
        vertical.alignment = .width
        vertical.spacing = 13
        vertical.translatesAutoresizingMaskIntoConstraints = false
        shell.addSubview(vertical)
        NSLayoutConstraint.activate([
            vertical.leadingAnchor.constraint(equalTo: shell.leadingAnchor, constant: 22),
            vertical.trailingAnchor.constraint(equalTo: shell.trailingAnchor, constant: -22),
            vertical.topAnchor.constraint(equalTo: shell.topAnchor, constant: 22),
            vertical.bottomAnchor.constraint(equalTo: shell.bottomAnchor, constant: -20)
        ])

        let controls = NSStackView()
        controls.orientation = .horizontal
        controls.alignment = .centerY
        controls.spacing = 12
        let heading = NSTextField(labelWithString: "FOCUS READER")
        heading.font = .systemFont(ofSize: 12, weight: .semibold)
        heading.textColor = .secondaryLabelColor
        controls.addArrangedSubview(heading)
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        controls.addArrangedSubview(spacer)
        let smaller = NSButton(title: "A−", target: self, action: #selector(decreaseFont))
        smaller.bezelStyle = .rounded
        smaller.toolTip = "Decrease text size"
        controls.addArrangedSubview(smaller)
        let larger = NSButton(title: "A+", target: self, action: #selector(increaseFont))
        larger.bezelStyle = .rounded
        larger.toolTip = "Increase text size"
        controls.addArrangedSubview(larger)
        vertical.addArrangedSubview(controls)

        let titleLabel = NSTextField(wrappingLabelWithString: String(title.prefix(200)))
        titleLabel.font = .systemFont(ofSize: 23, weight: .semibold)
        titleLabel.textColor = .labelColor
        vertical.addArrangedSubview(titleLabel)

        let origin = NSTextField(labelWithString: source.host ?? source.absoluteString)
        origin.font = .systemFont(ofSize: 12)
        origin.textColor = .secondaryLabelColor
        vertical.addArrangedSubview(origin)

        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        let text = NSTextView()
        text.isEditable = false
        text.isSelectable = true
        text.drawsBackground = false
        text.textContainerInset = NSSize(width: 12, height: 16)
        text.isVerticallyResizable = true
        text.isHorizontallyResizable = false
        text.autoresizingMask = [.width]
        text.textContainer?.widthTracksTextView = true
        text.string = body
        text.font = .systemFont(ofSize: fontSize)
        text.textColor = .labelColor
        scroll.documentView = text
        scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 160).isActive = true
        vertical.addArrangedSubview(scroll)

        let note = NSTextField(labelWithString: "Extracted locally from the current page · Original tab remains open")
        note.textColor = .tertiaryLabelColor
        note.font = .systemFont(ofSize: 11)
        vertical.addArrangedSubview(note)

        reader.contentView = shell
        panel = reader
        textView = text
        reader.center()
        reader.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func increaseFont() {
        fontSize = min(28, fontSize + 2)
        textView?.font = .systemFont(ofSize: fontSize)
    }

    @objc private func decreaseFont() {
        fontSize = max(12, fontSize - 2)
        textView?.font = .systemFont(ofSize: fontSize)
    }
}
