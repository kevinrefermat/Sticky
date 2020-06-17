// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation
import CoreData
@testable import Sticky

extension NSPersistentContainer {
    final class Spy: NSPersistentContainerProtocol {
        var persistentStoreCoordinator: NSPersistentStoreCoordinator { nsPersistentContainer.persistentStoreCoordinator }

        private let nsPersistentContainer: NSPersistentContainer

        init(nsPersistentContainer: NSPersistentContainer) {
            self.nsPersistentContainer = nsPersistentContainer
        }

        var persistentStoreDescriptions: [NSPersistentStoreDescription] {
            get {
                let persistentStoreDescriptions = nsPersistentContainer.persistentStoreDescriptions
                return persistentStoreDescriptions
            }

            set {
                nsPersistentContainer.persistentStoreDescriptions = newValue
            }
        }

        var loadPersistentStoreOverrideError: Error?
        var loadPersistentStoresCallCount = 0
        func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void) {
            loadPersistentStoresCallCount += 1
            nsPersistentContainer.loadPersistentStores { [weak self] (persistentStoreDescription, error) in
                guard let self = self else { return }

                block(persistentStoreDescription, self.loadPersistentStoreOverrideError ?? error)
            }
        }

        var viewContext: NSManagedObjectContext {
            return nsPersistentContainer.viewContext
        }

        var newBackgroundContextCallCount = 0
        func newBackgroundContext() -> NSManagedObjectContext {
            newBackgroundContextCallCount += 1
            return nsPersistentContainer.newBackgroundContext()
        }

        var performBackgroundTaskCallCount = 0
        func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
            performBackgroundTaskCallCount += 1
            return nsPersistentContainer.performBackgroundTask(block)
        }
    }
}
