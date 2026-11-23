import AppKit
import WebKit

/// Lightweight, native command/search popover shared by NOVA's tab and navigation actions.
@MainActor
final class OrbitCommandPaletteController: NSObject, NSSearchFieldDelegate {
    struct Item {
        let title: String
        let detail: String
        let symbol: String
        let perform: () -> Void
    }

    private weak var window: NSWindow?
    private weak var anchor: NSView?
    private let itemsProvider: (String) -> [Item]
    private var popover: NSPopover?
    private weak var searchField: NSSearchField?
    private weak var resultStack: NSStackView?
    private var visibleItems: [Item] = []
    private var itemIndices: [String: Int] = [:]

    init(window: NSWindow, anchor: NSView, items: @escaping (String) -> [Item]) {
        self.window = window
        self.anchor = anchor
        self.itemsProvider = items
        super.init()
    }

    func show() {
        guard let window, let anchor else { return }
        if popover?.isShown == true {
            popover?.performClose(nil)
            return
        }

        let container = NSView()
        let content = NSStackView()
        content.orientation = .vertical
        content.alignment = .width
        content.distribution = .fill
        content.spacing = 10
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])

        let heading = NSTextField(labelWithString: "NOVA ORBIT  /  COMMANDS")
        heading.font = .systemFont(ofSize: 10, weight: .semibold)
        heading.textColor = .secondaryLabelColor
        content.addArrangedSubview(heading)

        let search = NSSearchField()
        search.placeholderString = "Search tabs, bookmarks, history, commands"
        search.font = .systemFont(ofSize: 14)
        search.delegate = self
        search.target = self
        search.action = #selector(chooseFirst(_:))
        search.heightAnchor.constraint(equalToConstant: 34).isActive = true
        content.addArrangedSubview(search)

        let results = NSStackView()
        results.orientation = .vertical
        results.alignment = .width
        results.distribution = .fill
        results.spacing = 3
        content.addArrangedSubview(results)

        let hint = NSTextField(labelWithString: "Return to open  ·  Escape to close")
        hint.font = .systemFont(ofSize: 10)
        hint.textColor = .tertiaryLabelColor
        content.addArrangedSubview(hint)

        let controller = NSViewController()
        controller.view = container
        controller.preferredContentSize = NSSize(width: 490, height: 340)
        let panel = NSPopover()
        panel.behavior = .transient
        panel.animates = true
        panel.contentViewController = controller
        popover = panel
        searchField = search
        resultStack = results
        refreshResults()
        panel.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .maxY)
        window.makeFirstResponder(search)
    }

    func controlTextDidChange(_ notification: Notification) {
        guard notification.object as? NSSearchField === searchField else { return }
        refreshResults()
    }

    private func refreshResults() {
        guard let stack = resultStack else { return }
        let query = searchField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        visibleItems = Array(itemsProvider(query).prefix(7))
        itemIndices.removeAll()
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        if visibleItems.isEmpty {
            let label = NSTextField(labelWithString: "Nothing matches. Try a different search.")
            label.textColor = .secondaryLabelColor
            label.font = .systemFont(ofSize: 12)
            stack.addArrangedSubview(label)
        } else {
            for (index, item) in visibleItems.enumerated() {
                let row = NSButton(
                    title: item.title + "   ·   " + item.detail,
                    target: self, action: #selector(selectResult(_:))
                )
                row.identifier = NSUserInterfaceItemIdentifier(UUID().uuidString)
                row.image = NSImage(systemSymbolName: item.symbol, accessibilityDescription: item.title)
                row.imagePosition = .imageLeading
                row.alignment = .left
                row.bezelStyle = .inline
                row.isBordered = false
                row.lineBreakMode = .byTruncatingTail
                row.font = .systemFont(ofSize: 12, weight: .medium)
                row.toolTip = item.title + " — " + item.detail
                row.heightAnchor.constraint(equalToConstant: 34).isActive = true
                stack.addArrangedSubview(row)
                if let id = row.identifier?.rawValue { itemIndices[id] = index }
            }
        }
        popover?.contentViewController?.preferredContentSize =
            NSSize(width: 490, height: CGFloat(112 + max(1, visibleItems.count) * 37))
    }

    @objc private func selectResult(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue,
              let index = itemIndices[id], visibleItems.indices.contains(index) else { return }
        perform(visibleItems[index])
    }

    @objc private func chooseFirst(_ sender: Any?) {
        guard let first = visibleItems.first else { return }
        perform(first)
    }

    private func perform(_ item: Item) {
        popover?.performClose(nil)
        item.perform()
    }
}

