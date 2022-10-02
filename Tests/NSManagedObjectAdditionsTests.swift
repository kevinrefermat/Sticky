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

class NSManagedObjectAdditionsTests: XCTestCase {
    var nsPersistentContainer: NSPersistentContainer!

    override func setUp() {
        super.setUp()

        nsPersistentContainer = NSPersistentContainer.preloadedInMemoryDouble(
            name: "NSManagedObjectAdditionsTestsDB",
            managedObjectModel: .singleEntityModel
        )
    }

    func testThatInitializerProducesAnObjectThatSavesSuccessfully() {
        let expectedUUIDString = UUID().uuidString
        XCTAssertNoThrow(
            try nsPersistentContainer.viewContext.performAndWait { (context) in
                let newExampleEntity = try context.create(ExampleEntity.self)
                newExampleEntity.uuidString = expectedUUIDString
                try context.save()
            }
        )

        XCTAssertNoThrow(
            try nsPersistentContainer.viewContext.performAndWait { (context) in
                let exampleEntities = try context.fetch(ExampleEntity.self)
                let actual = exampleEntities.compactMap { $0.uuidString }
                XCTAssertEqual([expectedUUIDString], actual)
            }
        )
    }

    func testThatInitializerThrowsErrorWhenContextModelDoesNotClaimEntity() {
        final class OrphanManagedObject: NSManagedObject {}

        XCTAssertThrowsError(
            try nsPersistentContainer.viewContext.performAndWait { (context) in
                try context.create(OrphanManagedObject.self)
            }
        )
    }
}
