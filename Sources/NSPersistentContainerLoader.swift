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

final class NSPersistentContainerLoader {
    private let queue = DispatchQueue(label: "com.\(String(reflecting: type(of: NSPersistentContainerLoader.self)))")

    @discardableResult
    func syncLoad(
        nsPersistentContainer: NSPersistentContainerProtocol,
        handler: ((NSPersistentStoreDescription, Error?) -> Void)? = nil
    ) -> [NSPersistentStoreDescription: Error] {
        var persistentStoreDescriptionToError = [NSPersistentStoreDescription: Error]()

        nsPersistentContainer.persistentStoreDescriptions.forEach { $0.shouldAddStoreAsynchronously = false }

        var notLoadedPersistentStoreDescriptions = Set(nsPersistentContainer.persistentStoreDescriptions)

        let completion: (NSPersistentStoreDescription, Error?) -> Void = { (persistentStoreDescription, error) in
            notLoadedPersistentStoreDescriptions.remove(persistentStoreDescription)
            persistentStoreDescriptionToError[persistentStoreDescription] = error
        }

        let handler = handler ?? { (_, _) in }

        withoutActuallyEscaping(handler) { (handler) in
            nsPersistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
                handler(persistentStoreDescription, error)
                completion(persistentStoreDescription, error)
            }
        }

        assert(
            notLoadedPersistentStoreDescriptions.isEmpty,
            "did not finish loading stores \(notLoadedPersistentStoreDescriptions)"
        )

        return persistentStoreDescriptionToError
    }

    func asyncLoad(
        nsPersistentContainer: NSPersistentContainerProtocol,
        handler: ((NSPersistentStoreDescription, Error?) -> Void)? = nil,
        completion: @escaping ([NSPersistentStoreDescription: Error]) -> Void
    ) {
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
