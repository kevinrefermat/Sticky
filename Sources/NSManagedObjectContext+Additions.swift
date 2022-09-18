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
    @discardableResult
    public func create<T: NSManagedObject>(_ type: T.Type) throws -> T {
        let entity = try entity(for: type)
        let managedObject = T.init(entity: entity, insertInto: self)
        return managedObject
    }

    public func fetch<T: NSManagedObject>(_ type: T.Type, block: ((NSFetchRequest<T>) -> Void)? = nil) throws -> [T] {
        let request = NSFetchRequest<T>()
        block?(request)
        request.entity = try entity(for: type)
        let managedObjects = try fetch(request) as [T]
        return managedObjects
    }

    public func delete<T: NSManagedObject>(_ type: T.Type, block: ((NSFetchRequest<T>) -> Void)? = nil) throws {
        let managedObjects = try fetch(type, block: block)
        managedObjects.forEach(delete)
    }

    public func entity<T: NSManagedObject>(for type: T.Type) throws -> NSEntityDescription {
        let persistentStoreCoordinator = try persistentStoreCoordinator()
        let managedObjectModel = persistentStoreCoordinator.managedObjectModel
        let className = String(reflecting: type)
        let entity = try managedObjectModel.entity(for: className)
        return entity
    }

    private func persistentStoreCoordinator() throws -> NSPersistentStoreCoordinator {
        enum Error: Swift.Error {
            case persistentStoreCoordinatorWasNil
        }

        guard let persistentStoreCoordinator = persistentStoreCoordinator else {
            throw Error.persistentStoreCoordinatorWasNil
        }

        return persistentStoreCoordinator
    }
}
