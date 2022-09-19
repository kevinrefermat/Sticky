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

class NSManagedObjectContextAdditionsSyncTests: XCTestCase {
    enum ContextAccessType {
        case async
        case sync
    }

    var contextAccessType: ContextAccessType { .sync }

    var contextProviderSpy: PersistentContainer.ContextProviderSpy!

    override func setUp() {
        super.setUp()

        let nsPersistentContainer = NSPersistentContainer.preloadedInMemoryDouble(
            name: "NSManagedObjectContextAdditionsTestsDB",
            managedObjectModel: .singleEntityModel
        )
        contextProviderSpy = PersistentContainer.ContextProviderSpy(nsPersistentContainer: nsPersistentContainer)
    }

    func performBlockOnContext<T>(
        context: NSManagedObjectContext? = nil,
        block: @escaping (NSManagedObjectContext) throws -> T
    ) throws -> T {
        let context = context ?? contextProviderSpy.newBackgroundContext()

        switch contextAccessType {
        case .async:
            var result: Result<T, Error>?

            let expectation = self.expectation(description: "perform block did not execute in time")
            context.perform { (context) in
                result = Result {
                    try block(context)
                }
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5)

            switch result! {
            case .success(let element):
                return element
            case .failure(let error):
                throw error
            }
        case .sync:
            return try context.performAndWait(block: block)
        }
    }

    func testThatPerformAndWaitReturnsSameValueReturnedByBlock() throws {
        let expected = UUID().uuidString
        let actual = try performBlockOnContext { _ in expected }
        XCTAssertEqual(expected, actual)
    }

    func testThatPerformAndWaitThrowsSameErrorThrownByBlock() {
        do {
            try performBlockOnContext { _ in throw TestError() }
        } catch {
            guard error is TestError else { XCTFail(); return }
        }
    }

    func testThatPerformAndWaitContextSuccessfullySaves() {
        let expected = UUID().uuidString
        insertExampleEntity(uuidString: expected)

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let actual = try context.fetch(ExampleEntity.self)
                XCTAssertEqual([expected], actual.compactMap { $0.uuidString })
            }
        )
    }

    func testThatFetchReturnsEmptyArrayWhenNoEntitiesArePersisted() {
        let expected = UUID().uuidString
        insertExampleEntity(uuidString: expected)

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let actual = try context.fetch(ExampleEntity.self)
                XCTAssertEqual(actual.compactMap { $0.uuidString }, [expected])
            }
        )
    }

    func testThatFetchReturnsAllEntitiesWhenSingleEntityIsPersisted() {
        let expected = UUID().uuidString
        insertExampleEntity(uuidString: expected)

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let categories = try context.fetch(ExampleEntity.self)
                XCTAssertEqual(categories.compactMap { $0.uuidString }, [expected])
            }
        )
    }

    func testThatFetchReturnsAllEntitiesWhenMultipleEntitiesArePersisted() {
        let expected = Set([0..<5].map { _ in UUID().uuidString })
        expected.forEach { insertExampleEntity(uuidString: $0) }

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let categories = try context.fetch(ExampleEntity.self)
                XCTAssertEqual(Set(categories.compactMap { $0.uuidString }), expected)
            }
        )
    }

    func testThatFetchReturnsEntitiesSortedByNameWhenFetchRequestCustomizedWithSortDescriptor() {
        let expected = [0..<5].map({ _ in UUID().uuidString }).sorted()
        expected.forEach { insertExampleEntity(uuidString: $0) }

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let categories = try context.fetch(ExampleEntity.self) { (request) in
                    request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                }
                XCTAssertEqual(categories.compactMap { $0.uuidString }, expected)
            }
        )
    }

    func testThatErrorIsThrownWhenFetchIsCalledBeforePersistentStoreIsSet() {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

        XCTAssertThrowsError(
            try performBlockOnContext(context: context) { (context) in
                _ = try context.fetch(ExampleEntity.self)
            }
        )
    }

    func testThatErrorIsThrownWhenFetchIsCalledOnAnNSManagedObjectThatIsNotAssociatedWithAnEntityInTheContextsModel() {
        final class TestManagedObject: NSManagedObject {}

        XCTAssertThrowsError(
            try performBlockOnContext { (context) in
                _ = try context.fetch(TestManagedObject.self)
            }
        )
    }

    func testThatCreateProducesAnObjectThatSavesSuccessfully() {
        let expectedUUIDString = UUID().uuidString
        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let newExampleEntity = try ExampleEntity(context)
                newExampleEntity.uuidString = expectedUUIDString
                try context.save()
            }
        )

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let exampleEntities = try context.fetch(ExampleEntity.self)
                let actual = exampleEntities.compactMap { $0.uuidString }
                XCTAssertEqual([expectedUUIDString], actual)
            }
        )
    }

    func testThatCreateThrowsErrorWhenContextModelDoesNotClaimEntity() {
        final class OrphanManagedObject: NSManagedObject {}

        XCTAssertThrowsError(
            try performBlockOnContext { (context) in
                try OrphanManagedObject(context)
            }
        )
    }

    func testPresetValues() {
        let uuidString = UUID().uuidString
        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let object = try ExampleEntity(context)
                object.uuidString = uuidString
                try context.save()
            }
        )

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let entities = try context.fetch(ExampleEntity.self)
                XCTAssertEqual(entities.map { $0.uuidString }, [uuidString])
            }
        )
    }

    func testThatAllEntitiesAreDeletedWhenDeleteIsCalledForGivenType() {
        let entityCount = 10

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                try (0..<entityCount).forEach { _ in
                    let newExampleEntity = try ExampleEntity(context)
                    newExampleEntity.uuidString = UUID().uuidString
                }

                try context.save()
            }
        )

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let entities = try context.fetch(ExampleEntity.self)
                XCTAssertEqual(entities.count, entityCount)
                try context.delete(ExampleEntity.self, isDeleted: { _ in true })
                try context.save()
            }
        )

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let entities = try context.fetch(ExampleEntity.self)
                XCTAssertEqual(entities, [])
            }
        )
    }

    func testThatSelectedEntitiesAreDeletedWhenDeleteIsCalledForGivenTypeWithSpecificCriteria() {
        let uuidA = UUID()
        let uuidB = UUID()

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let a = try ExampleEntity(context)
                a.uuidString = uuidA.uuidString
                let b = try ExampleEntity(context)
                b.uuidString = uuidB.uuidString
                try context.save()
            }
        )

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                try context.delete(ExampleEntity.self, isDeleted: { $0.uuidString == uuidA.uuidString })
                try context.save()
            }
        )

        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let entities = try context.fetch(ExampleEntity.self)
                XCTAssertEqual(entities.map { $0.uuidString }, [uuidB.uuidString])
            }
        )
    }

    func insertExampleEntity(uuidString: String) {
        XCTAssertNoThrow(
            try performBlockOnContext { (context) in
                let exampleEntity = try ExampleEntity(context)
                exampleEntity.uuidString = uuidString
                try context.save()
            }
        )
    }
}

class NSManagedObjectContextAdditionsAsyncTests: NSManagedObjectContextAdditionsSyncTests {
    override var contextAccessType: ContextAccessType { .async }
}
