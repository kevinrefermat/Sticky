// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

extension NSManagedObjectContext {
    public func performAndWait<T>(block: (NSManagedObjectContext) throws -> T) rethrows -> T {
        let value = try executePerformAndWait(
            block: block,
            rescue: { throw $0 }
        )

        return value
    }

    private func executePerformAndWait<T>(block: (NSManagedObjectContext) throws -> T, rescue: ((Error) throws -> (T))) rethrows -> T {
        var result: Result<T, Error>?

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

    public func create<T: NSManagedObject>(_: T.Type) throws -> T {
        let entity = try self.entity(for: T.self)
        let managedObject = T(entity: entity, insertInto: self)
        return managedObject
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
        let persistentStoreCoordinator = try nonnullPersistentStoreCoordinator()
        let managedObjectModel = persistentStoreCoordinator.managedObjectModel
        let className = String(reflecting: T.self)
        let entity = try nonnullEntity(for: className, in: managedObjectModel)
        return entity
    }

    private func nonnullPersistentStoreCoordinator() throws -> NSPersistentStoreCoordinator {
        enum Error: Swift.Error {
            case mustHaveNonnullPersistentStoreCoordinator
        }

        guard let persistentStoreCoordinator = persistentStoreCoordinator else {
            throw Error.mustHaveNonnullPersistentStoreCoordinator
        }

        return persistentStoreCoordinator
    }

    private func nonnullEntity(for className: String, in managedObjectModel: NSManagedObjectModel) throws -> NSEntityDescription {
        enum Error: Swift.Error {
            case modelDoesNotHaveEntityWithClassName(String)
        }

        guard let entity = managedObjectModel.entities.first(where: { $0.managedObjectClassName == className }) else {
            throw Error.modelDoesNotHaveEntityWithClassName(className)
        }

        return entity
    }
}
