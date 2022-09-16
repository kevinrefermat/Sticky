// Copyright © 2022 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

public protocol PersistentContainerProtocol {
    var state: PersistentContainer.State { get }
    func start() throws -> PersistentContainer.ContextProvider
    func start(queue: DispatchQueue, completion: @escaping (Result<PersistentContainer.ContextProvider, Swift.Error>) -> Void)
}

open class PersistentContainer: PersistentContainerProtocol {
    private let nsPersistentContainer: NSPersistentContainerProtocol
    private let fileManager: FileManagerProtocol
    private let loader = NSPersistentContainerLoader()
    private let inMemory: Bool

    init(nsPersistentContainer: NSPersistentContainerProtocol, inMemory: Bool = false, fileManager: FileManagerProtocol = FileManager.default) {
        self.nsPersistentContainer = nsPersistentContainer
        self.fileManager = fileManager
        self.inMemory = inMemory
    }

    public convenience init(name: String, managedObjectModel: NSManagedObjectModel? = nil, inMemory: Bool = false, fileManager: FileManagerProtocol = FileManager.default) {
        let nsPersistentContainer: NSPersistentContainer = {
            if let managedObjectModel = managedObjectModel {
                return NSPersistentContainer(name: name, managedObjectModel: managedObjectModel)
            } else {
                return NSPersistentContainer(name: name)
            }
        }()
        self.init(nsPersistentContainer: nsPersistentContainer, inMemory: inMemory, fileManager: fileManager)
    }

    private let _state = Atomic(State.reset)
    public var state: State {
        let state = _state.value
        return state
    }

    private func resetToLoading() throws {
        try _state.modify { (state) in
            guard case .reset = state else { throw Error.invalidStateToCallStartFrom(state) }
            state = .loading
        }
    }

    @discardableResult
    public func start() throws -> ContextProvider {
        try resetToLoading()

        if inMemory {
            nsPersistentContainer.replacePersistentStoreDescriptionsWithSingleInMemoryDescription()
        }

        let persistentStoreDescriptionToError = loader.syncLoad(nsPersistentContainer: nsPersistentContainer)
        guard persistentStoreDescriptionToError.isEmpty else {
            let error = Error.failedToLoadPersistentStores(persistentStoreDescriptionToError)
            _state.value = .failedToLoad(error)
            throw error
        }

        let contextProvider = ContextProvider(nsPersistentContainer: nsPersistentContainer)
        _state.value = .loaded(contextProvider)
        return contextProvider
    }

    public func start(queue: DispatchQueue = .main, completion: @escaping (Result<ContextProvider, Swift.Error>) -> Void) {
        do {
            try resetToLoading()
        } catch {
            queue.async {
                completion(.failure(error))
            }
            return
        }

        if inMemory {
            nsPersistentContainer.replacePersistentStoreDescriptionsWithSingleInMemoryDescription()
        }

        loader.asyncLoad(nsPersistentContainer: nsPersistentContainer) { (persistentStoreDescriptionToError) in
            queue.async {
                guard persistentStoreDescriptionToError.isEmpty else {
                    let error = Error.failedToLoadPersistentStores(persistentStoreDescriptionToError)
                    self._state.value = .failedToLoad(error)
                    completion(.failure(error))
                    return
                }

                let contextProvider = ContextProvider(nsPersistentContainer: self.nsPersistentContainer)
                self._state.value = .loaded(contextProvider)
                completion(.success(contextProvider))
            }
        }
    }

    public func deleteSQLLiteStores() throws {
        func deleteFileIfExists(at url: URL) throws {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(atPath: url.path)
            }
        }

        func deleteDatabaseFiles(for urls: [URL]) throws {
            for url in urls {
                try deleteFileIfExists(at: url)

                let writeAheadLogURL = url.appendingToLastPathComponent("-wal")
                try deleteFileIfExists(at: writeAheadLogURL)

                let writeAheadLogIndexURL = url.appendingToLastPathComponent("-shm")
                try deleteFileIfExists(at: writeAheadLogIndexURL)
            }
        }

        let urls = nsPersistentContainer.persistentStoreDescriptions
            .filter { $0.type == NSSQLiteStoreType }
            .compactMap { $0.url }

        switch state {
        case .loading:
            throw PersistentContainer.Error.cannotDeleteSQLLiteStoresWhileLoading
        case .loaded:
            try urls.forEach { try nsPersistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: $0, ofType: NSSQLiteStoreType) }
            try deleteDatabaseFiles(for: urls)
            throw PersistentContainer.Error.reinitializationRequired
        case .reset, .failedToLoad:
            try deleteDatabaseFiles(for: urls)
        }
    }
}
