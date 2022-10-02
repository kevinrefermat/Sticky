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

class NSManagedObjectModelAdditionsTests: XCTestCase {
    func testThatErrorIsThrownWhenModelContainsMultipleEntitiesWithSameClassNames() {
        @objc(EntityA)
        final class EntityA: NSManagedObject {}

        @objc(EntityB)
        final class EntityB: NSManagedObject {}

        let entityA = NSEntityDescription()
        entityA.name = String(describing: EntityA.self)
        entityA.managedObjectClassName = "EntityClassName"
        entityA.properties = []

        let entityB = NSEntityDescription()
        entityB.name = String(describing: EntityB.self)
        entityB.managedObjectClassName = "EntityClassName"
        entityB.properties = []

        let sut = NSManagedObjectModel()
        sut.entities = [entityA, entityB]

        XCTAssertThrowsError(try sut.entity(for: "EntityClassName")) { error in
            XCTAssertEqual(
                String(describing: error),
                "modelContainsMultipleEntitiesWithClassName(\"EntityClassName\", 2)"
            )
        }
    }

    func testThatErrorIsThrownWhenModelDoesNotContainEntity() {
        let sut = NSManagedObjectModel()

        XCTAssertThrowsError(try sut.entity(for: "NonExistentClassName")) { error in
            XCTAssertEqual(
                String(describing: error),
                "modelDoesNotContainEntityWithClassName(\"NonExistentClassName\")"
            )
        }
    }
}