/// Native WebKit Find in Page. Does not inject or execute arbitrary page scripts.
@MainActor
final class OrbitFindController: NSObject, NSSearchFieldDelegate {
    private weak var window: NSWindow?
    private weak var anchor: NSView?
    private weak var webView: WKWebView?
    private var popover: NSPopover?
    private weak var searchField: NSSearchField?
    private weak var statusLabel: NSTextField?

    init(window: NSWindow, anchor: NSView) {
        self.window = window
        self.anchor = anchor
        super.init()
    }

    func show(for page: WKWebView) {
        guard let window, let anchor else { return }
        webView = page
        if popover?.isShown == true {
            if let search = searchField { window.makeFirstResponder(search) }
            return
        }

        let container = NSView()
        let content = NSStackView()
        content.orientation = .horizontal
        content.alignment = .centerY
        content.spacing = 8
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])
        let search = NSSearchField()
        search.placeholderString = "Find on page"
        search.font = .systemFont(ofSize: 13)
        search.delegate = self
        search.target = self
        search.action = #selector(findNext(_:))
        content.addArrangedSubview(search)

        let previous = NSButton(
            image: NSImage(systemSymbolName: "chevron.up", accessibilityDescription: "Previous") ?? NSImage(),
            target: self, action: #selector(findPrevious(_:))
        )
        previous.bezelStyle = .inline
        previous.toolTip = "Previous match"
        content.addArrangedSubview(previous)

        let next = NSButton(
            image: NSImage(systemSymbolName: "chevron.down", accessibilityDescription: "Next") ?? NSImage(),
            target: self, action: #selector(findNext(_:))
        )
        next.bezelStyle = .inline
        next.toolTip = "Next match"
        content.addArrangedSubview(next)

        let status = NSTextField(labelWithString: " ")
        status.font = .systemFont(ofSize: 10)
        status.alignment = .right
        status.textColor = .secondaryLabelColor
        status.widthAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
        content.addArrangedSubview(status)

        let controller = NSViewController()
        controller.view = container
        controller.preferredContentSize = NSSize(width: 435, height: 54)
        let panel = NSPopover()
        panel.behavior = .transient
        panel.animates = true
        panel.contentViewController = controller
        popover = panel
        searchField = search
        statusLabel = status
        panel.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .maxY)
        window.makeFirstResponder(search)
    }

    func controlTextDidChange(_ notification: Notification) {
        guard notification.object as? NSSearchField === searchField else { return }
        performFind(backwards: false)
    }

    @objc private func findNext(_ sender: Any?) { performFind(backwards: false) }
    @objc private func findPrevious(_ sender: Any?) { performFind(backwards: true) }

    private func performFind(backwards: Bool) {
        guard let webView, let text = searchField?.stringValue, !text.isEmpty else {
            statusLabel?.stringValue = "Type to find"
            return
        }
        let configuration = WKFindConfiguration()
        configuration.backwards = backwards
        configuration.wraps = true
        webView.find(text, configuration: configuration) { [weak self, weak webView] result in
            guard let self, let webView, self.webView === webView else { return }
            self.statusLabel?.stringValue = result.matchFound ? "Match found" : "No matches"
        }
    }
}
