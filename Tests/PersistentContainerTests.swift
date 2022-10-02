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

class PersistentContainerTests: XCTestCase {
    var nsPersistentContainer: NSPersistentContainer!
    var nsPersistentContainerSpy: NSPersistentContainer.Spy!

    var sut: PersistentContainer!

    override func setUp() {
        super.setUp()

        nsPersistentContainer = NSPersistentContainer(
            name: "\(type(of: self))DB",
            managedObjectModel: .singleEntityModel
        )
        nsPersistentContainerSpy = NSPersistentContainer.Spy(nsPersistentContainer: nsPersistentContainer)
    }

    func resetSUT(inMemory: Bool = true, preloaded: Bool = false) {
        sut = PersistentContainer(nsPersistentContainer: nsPersistentContainerSpy, inMemory: inMemory)

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
        guard case PersistentContainer.Error.failedToLoadPersistentStores(let failures) = error else {
            XCTFail()
            return
        }

        XCTAssertEqual(failures.count, nsPersistentContainerSpy.persistentStoreDescriptions.count)
    }

    func testThatSUTStateIsFailedToLoadWhenEachPersistentStoreFailsToLoadSynchronously() {
        nsPersistentContainerSpy.loadPersistentStoreOverrideError = TestError()
        resetSUT()

        XCTAssertThrowsError(try sut.start())

        guard case .failedToLoad(let error) = sut.state else { XCTFail(); return }
        guard case PersistentContainer.Error.failedToLoadPersistentStores(let failures) = error else {
            XCTFail()
            return
        }

        XCTAssertEqual(failures.count, nsPersistentContainerSpy.persistentStoreDescriptions.count)
    }

    func testThatStartCallbackIsCalledWhenLoadingAnAuthenticNSPersistentContainer() {
        let nsPersistentContainer = NSPersistentContainer(
            name: UUID().uuidString,
            managedObjectModel: .singleEntityModel
        )
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
        sut.start { _ in
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
        sut.start { _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertNotEqual(nsPersistentContainer.persistentStoreDescriptions.map { $0.type }, [NSInMemoryStoreType])
    }

    func testThatDeleteSQLiteStoresRemovesDatabaseFilesWhenCalledAfterSUTStarts() throws {
        resetSUT(inMemory: false, preloaded: false)

        try sut.deleteSQLLiteStores()
        XCTAssertFalse(filesExist(for: nsPersistentContainer.persistentStoreDescriptions))

        try sut.start()
        XCTAssertTrue(filesExist(for: nsPersistentContainer.persistentStoreDescriptions))

        XCTAssertThrowsError(try sut.deleteSQLLiteStores()) { (error) in
            guard case PersistentContainer.Error.reinitializationRequired = error else { XCTFail(); return }
        }
        XCTAssertFalse(filesExist(for: nsPersistentContainer.persistentStoreDescriptions))
    }

    func testThatDeleteSQLiteStoresRemovesDatabasesBeforeSUTStarts() throws {
        resetSUT(inMemory: false, preloaded: false)

        try sut.deleteSQLLiteStores()
        XCTAssertFalse(filesExist(for: nsPersistentContainer.persistentStoreDescriptions))

        try sut.start()
        XCTAssertTrue(filesExist(for: nsPersistentContainer.persistentStoreDescriptions))

        resetSUT(inMemory: false, preloaded: false)
        XCTAssertTrue(filesExist(for: nsPersistentContainer.persistentStoreDescriptions))

        try sut.deleteSQLLiteStores()
        XCTAssertFalse(filesExist(for: nsPersistentContainer.persistentStoreDescriptions))
    }

    func paths(for persistentStoreDescriptions: [NSPersistentStoreDescription]) -> [String] {
        var paths = [String]()

        for url in persistentStoreDescriptions.compactMap({ $0.url }) {
            let writeAheadLogURL = url.appendingToLastPathComponent("-wal")
            let writeAheadLogIndexURL = url.appendingToLastPathComponent("-shm")
            paths += [url.path, writeAheadLogURL.path, writeAheadLogIndexURL.path]
        }

        return paths
    }

    func filesExist(for descriptions: [NSPersistentStoreDescription]) -> Bool {
        var filesExist = false

        for path in paths(for: descriptions) {
            filesExist = filesExist || FileManager.default.fileExists(atPath: path)
        }

        return filesExist
    }
}
