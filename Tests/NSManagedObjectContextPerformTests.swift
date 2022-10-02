// MIT License
//
// Copyright (c) 2022 Kevin Refermat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import XCTest
import CoreData
@testable import Sticky

class NSManagedObjectContextPerformTests: XCTestCase {
    var contextProviderSpy: PersistentContainer.ContextProviderSpy!

    override func setUp() {
        super.setUp()

        let nsPersistentContainer = NSPersistentContainer.preloadedInMemoryDouble(
            name: "NSManagedObjectContextPerformTestsDB",
            managedObjectModel: .singleEntityModel
        )
        contextProviderSpy = PersistentContainer.ContextProviderSpy(
            nsPersistentContainer: nsPersistentContainer
        )
    }

    func testThatPerformAndWaitReturnsSameValueReturnedByBlock() {
        let expected = UUID().uuidString
        let actual = contextProviderSpy.newBackgroundContext().performAndWait { _ in expected }
        XCTAssertEqual(expected, actual)
    }

    func testThatPerformAndWaitThrowsSameErrorThrownByBlock() {
        do {
            try contextProviderSpy.newBackgroundContext().performAndWait { _ in throw TestError() }
        } catch {
            guard error is TestError else { XCTFail(); return }
        }
    }

    func testThatPerformAndWaitDoesNotRequireTryWhenBlockDoesNotThrow() {
        let actual = contextProviderSpy.newBackgroundContext().performAndWait { context in
            return try? context.fetch(ExampleEntity.self).count
        }
        XCTAssertEqual(actual, 0)
    }

    func testThatPerformAndWaitDoesRequireTryWhenBlockThrows() throws {
        let actual = try contextProviderSpy.newBackgroundContext().performAndWait { context in
            return try context.fetch(ExampleEntity.self).count
        }
        XCTAssertEqual(actual, 0)
    }

    func testThatPerformAndWaitContextSuccessfullySaves() throws {
        let expected = UUID().uuidString

        try contextProviderSpy.newBackgroundContext().performAndWait { (context) in
            let exampleEntity = try context.create(ExampleEntity.self)
            exampleEntity.uuidString = expected
            try context.save()
        }

        XCTAssertNoThrow(
            try contextProviderSpy.newBackgroundContext().performAndWait { (context) in
                let actual = try context.fetch(ExampleEntity.self)
                XCTAssertEqual([expected], actual.compactMap { $0.uuidString })
            }
        )
    }
}
