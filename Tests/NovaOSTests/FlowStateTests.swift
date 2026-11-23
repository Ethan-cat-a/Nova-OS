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

    func testCorruptPayloadFallsBack() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(Data("not-json".utf8), forKey: FlowStore.key)
        XCTAssertNil(FlowStore.load(from: defaults))
    }
}
