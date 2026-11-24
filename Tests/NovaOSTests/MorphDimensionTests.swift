import XCTest
@testable import NovaOS

final class MorphDimensionTests: XCTestCase {
    func testLocalIntentAndNoArbitraryScript() {
        XCTAssertEqual(MorphEffect.interpret("Make the article easier to read and dim recommendations"), [.comfortable,.quiet])
        XCTAssertTrue(MorphEffect.interpret("fetch private cookies and execute code").isEmpty)
        XCTAssertFalse(MorphEffect.stylesheet([.native]).contains("fetch("))
        XCTAssertEqual(MorphEffect.stylesheet([]), "")
    }
    func testExactOrigins() {
        XCTAssertEqual(MorphEffect.origin(URL(string: "https://EXAMPLE.org:443/a")!), "https://example.org")
        XCTAssertEqual(MorphEffect.origin(URL(string: "https://example.org:8443/a")!), "https://example.org:8443")
        XCTAssertNil(MorphEffect.origin(URL(string: "file:///tmp/a")!))
        XCTAssertNil(MorphEffect.origin(URL(string: "https://u:p@example.org")!))
    }
    func testBoardBoundsAndQuota() {
        var board = DimensionBoard()
        for i in 0..<40 { XCTAssertTrue(board.add(url: nil, title: "Note \(i)")) }
        XCTAssertFalse(board.add(url: nil, title: "Overflow"))
        board.tiles[0].x = -.infinity
        board.tiles[0].y = 100_000
        let result = board.normalized()
        XCTAssertEqual(result.tiles.count, 40)
        XCTAssertEqual(result.tiles[0].x, 20)
        XCTAssertEqual(result.tiles[0].y, DimensionBoard.height - DimensionBoard.tileHeight - 12)
    }
    func testRejectUnsafeTileURLsAndDuplicates() {
        var board = DimensionBoard()
        XCTAssertFalse(board.add(url: URL(string: "javascript:alert(1)")!, title: "bad"))
        XCTAssertTrue(board.add(url: URL(string: "https://example.org")!, title: "Example"))
        board.tiles.append(board.tiles[0])
        board.tiles.append(DimensionTile(url: "file:///tmp/private", title: "bad", note: "", x: 20, y: 20))
        XCTAssertEqual(board.normalized().tiles.count, 1)
    }
    func testBoardRoundTripAndSpaceIsolation() {
        let name = "NovaOS.DimensionTests." + UUID().uuidString
        let prefs = UserDefaults(suiteName: name)!
        defer { prefs.removePersistentDomain(forName: name) }
        let a = UUID(), b = UUID()
        var board = DimensionBoard()
        XCTAssertTrue(board.add(url: nil, title: "Note", note: "Local"))
        DimensionStore.save([a: board, b: DimensionBoard()], to: prefs)
        let restored = DimensionStore.load(from: prefs)
        XCTAssertEqual(restored[a], board)
        XCTAssertEqual(restored[b]?.tiles.count, 0)
    }
}
