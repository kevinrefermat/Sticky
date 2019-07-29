// Copyright © 2019 Kevin Refermat. All rights reserved.

import XCTest
import CoreData
@testable import Sticky

class PersistentContainerTests: XCTestCase {
    var nsPersistentContainer: NSPersistentContainer!
    var nsPersistentContainerSpy: NSPersistentContainer.Spy!

    var sut: PersistentContainer!

    override func setUp() {
        super.setUp()

        nsPersistentContainer = NSPersistentContainer(name: "\(type(of: self))DB", managedObjectModel: .singleEntityModel)
        nsPersistentContainerSpy = NSPersistentContainer.Spy(nsPersistentContainer: nsPersistentContainer)
    }

    func resetSUT(preloaded: Bool = false) {
        nsPersistentContainer.replacePersistentStoreDescriptionsWithSingleInMemoryDescription()

        sut = PersistentContainer(nsPersistentContainer: nsPersistentContainerSpy)

        guard preloaded else { return }

        continueAfterFailure = false
        XCTAssertNoThrow(try sut.start())
        continueAfterFailure = true
    }

    func testThatStateIsResetWhenSUTInitialized() {
        resetSUT()

        guard case .reset = sut.state else { XCTFail(); return }
    }

    func testThatStateIsLoadingWhenAsynchronousStartIsCalled() {
        resetSUT()

        sut.start { _ in }

        guard case .loading = sut.state else { XCTFail(); return }
    }

    func testThatStateIsLoadedWhenSynchronousStartIsCalledSuccessfully() {
        resetSUT()

        XCTAssertNoThrow(try sut.start())

        guard case .loaded = sut.state else { XCTFail(); return }
    }

    func testThatLoadPersistentStoresIsCalledWithSuccessWhenAsynchronousStartIsCalled() {
        resetSUT()

        XCTAssertEqual(nsPersistentContainerSpy.loadPersistentStoresCallCount, 0)

        let expectation = self.expectation(description: "callback not called")
        sut.start { (result) in
            defer { expectation.fulfill() }
            guard case .success = result else { XCTFail(); return }
        }

        XCTAssertEqual(nsPersistentContainerSpy.loadPersistentStoresCallCount, 1)

        waitForExpectations(timeout: 1)
    }

    func testThatLoadPersistentStoresIsCalledWhenSynchronousStartIsCalled() {
        resetSUT()

        XCTAssertEqual(nsPersistentContainerSpy.loadPersistentStoresCallCount, 0)
        XCTAssertNoThrow(try sut.start())
        XCTAssertEqual(nsPersistentContainerSpy.loadPersistentStoresCallCount, 1)
    }

