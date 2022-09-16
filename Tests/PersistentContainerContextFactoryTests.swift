// Copyright © 2022 Kevin Refermat. All rights reserved.

import XCTest
import CoreData
@testable import Sticky

class PersistentContainerContextProviderTests: XCTestCase {
    typealias ContextProvider = PersistentContainer.ContextProvider

    var nsPersistentContainer: NSPersistentContainer!
    var nsPersistentContainerSpy: NSPersistentContainer.Spy!

    var sut: ContextProvider!

    override func setUp() {
        super.setUp()

        nsPersistentContainer = NSPersistentContainer.preloadedInMemoryDouble(name: "PersistentContainerContextProviderTestsDB", managedObjectModel: .singleEntityModel)
        nsPersistentContainerSpy = NSPersistentContainer.Spy(nsPersistentContainer: nsPersistentContainer)
    }

    func resetSUT() {
        sut = ContextProvider(nsPersistentContainer: nsPersistentContainerSpy)
    }

    func testThatNSPersistentContainerViewContextIsReturnedWhenCallingSUTViewContext() {
        resetSUT()

        XCTAssertTrue(sut.viewContext === nsPersistentContainerSpy.viewContext)
    }

    func testThatNSPersistentContainerNewBackgroundContextIsCalledWhenCallingSUTNewBackgroundContext() {
        resetSUT()

        XCTAssertEqual(nsPersistentContainerSpy.newBackgroundContextCallCount, 0)
        let _ = sut.newBackgroundContext()
        XCTAssertEqual(nsPersistentContainerSpy.newBackgroundContextCallCount, 1)
    }
}
