// Copyright © 2019 Kevin Refermat. All rights reserved.

import XCTest
@testable import Sticky

class ValidatedKVCKeyPathTests: XCTestCase {
    func testThatSUTThrowsWhenKVCKeyPathIsNil() {
        XCTAssertThrowsError(try ValidatedKVCKeyPath(keyPath: \UUID.uuidString))
    }

    func testTHatSUTDoesNotThrowWhenKVCKeyPathIsNonnull() {
        XCTAssertNoThrow(try ValidatedKVCKeyPath(keyPath: \ExampleEntity.uuidString))
    }
}
