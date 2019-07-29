// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

final class NSPersistentContainerLoader {
    private let queue = DispatchQueue(label: "com.\(String(reflecting: type(of: NSPersistentContainerLoader.self)))")

    @discardableResult
    func syncLoad(nsPersistentContainer: NSPersistentContainerProtocol, handler: ((NSPersistentStoreDescription, Error?) -> ())? = nil) -> [NSPersistentStoreDescription: Error] {
        var persistentStoreDescriptionToError = [NSPersistentStoreDescription: Error]()

        nsPersistentContainer.persistentStoreDescriptions.forEach { $0.shouldAddStoreAsynchronously = false }

        var notLoadedPersistentStoreDescriptions = Set(nsPersistentContainer.persistentStoreDescriptions)

        let completion: (NSPersistentStoreDescription, Error?) -> () = { (persistentStoreDescription, error) in
            notLoadedPersistentStoreDescriptions.remove(persistentStoreDescription)
            persistentStoreDescriptionToError[persistentStoreDescription] = error
        }

        let handler = handler ?? { (_, _) in }
        
        withoutActuallyEscaping(handler) { (_handler) in
            nsPersistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
                _handler(persistentStoreDescription, error)
                completion(persistentStoreDescription, error)
            }
        }

        assert(notLoadedPersistentStoreDescriptions.isEmpty, "did not finish loading stores \(notLoadedPersistentStoreDescriptions)")

        return persistentStoreDescriptionToError
    }

    func asyncLoad(nsPersistentContainer: NSPersistentContainerProtocol, handler: ((NSPersistentStoreDescription, Error?) -> ())? = nil, completion: @escaping ([NSPersistentStoreDescription: Error]) -> ()) {
        var persistentStoreDescriptionToError = [NSPersistentStoreDescription: Error]()

        nsPersistentContainer.persistentStoreDescriptions.forEach { $0.shouldAddStoreAsynchronously = true }

        let expectedCallCount = nsPersistentContainer.persistentStoreDescriptions.count
        var callCount = 0
        nsPersistentContainer.loadPersistentStores { [queue] (persistentStoreDescription, error) in
            handler?(persistentStoreDescription, error)

            queue.sync {
                callCount += 1

                guard let error = error else { return }

                persistentStoreDescriptionToError[persistentStoreDescription] = error
            }

            guard callCount == expectedCallCount else { return }
            completion(persistentStoreDescriptionToError)
        }
    }
}
