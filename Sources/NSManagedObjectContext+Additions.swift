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

import Foundation
import CoreData

extension NSManagedObjectContext {
    /// Errors specific to `NSManagedObjectContext`.
    enum Error: Swift.Error {
        /// The context does not have an associated `NSPersistentStoreCoordinator`.
        case persistentStoreCoordinatorWasNil
        /// The managed object model associated with the persistent store coordinate does not contain an entity with the specified class name.
        case modelDoesNotContainEntityWithClassName(String)
    }

    /// Asynchronously performs the specified block on the context’s queue.
    /// - Parameters:
    ///   - block: The block to perform.
    ///   - context: The current context.
    ///
    /// The receiving context is retained until `block` is executed.
    public func perform(block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        perform {
            block(self)
            self.reset()
        }
    }

    /// Synchronously performs the specified block on the context’s queue.
    /// - Parameters:
    ///   - block: The block to perform.
    ///   - context: The current context.
    /// - Returns: The value returned by `block`, or `Void` if no value returned.
    ///
    /// Errors thrown in `block` are rethrown.
    public func performAndWait<T>(block: (_ context: NSManagedObjectContext) throws -> T) rethrows -> T {
        let value = try executePerformAndWait(
            block: block,
            rescue: { throw $0 }
        )

        return value
    }

    private func executePerformAndWait<T>(
        block: (NSManagedObjectContext) throws -> T,
        rescue: (Swift.Error) throws -> T
    ) rethrows -> T {
        var result: Result<T, Swift.Error>?

        withoutActuallyEscaping(block) { block in
            performAndWait {
                result = Result { try block(self) }
                reset()
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

    /// Creates an instance of type `T` in the context.
    /// - Parameters:
    ///   - type: The type to create.
    ///   - presets: A set of preset values to apply after object creation.
    /// - Returns: An instance of type `T` with the specified presets set.
    @discardableResult
    public func create<T: NSManagedObject>(_: T.Type, with presets: Set<Preset<T>> = []) throws -> T {
        return try T(self, with: presets)
    }

    /// Returns an array of items of the specified type that meet the fetch request’s critieria.
    /// - Parameters:
    ///   - type: The type of `NSManagedObject` to fetch.
    ///   - block: An optional block that allows customization of the fetch request.
    ///   - fetchRequest: A fetch request that can be customized before the execution of the fetch.
    /// - Returns: An array of `T` that meet the criteria specified by request fetched from the receiver and from the persistent stores associated with the receiver’s persistent store coordinator. If no objects match the criteria specified by request, returns an empty array.
    public func fetch<T: NSManagedObject>(
        _ type: T.Type = T.self,
        block: ((_ fetchRequest: NSFetchRequest<T>) -> Void)? = nil
    ) throws -> [T] {
        let request = NSFetchRequest<T>()
        block?(request)
        request.entity = try entity(for: T.self)
        let managedObjects = try fetch(request) as [T]
        return managedObjects
    }


    /// Deletes objects of specified type, with an option
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isDeleted: <#isDeleted description#>
    public func delete<T: NSManagedObject>(_ type: T.Type = T.self, isDeleted: (T) -> Bool) throws {
        let managedObjects = try fetch(type)
        managedObjects.forEach {
            if isDeleted($0) {
                delete($0)
            }
        }
    }

    public func deleteAllAndSave<T: NSManagedObject>(_ type: T.Type = T.self) throws {
        guard let persistentStoreCoordinator = persistentStoreCoordinator else {
            throw Error.persistentStoreCoordinatorWasNil
        }

        let hasInMemoryStore = persistentStoreCoordinator.persistentStores.contains(
            where: { $0.type == NSInMemoryStoreType }
        )

        if hasInMemoryStore {
            try delete(T.self, isDeleted: { _ in true })
            try save()
        } else {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
            fetchRequest.entity = try entity(for: T.self)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs
            guard let batchDeleteResult = try persistentStoreCoordinator.execute(
                deleteRequest,
                with: self
            ) as? NSBatchDeleteResult else {
                fatalError("An executed NSBatchDeleteRequest should always have return type NSBatchDeleteResult")
            }
            guard let deletedObjectIDs = batchDeleteResult.result as? [NSManagedObjectID] else {
                fatalError("""
                The NSBatchDeleteResult from a NSBatchDeleteRequest with resultType .resultTypeObjectIDs \
                should always have type [NSManagedObjectID]
                """)
            }
            let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: deletedObjectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
        }
    }

    /// Returns the `NSEntityDescription` for the specified type associated with the context's managed object model.
    /// - Parameter type: The specified type.
    /// - Returns: The `NSEntityDescription` of the specified type according to the context's managed object model.
    ///
    /// There is a supplied class method
    public func entity<T: NSManagedObject>(for type: T.Type = T.self) throws -> NSEntityDescription {
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
