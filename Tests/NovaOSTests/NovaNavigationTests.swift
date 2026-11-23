import XCTest
@testable import NovaOS

final class NovaNavigationTests: XCTestCase {
    func testSimpleQueryIsSearch() {
        XCTAssertEqual(NovaNavigation.resolve("music"), .search("music"))
    }
    func testWhitespaceQueryIsSearch() {
        XCTAssertEqual(NovaNavigation.resolve("  browser for Mac  "), .search("browser for Mac"))
    }
    func testDomainNavigatesWithHTTPS() {
        XCTAssertEqual(NovaNavigation.resolve("example.com"), .website(URL(string: "https://example.com")!))
    }
    func testExplicitHTTPIsPreserved() {
        XCTAssertEqual(NovaNavigation.resolve("http://example.com/docs"), .website(URL(string: "http://example.com/docs")!))
    }
    func testLocalhostNavigatesWithHTTP() {
        XCTAssertEqual(NovaNavigation.resolve("localhost:3000"), .website(URL(string: "http://localhost:3000")!))
    }
    func testBlankInputIsIgnored() {
        XCTAssertNil(NovaNavigation.resolve(" \t\n "))
    }
}
