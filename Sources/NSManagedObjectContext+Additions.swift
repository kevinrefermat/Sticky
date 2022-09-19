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
    public func fetch<T: NSManagedObject>(_: T.Type, block: ((NSFetchRequest<T>) -> Void)? = nil) throws -> [T] {
        let request = NSFetchRequest<T>()
        block?(request)
        request.entity = try T.entity(self)
        let managedObjects = try fetch(request) as [T]
        return managedObjects
    }

    public func delete<T: NSManagedObject>(_: T.Type, isDeleted: (T) -> Bool) throws {
        let managedObjects = try fetch(T.self)
        managedObjects.forEach {
            if isDeleted($0) {
                delete($0)
            }
        }
    }

    public func deleteAllAndSave<T: NSManagedObject>(_: T.Type) throws {
        guard let persistentStoreCoordinator = persistentStoreCoordinator else { fatalError() }

        let hasInMemoryStore = persistentStoreCoordinator.persistentStores.contains(
            where: { $0.type == NSInMemoryStoreType }
        )

        if hasInMemoryStore {
            try delete(T.self, isDeleted: { _ in true })
            try save()
        } else {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest()
            fetchRequest.entity = try T.entity(self)
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

    func persistentStoreCoordinator() throws -> NSPersistentStoreCoordinator {
        enum Error: Swift.Error {
            case persistentStoreCoordinatorWasNil
        }

        guard let persistentStoreCoordinator = persistentStoreCoordinator else {
            throw Error.persistentStoreCoordinatorWasNil
        }

        return persistentStoreCoordinator
    }
}
