// Copyright © 2022 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

protocol NSPersistentContainerProtocol: class {
    var persistentStoreCoordinator: NSPersistentStoreCoordinator { get }

    var persistentStoreDescriptions: [NSPersistentStoreDescription] { get set }

    func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void)

    var viewContext: NSManagedObjectContext { get }

    func newBackgroundContext() -> NSManagedObjectContext

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)
}

extension NSPersistentContainer: NSPersistentContainerProtocol {}