    func testThatLoadPersistentStoresIsNotCalledWhenAsyncronousStartIsCalledASecondTime() {
        resetSUT()
        
        XCTAssertEqual(nsPersistentContainerSpy.loadPersistentStoresCallCount, 0)
        let expectation0 = self.expectation(description: "callback not called")
        sut.start { (result) in
            defer { expectation0.fulfill() }
            guard case .success = result else { XCTFail(); return }
        }
        XCTAssertEqual(nsPersistentContainerSpy.loadPersistentStoresCallCount, 1)
        let expectation1 = self.expectation(description: "callback not called")
        sut.start { (result) in
            defer { expectation1.fulfill() }
            guard case .failure = result else { XCTFail(); return }
        }
        XCTAssertEqual(nsPersistentContainerSpy.loadPersistentStoresCallCount, 1)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testThatLoadPersistentStoresIsNotCalledWhenSyncronousStartIsCalledASecondTime() {
        resetSUT()

        XCTAssertEqual(nsPersistentContainerSpy.loadPersistentStoresCallCount, 0)
        XCTAssertNoThrow(try sut.start())
        XCTAssertEqual(nsPersistentContainerSpy.loadPersistentStoresCallCount, 1)
        XCTAssertThrowsError(try sut.start())
        XCTAssertEqual(nsPersistentContainerSpy.loadPersistentStoresCallCount, 1)
    }

    func testThatSUTStateIsLoadedWhenEachPersistentStoreIsLoadedSuccessfullySynchronously() {
        resetSUT(preloaded: false)

        XCTAssertNoThrow(try sut.start())

        guard case .loaded = sut.state else { XCTFail(); return }
    }

    func testThatSUTStateIsLoadedWhenEachPersistentStoreIsLoadedSuccessfullyAsynchronously() {
        resetSUT(preloaded: false)

        let expectation = self.expectation(description: "start callback was not called")
        sut.start { (result) in
            defer { expectation.fulfill() }

            guard case .success(let contextProvider) = result else { XCTFail(); return }

            XCTAssertTrue(contextProvider.viewContext === self.nsPersistentContainer.viewContext)
        }

        waitForExpectations(timeout: 1, handler: nil)

        guard case .loaded = sut.state else { XCTFail(); return }
    }

    func testThatSUTStateIsFailedToLoadWhenEachPersistentStoreFailsToLoadAsynchronously() {
        nsPersistentContainerSpy.loadPersistentStoreOverrideError = TestError()
        resetSUT()

        let expectation = self.expectation(description: "start callback was not called")
        sut.start { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
        
        guard case .failedToLoad(let error) = sut.state else { XCTFail(); return }
        guard case PersistentContainer.Error.failedToLoadPersistentStores(let failures) = error else { XCTFail(); return }

        XCTAssertEqual(failures.count, nsPersistentContainerSpy.persistentStoreDescriptions.count)
    }

    func testThatSUTStateIsFailedToLoadWhenEachPersistentStoreFailsToLoadSynchronously() {
        nsPersistentContainerSpy.loadPersistentStoreOverrideError = TestError()
        resetSUT()

        XCTAssertThrowsError(try sut.start())

        guard case .failedToLoad(let error) = sut.state else { XCTFail(); return }
        guard case PersistentContainer.Error.failedToLoadPersistentStores(let failures) = error else { XCTFail(); return }

        XCTAssertEqual(failures.count, nsPersistentContainerSpy.persistentStoreDescriptions.count)
    }

    func testThatStartCallbackIsCalledWhenLoadingAnAuthenticNSPersistentContainer() {
        let nsPersistentContainer = NSPersistentContainer(name: UUID().uuidString, managedObjectModel: .singleEntityModel)
        sut = PersistentContainer(nsPersistentContainer: nsPersistentContainer)

        let expectation = self.expectation(description: "start callback was not called")
        sut.start { (result) in
            defer { expectation.fulfill() }

            guard case .success(let contextProvider) = result else { XCTFail(); return }

            XCTAssertTrue(contextProvider.viewContext === nsPersistentContainer.viewContext)
        }

        waitForExpectations(timeout: 1)
    }

    func testThatNSPersistentContainerContainsASingleInMemoryDescriptionWhenInitializedWithInMemorySetToTrueStartedSync() {
        XCTAssertNotEqual(nsPersistentContainer.persistentStoreDescriptions.map { $0.type }, [NSInMemoryStoreType])
        sut = PersistentContainer(nsPersistentContainer: nsPersistentContainer, inMemory: true)
        XCTAssertNoThrow(try sut.start())
        XCTAssertEqual(nsPersistentContainer.persistentStoreDescriptions.map { $0.type }, [NSInMemoryStoreType])
    }

    func testThatNSPersistentContainerContainsASingleInMemoryDescriptionWhenInitializedWithInMemorySetToTrueStartedAsync() {
        XCTAssertNotEqual(nsPersistentContainer.persistentStoreDescriptions.map { $0.type }, [NSInMemoryStoreType])
        sut = PersistentContainer(nsPersistentContainer: nsPersistentContainer, inMemory: true)

        let expectation = self.expectation(description: "callback not called")
        sut.start { (result) in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(nsPersistentContainer.persistentStoreDescriptions.map { $0.type }, [NSInMemoryStoreType])
    }

    func testThatNSPersistentContainerDoesNotContainASingleInMemoryDescriptionWhenInitializedWithInMemorySetToFalseStartedSync() {
        XCTAssertNotEqual(nsPersistentContainer.persistentStoreDescriptions.map { $0.type }, [NSInMemoryStoreType])
        sut = PersistentContainer(nsPersistentContainer: nsPersistentContainer, inMemory: false)
        XCTAssertNoThrow(try sut.start())
        XCTAssertNotEqual(nsPersistentContainer.persistentStoreDescriptions.map { $0.type }, [NSInMemoryStoreType])
    }

    func testThatNSPersistentContainerDoesNotContainASingleInMemoryDescriptionWhenInitializedWithInMemorySetToFalseStartedAsync() {
        XCTAssertNotEqual(nsPersistentContainer.persistentStoreDescriptions.map { $0.type }, [NSInMemoryStoreType])
        sut = PersistentContainer(nsPersistentContainer: nsPersistentContainer, inMemory: false)

        let expectation = self.expectation(description: "callback not called")
        sut.start { (result) in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertNotEqual(nsPersistentContainer.persistentStoreDescriptions.map { $0.type }, [NSInMemoryStoreType])
    }
}
