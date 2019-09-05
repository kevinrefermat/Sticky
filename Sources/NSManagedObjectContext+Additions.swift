// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

extension NSManagedObjectContext {
    enum Error: Swift.Error {
        case persistentStoreCoordinatorWasNil
        case modelDoesNotContainEntityWithClassName(String)
    }

    public func performAndWait<T>(block: (NSManagedObjectContext) throws -> T) rethrows -> T {
        let value = try executePerformAndWait(
            block: block,
            rescue: { throw $0 }
        )

        return value
    }

    private func executePerformAndWait<T>(block: (NSManagedObjectContext) throws -> T, rescue: ((Swift.Error) throws -> (T))) rethrows -> T {
        var result: Result<T, Swift.Error>?

        withoutActuallyEscaping(block) { _block in
            performAndWait {
                result = Result { try _block(self) }
            }
        }

        switch result! {
        case .success(let value):
            return value
        case .failure(let error):
            let value = try rescue(error)
            return value
        }
    }

    @discardableResult
    public func create<T: NSManagedObject>(_: T.Type, with presets: Set<Preset<T>> = []) throws -> T {
        return try T(self, with: presets)
    }

    public func fetch<T: NSManagedObject>(_: T.Type, block: ((NSFetchRequest<T>) -> Void)? = nil) throws -> [T] {
        let request = NSFetchRequest<T>()
        request.entity = try entity(for: T.self)
        block?(request)
        let managedObjects = try fetch(request) as [T]
        return managedObjects
    }

    public func delete<T: NSManagedObject>(_: T.Type) throws {
        let managedObjects = try fetch(T.self)
        managedObjects.forEach { delete($0) }
    }

    public func entity<T: NSManagedObject>(for _: T.Type) throws -> NSEntityDescription {
        guard let persistentStoreCoordinator = persistentStoreCoordinator else {
            throw Error.persistentStoreCoordinatorWasNil
        }

        let managedObjectModel = persistentStoreCoordinator.managedObjectModel
        let className = String(reflecting: T.self)
        guard let entity = managedObjectModel.entities.first(where: { $0.managedObjectClassName == className }) else {
            throw Error.modelDoesNotContainEntityWithClassName(className)
        }
        return entity
    }
}
