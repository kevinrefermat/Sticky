// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

public protocol PersistentContainerProtocol {
    var state: PersistentContainer.State { get }
    func start() throws -> PersistentContainer.ContextProvider
    func start(queue: DispatchQueue, completion: @escaping (Result<PersistentContainer.ContextProvider, Swift.Error>) -> Void)
}

open class PersistentContainer: PersistentContainerProtocol {
    private let nsPersistentContainer: NSPersistentContainerProtocol
    private let loader = NSPersistentContainerLoader()
    private let inMemory: Bool

    init(nsPersistentContainer: NSPersistentContainerProtocol, inMemory: Bool = false) {
        self.nsPersistentContainer = nsPersistentContainer
        self.inMemory = inMemory
    }

    public convenience init(name: String, managedObjectModel: NSManagedObjectModel? = nil, inMemory: Bool = false) {
        let nsPersistentContainer: NSPersistentContainer = {
            if let managedObjectModel = managedObjectModel {
                return NSPersistentContainer(name: name, managedObjectModel: managedObjectModel)
            } else {
                return NSPersistentContainer(name: name)
            }
        }()
        self.init(nsPersistentContainer: nsPersistentContainer, inMemory: inMemory)
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
}
