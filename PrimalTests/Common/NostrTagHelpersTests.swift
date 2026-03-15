//
//  NostrTagHelpersTests.swift
//  PrimalTests
//
//  Created by NostrWolfe on 14.3.26..
//

import XCTest
@testable import Primal

final class NostrTagHelpersTests: XCTestCase {

    // MARK: - firstTag

    func testFirstTag_findsMatchingTag() {
        let tags: [[String]] = [
            ["e", "abc123", "", "reply"],
            ["p", "pubkey123"],
            ["d", "service-id"],
        ]
        let result = tags.firstTag("d")
        XCTAssertNotNil(result)
        XCTAssertEqual(result, ["d", "service-id"])
    }

    func testFirstTag_returnsNilForMissingTag() {
        let tags: [[String]] = [
            ["e", "abc123"],
            ["p", "pubkey123"],
        ]
        XCTAssertNil(tags.firstTag("d"))
    }

    func testFirstTag_returnsFirstOfMultiple() {
        let tags: [[String]] = [
            ["p", "first-pubkey", "", "provider"],
            ["p", "second-pubkey", "", "requester"],
        ]
        let result = tags.firstTag("p")
        XCTAssertEqual(result?[1], "first-pubkey")
    }

    func testFirstTag_emptyArray() {
        let tags: [[String]] = []
        XCTAssertNil(tags.firstTag("d"))
    }

    func testFirstTag_emptyInnerArray() {
        let tags: [[String]] = [[], ["d", "value"]]
        XCTAssertNil(tags.firstTag(""))
        XCTAssertEqual(tags.firstTag("d"), ["d", "value"])
    }

    // MARK: - allTags

    func testAllTags_returnsAllMatching() {
        let tags: [[String]] = [
            ["p", "pubkey-a", "", "provider"],
            ["e", "event-id"],
            ["p", "pubkey-b", "", "requester"],
        ]
        let result = tags.allTags("p")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0][1], "pubkey-a")
        XCTAssertEqual(result[1][1], "pubkey-b")
    }

    func testAllTags_returnsEmptyForNoMatches() {
        let tags: [[String]] = [
            ["e", "event-id"],
            ["d", "service-id"],
        ]
        let result = tags.allTags("p")
        XCTAssertTrue(result.isEmpty)
    }

    func testAllTags_emptyArray() {
        let tags: [[String]] = []
        XCTAssertTrue(tags.allTags("p").isEmpty)
    }

    // MARK: - tagValue

    func testTagValue_returnsIndex1() {
        let tags: [[String]] = [
            ["d", "my-service-id"],
            ["status", "active"],
        ]
        XCTAssertEqual(tags.tagValue("d"), "my-service-id")
        XCTAssertEqual(tags.tagValue("status"), "active")
    }

    func testTagValue_returnsNilForMissing() {
        let tags: [[String]] = [["d", "value"]]
        XCTAssertNil(tags.tagValue("status"))
    }

    func testTagValue_returnsNilForSingleElementTag() {
        let tags: [[String]] = [["d"]]
        XCTAssertNil(tags.tagValue("d"))
    }

    func testTagValue_returnsFirstMatchOnly() {
        let tags: [[String]] = [
            ["s", "translation"],
            ["s", "summarization"],
        ]
        XCTAssertEqual(tags.tagValue("s"), "translation")
    }

    // MARK: - tagValues

    func testTagValues_returnsAllIndex1Values() {
        let tags: [[String]] = [
            ["s", "translation"],
            ["s", "summarization"],
            ["s", "generation"],
        ]
        let result = tags.tagValues("s")
        XCTAssertEqual(result, ["translation", "summarization", "generation"])
    }

    func testTagValues_skipsTagsWithoutIndex1() {
        let tags: [[String]] = [
            ["s", "translation"],
            ["s"],
            ["s", "summarization"],
        ]
        let result = tags.tagValues("s")
        XCTAssertEqual(result, ["translation", "summarization"])
    }

    func testTagValues_returnsEmptyForNoMatches() {
        let tags: [[String]] = [["d", "value"]]
        XCTAssertTrue(tags.tagValues("t").isEmpty)
    }

    func testTagValues_emptyArray() {
        let tags: [[String]] = []
        XCTAssertTrue(tags.tagValues("s").isEmpty)
    }
}
