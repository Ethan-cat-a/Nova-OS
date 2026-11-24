import Foundation

/// Persisted workspace state. No WKWebView, cookies, page body or thumbnail data is saved here.
struct FlowTabState: Codable, Equatable {
    var id: UUID
    var kind: String
    var value: String?
    var title: String
    var pinned: Bool

    init(id: UUID = UUID(), kind: String = "home", value: String? = nil, title: String = "", pinned: Bool = false) {
        self.id = id
        self.kind = kind
        self.value = value
        self.title = title
        self.pinned = pinned
    }
}

struct FlowSpaceState: Codable, Equatable {
    var id: UUID
    var name: String
    var tabs: [FlowTabState]
    var selectedTabID: UUID?

    init(id: UUID = UUID(), name: String, tabs: [FlowTabState] = [FlowTabState()], selectedTabID: UUID? = nil) {
        self.id = id
        self.name = name
        self.tabs = tabs
        self.selectedTabID = selectedTabID ?? tabs.first?.id
    }
}

struct FlowState: Codable, Equatable {
    var schemaVersion: Int
    var activeSpaceID: UUID
    var spaces: [FlowSpaceState]

    static func fresh() -> FlowState {
        let initial = FlowSpaceState(name: "My Space")
        return FlowState(schemaVersion: 1, activeSpaceID: initial.id, spaces: [initial])
    }

    var activeSpace: FlowSpaceState? {
        spaces.first(where: { $0.id == activeSpaceID })
    }

    /// Corrupt, oversized, or hostile saved values are rejected before WebKit loads them.
    func normalized() -> FlowState {
        var result: [FlowSpaceState] = []
        var seenSpaceIDs: Set<UUID> = []
        for original in spaces.prefix(8) {
            var space = original
            if !seenSpaceIDs.insert(space.id).inserted { space.id = UUID() }
            let cleanedName = String(space.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(32))
            space.name = cleanedName.isEmpty ? "My Space" : cleanedName
            var seenTabIDs: Set<UUID> = []
            var validated: [FlowTabState] = []
            for originalTab in space.tabs.prefix(40) {
                var tab = originalTab
                if !seenTabIDs.insert(tab.id).inserted { tab.id = UUID() }
                tab.title = String(tab.title.prefix(150))
                switch tab.kind {
                case "home":
                    tab.value = nil
                case "search":
                    guard let value = tab.value, !value.isEmpty, value.utf8.count <= 2048 else { continue }
                case "website":
                    guard let raw = tab.value, let url = URL(string: raw),
                          ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
                          url.host != nil, raw.utf8.count <= 4096 else { continue }
                    tab.value = url.absoluteString
                default:
                    continue
                }
                validated.append(tab)
            }
            if validated.isEmpty { validated = [FlowTabState()] }
            space.tabs = FlowOrder.pinnedFirst(validated)
            if !space.tabs.contains(where: { $0.id == space.selectedTabID }) {
                space.selectedTabID = space.tabs.first?.id
            }
            result.append(space)
        }
        if result.isEmpty { return .fresh() }
        let id = result.contains(where: { $0.id == activeSpaceID }) ? activeSpaceID : result[0].id
        return FlowState(schemaVersion: 1, activeSpaceID: id, spaces: result)
    }
}

enum FlowStore {
    static let key = "NovaOS.FlowSpaces.v1"

    /// File-based storage handles the full 8 x 40 Space quota without UserDefaults size limits.
    /// The old UserDefaults value is retained for migration and rollback compatibility.
    static var applicationSupportURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("Nova OS", isDirectory: true)
            .appendingPathComponent("flow-spaces-v1.json")
    }

    private static func decoded(_ data: Data?) -> FlowState? {
        guard let data, data.count < 4_000_000,
              let value = try? JSONDecoder().decode(FlowState.self, from: data),
              value.schemaVersion == 1 else { return nil }
        return value.normalized()
    }

    static func load(from defaults: UserDefaults = .standard, fileURL: URL? = nil) -> FlowState? {
        if let fileURL {
            if let current = decoded(try? Data(contentsOf: fileURL, options: .mappedIfSafe)) {
                return current
            }
            // An interrupted or corrupted primary file must not erase the last good snapshot.
            if let backup = decoded(try? Data(contentsOf: fileURL.appendingPathExtension("bak"), options: .mappedIfSafe)) {
                return backup
            }
        }
        return decoded(defaults.data(forKey: key))
    }

    @discardableResult
    static func save(_ state: FlowState, to defaults: UserDefaults = .standard, fileURL: URL? = nil) -> Bool {
        guard let data = try? JSONEncoder().encode(state.normalized()), data.count < 4_000_000 else { return false }
        if let fileURL {
            do {
                try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                        withIntermediateDirectories: true)
                if let prior = try? Data(contentsOf: fileURL, options: .mappedIfSafe),
                   decoded(prior) != nil {
                    try? prior.write(to: fileURL.appendingPathExtension("bak"), options: .atomic)
                }
                try data.write(to: fileURL, options: .atomic)
                // Keep the last legacy snapshot where small enough; never block a large file save.
                if data.count < 1_000_000 { defaults.set(data, forKey: key) }
                return true
            } catch {
                return false
            }
        }
        guard data.count < 1_000_000 else { return false }
        defaults.set(data, forKey: key)
        return true
    }
}

enum FlowOrder {
    static func pinnedFirst(_ items: [FlowTabState]) -> [FlowTabState] {
        items.filter(\.pinned) + items.filter { !$0.pinned }
    }

    /// Dragging within the pinned/unpinned group is allowed; crossing the pin boundary
    /// requires an explicit Pin/Unpin action, avoiding accidental loss of pin status.
    static func moved(_ items: [FlowTabState], from movingID: UUID, to targetID: UUID) -> [FlowTabState] {
        guard movingID != targetID,
              let source = items.firstIndex(where: { $0.id == movingID }),
              let target = items.firstIndex(where: { $0.id == targetID }),
              items[source].pinned == items[target].pinned else { return items }
        var modified = items
        let item = modified.remove(at: source)
        modified.insert(item, at: min(target, modified.count))
        return modified
    }

    static func toggledPin(_ items: [FlowTabState], id: UUID) -> [FlowTabState] {
        var updated = items
        guard let idx = updated.firstIndex(where: { $0.id == id }) else { return items }
        updated[idx].pinned.toggle()
        return pinnedFirst(updated)
    }
}

enum FlowOmniRank {
    /// Deterministic local ranking; does not call the network or expose browsing history.
    static func score(title: String, detail: String, query: String) -> Int {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return 1 }
        let name = title.lowercased()
        let secondary = detail.lowercased()
        if name == needle { return 120 }
        if name.hasPrefix(needle) { return 90 }
        if name.contains(needle) { return 60 }
        if secondary.hasPrefix(needle) { return 50 }
        if secondary.contains(needle) { return 25 }
        return 0
    }
}
