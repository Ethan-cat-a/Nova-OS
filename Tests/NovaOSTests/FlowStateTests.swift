import XCTest
@testable import NovaOS

final class FlowStateTests: XCTestCase {
    func testFreshSpaceHasHomeTab() {
        let state = FlowState.fresh()
        XCTAssertEqual(state.spaces.count, 1)
        XCTAssertEqual(state.activeSpace?.tabs.first?.kind, "home")
        XCTAssertEqual(state.activeSpace?.selectedTabID, state.activeSpace?.tabs.first?.id)
    }

    func testRoundTripAndPinOrdering() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defer { defaults.removePersistentDomain(forName: defaults.volatileDomainNames.first ?? "") }
        var state = FlowState.fresh()
        let unpinned = FlowTabState(kind: "website", value: "https://example.com", title: "Example")
        let pinned = FlowTabState(kind: "search", value: "swift", title: "Swift", pinned: true)
        state.spaces[0].tabs = [unpinned, pinned]
        state.spaces[0].selectedTabID = unpinned.id
        XCTAssertTrue(FlowStore.save(state, to: defaults))
        let loaded = FlowStore.load(from: defaults)
        XCTAssertEqual(loaded?.activeSpace?.tabs.map(\.id), [pinned.id, unpinned.id])
        XCTAssertEqual(loaded?.activeSpace?.selectedTabID, unpinned.id)
    }

    func testInvalidSchemeRejected() {
        var state = FlowState.fresh()
        state.spaces[0].tabs = [
            FlowTabState(kind: "website", value: "javascript:alert(1)"),
            FlowTabState(kind: "website", value: "file:///private/secret"),
            FlowTabState(kind: "website", value: "https://example.org")
        ]
        let valid = state.normalized().spaces[0].tabs
        XCTAssertEqual(valid.count, 1)
        XCTAssertEqual(valid.first?.value, "https://example.org")
    }

    func testUnknownTabKindIgnored() {
        var state = FlowState.fresh()
        state.spaces[0].tabs = [FlowTabState(kind: "unsafe", value: "anything")]
        XCTAssertEqual(state.normalized().spaces[0].tabs.first?.kind, "home")
    }

    func testSpacesAreBounded() {
        var state = FlowState.fresh()
        state.spaces = (0..<20).map { FlowSpaceState(name: "Space \($0)", tabs: (0..<80).map { _ in FlowTabState() }) }
        state.activeSpaceID = state.spaces[19].id
        let clean = state.normalized()
        XCTAssertEqual(clean.spaces.count, 8)
        XCTAssertTrue(clean.spaces.allSatisfy { $0.tabs.count == 40 })
        XCTAssertEqual(clean.activeSpaceID, clean.spaces[0].id)
    }

    func testMissingSelectionRecovers() {
        var state = FlowState.fresh()
        state.spaces[0].selectedTabID = UUID()
        XCTAssertEqual(state.normalized().activeSpace?.selectedTabID, state.activeSpace?.tabs[0].id)
    }

    func testPinStablePartition() {
        let first = FlowTabState(title: "A")
        let pinned = FlowTabState(title: "B", pinned: true)
        let last = FlowTabState(title: "C")
        XCTAssertEqual(FlowOrder.pinnedFirst([first, pinned, last]).map(\.title), ["B", "A", "C"])
        XCTAssertEqual(FlowOrder.toggledPin([first, pinned, last], id: last.id).map(\.title), ["B", "C", "A"])
    }

    func testDragReorder() {
        let a = FlowTabState(title: "A"), b = FlowTabState(title: "B"), c = FlowTabState(title: "C")
        XCTAssertEqual(FlowOrder.moved([a,b,c], from: a.id, to: c.id).map(\.title), ["B","C","A"])
        XCTAssertEqual(FlowOrder.moved([a,b,c], from: c.id, to: a.id).map(\.title), ["C","A","B"])
    }

    func testCantDragAcrossPinBoundary() {
        let pinned = FlowTabState(title: "Pinned", pinned: true)
        let normal = FlowTabState(title: "Normal")
        XCTAssertEqual(FlowOrder.moved([pinned,normal], from: normal.id, to: pinned.id), [pinned,normal])
    }

    func testOmniRankPrioritizesTitles() {
        XCTAssertGreaterThan(FlowOmniRank.score(title: "GitHub", detail: "", query: "github"),
                             FlowOmniRank.score(title: "History", detail: "github.com", query: "github"))
        XCTAssertEqual(FlowOmniRank.score(title: "Github", detail: "", query: "absent"), 0)
    }


    func testFileStorePersistsAllEightSpacesEvenWhenPayloadExceedsUserDefaultsLimit() throws {
        let defaults = UserDefaults(suiteName: "NovaOS.FlowTests." + UUID().uuidString)!
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("spaces.json")
        let longURL = "https://example.org/" + String(repeating: "a", count: 3500)
        var state = FlowState.fresh()
        state.spaces = (0..<8).map { index in
            FlowSpaceState(name: "Space \(index)",
                           tabs: (0..<40).map { _ in FlowTabState(kind: "website", value: longURL) })
        }
        state.activeSpaceID = state.spaces.last!.id
        XCTAssertTrue(FlowStore.save(state, to: defaults, fileURL: url))
        XCTAssertGreaterThan(try Data(contentsOf: url).count, 1_000_000)
        let loaded = FlowStore.load(from: defaults, fileURL: url)
        XCTAssertEqual(loaded?.spaces.count, 8)
        XCTAssertTrue(loaded?.spaces.allSatisfy { $0.tabs.count == 40 } ?? false)
        XCTAssertEqual(loaded?.activeSpaceID, state.activeSpaceID)
    }

    func testFileStoreFallsBackToBackupOnCorruption() throws {
        let defaults = UserDefaults(suiteName: "NovaOS.FlowTests." + UUID().uuidString)!
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("spaces.json")
        var original = FlowState.fresh()
        original.spaces[0].name = "Recover This"
        XCTAssertTrue(FlowStore.save(original, to: defaults, fileURL: url))
        var revised = original
        revised.spaces[0].name = "Updated Space"
        XCTAssertTrue(FlowStore.save(revised, to: defaults, fileURL: url))
        try Data("broken JSON".utf8).write(to: url, options: .atomic)
        XCTAssertEqual(FlowStore.load(from: defaults, fileURL: url)?.spaces.first?.name, "Recover This")
    }

    func testLegacyUserDefaultsMigratesToFileStore() {
        let defaults = UserDefaults(suiteName: "NovaOS.FlowTests." + UUID().uuidString)!
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("spaces.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        var legacy = FlowState.fresh()
        legacy.spaces[0].name = "Imported"
        XCTAssertTrue(FlowStore.save(legacy, to: defaults))
        XCTAssertEqual(FlowStore.load(from: defaults, fileURL: url)?.spaces.first?.name, "Imported")
        XCTAssertTrue(FlowStore.save(legacy, to: defaults, fileURL: url))
        XCTAssertEqual(FlowStore.load(from: defaults, fileURL: url)?.spaces.first?.name, "Imported")
    }

    func testCorruptPayloadFallsBack() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(Data("not-json".utf8), forKey: FlowStore.key)
        XCTAssertNil(FlowStore.load(from: defaults))
    }
}
