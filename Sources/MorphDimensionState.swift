import Foundation

/// Morph is a local intent interpreter, not an arbitrary code generator.
/// Every effect is a reviewed, reversible stylesheet. No page data is sent to AI.
enum MorphEffect: String, Codable, CaseIterable {
    case comfortable, contrast, native, video, quiet
    var title: String {
        switch self {
        case .comfortable: return "Comfortable reading"
        case .contrast: return "High contrast"
        case .native: return "Native typography"
        case .video: return "Media spotlight"
        case .quiet: return "Dim recommendations"
        }
    }
    var css: String {
        switch self {
        case .comfortable:
            return "article, main, [role=main] { line-height: 1.8 !important; } article p, main p, article li { font-size: 1.12em !important; line-height: 1.8 !important; } article { max-width: 80ch !important; margin-inline: auto !important; }"
        case .contrast:
            return "html { filter: contrast(1.25) !important; } a { text-decoration: underline !important; } :focus-visible { outline: 3px solid #2675ff !important; outline-offset: 3px !important; }"
        case .native:
            return "body, button, input, select, textarea { font-family: -apple-system, BlinkMacSystemFont, system-ui, sans-serif !important; } button, input, select, textarea { border-radius: 8px !important; } article, main { line-height: 1.65 !important; }"
        case .video:
            return "video { box-shadow: 0 0 0 4px #8978eb, 0 14px 60px #0005 !important; border-radius: 10px !important; } video, iframe[src*='youtube.com/embed'] { max-width: 100% !important; }"
        case .quiet:
            return "[aria-label='Recommended videos'], [aria-label='Recommendations'], ytd-watch-next-secondary-results-renderer { opacity: .28 !important; transition: opacity .2s ease !important; } [aria-label='Recommended videos']:hover, [aria-label='Recommendations']:hover, ytd-watch-next-secondary-results-renderer:hover, [aria-label='Recommended videos']:focus-within, [aria-label='Recommendations']:focus-within, ytd-watch-next-secondary-results-renderer:focus-within { opacity: 1 !important; }"
        }
    }
    static func interpret(_ text: String) -> [MorphEffect] {
        let q = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, q.utf8.count <= 800 else { return [] }
        let patterns: [(MorphEffect,[String])] = [
            (.comfortable, ["read", "article", "larger text", "font size", "comfortable", "spacing"]),
            (.contrast, ["contrast", "accessibility", "accessible"]),
            (.native, ["native", "macos", "typography", "system font"]),
            (.video, ["video", "media", "spotlight"]),
            (.quiet, ["recommendation", "distraction", "quiet", "declutter"])
        ]
        return patterns.compactMap { effect, words in words.contains(where: { q.contains($0) }) ? effect : nil }
    }
    static func stylesheet(_ effects: [MorphEffect]) -> String {
        allCases.filter { effects.contains($0) }.map(\.css).joined(separator: "\n")
    }
    static func origin(_ url: URL) -> String? {
        guard let scheme = url.scheme?.lowercased(), ["http","https"].contains(scheme),
              let host = url.host?.lowercased(), !host.isEmpty,
              url.user == nil, url.password == nil else { return nil }
        let port = url.port.flatMap { p in (scheme == "https" && p == 443) || (scheme == "http" && p == 80) ? nil : ":\(p)" } ?? ""
        return "\(scheme)://\(host)\(port)"
    }
}

struct DimensionTile: Codable, Equatable {
    var id = UUID()
    var url: String?
    var title: String
    var note: String
    var x: Double
    var y: Double

    var safeURL: URL? {
        guard let raw = url, raw.utf8.count <= 4096, let candidate = URL(string: raw),
              MorphEffect.origin(candidate) != nil else { return nil }
        return candidate
    }
}

struct DimensionBoard: Codable, Equatable {
    static let width = 3200.0
    static let height = 2400.0
    static let tileWidth = 360.0
    static let tileHeight = 260.0
    static let maxTiles = 40
    var tiles: [DimensionTile] = []

    static func position(_ x: Double, _ y: Double) -> (Double, Double) {
        (min(max(x.isFinite ? x : 20, 12), width - tileWidth - 12),
         min(max(y.isFinite ? y : 20, 12), height - tileHeight - 12))
    }
    func normalized() -> DimensionBoard {
        var ids = Set<UUID>()
        return DimensionBoard(tiles: tiles.prefix(Self.maxTiles).compactMap { original in
            var tile = original
            guard ids.insert(tile.id).inserted else { return nil }
            if tile.url != nil && tile.safeURL == nil { return nil }
            tile.title = String(tile.title.prefix(150))
            tile.note = String(tile.note.prefix(2000))
            (tile.x, tile.y) = Self.position(tile.x, tile.y)
            return tile
        })
    }
    mutating func add(url: URL?, title: String, note: String = "") -> Bool {
        guard tiles.count < Self.maxTiles, url == nil || MorphEffect.origin(url!) != nil else { return false }
        if let url, url.absoluteString.utf8.count > 4096 { return false }
        let used = tiles
        let pos = (0..<Self.maxTiles).map { (Double(24 + ($0 % 7) * 382), Double(24 + ($0 / 7) * 282)) }
            .first { x,y in !used.contains { abs($0.x-x) < Self.tileWidth && abs($0.y-y) < Self.tileHeight } }
            ?? (24 + Double(tiles.count % 7) * 382, 24 + Double(tiles.count / 7) * 282)
        tiles.append(DimensionTile(url: url?.absoluteString, title: String(title.prefix(150)), note: String(note.prefix(2000)), x: pos.0, y: pos.1))
        return true
    }
}

enum DimensionStore {
    static let key = "NovaOS.DimensionBoards.v1"
    static func load(from defaults: UserDefaults = .standard) -> [UUID: DimensionBoard] {
        guard let data = defaults.data(forKey: key), data.count <= 4_000_000,
              let stored = try? JSONDecoder().decode([UUID:DimensionBoard].self, from: data) else { return [:] }
        return Dictionary(uniqueKeysWithValues: stored.prefix(8).map { ($0.key, $0.value.normalized()) })
    }
    static func save(_ boards: [UUID:DimensionBoard], to defaults: UserDefaults = .standard) {
        let bounded = Dictionary(uniqueKeysWithValues: boards.prefix(8).map { ($0.key, $0.value.normalized()) })
        guard let data = try? JSONEncoder().encode(bounded), data.count <= 4_000_000 else { return }
        defaults.set(data, forKey: key)
    }
}
