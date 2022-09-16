// Copyright © 2022 Kevin Refermat. All rights reserved.

import XCTest
@testable import Sticky

class PresetTests: XCTestCase {
    func testThatEqualityIsBasedExlusivelyOnKeyPath() {
        XCTAssertEqual(Preset(key: \UUID.uuidString, value: "a"), Preset(key: \UUID.uuidString, value: "b"))
    }

    func testThatHashableIsBasedExlusivelyOnKeyPath() {
        let a = Preset(key: \UUID.uuidString, value: "a")
        let b = Preset(key: \UUID.uuidString, value: "b")

        var dictionary = [a.keyPath: a]
        dictionary[b.keyPath] = b
        XCTAssertEqual(dictionary[a.keyPath], b)
    }
}
