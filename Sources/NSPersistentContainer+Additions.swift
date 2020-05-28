// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

extension NSPersistentContainer {
    static func preloadedInMemoryDouble(name: String, managedObjectModel: NSManagedObjectModel) -> Self {
        let nsPersistentContainer = self.init(name: name, managedObjectModel: managedObjectModel)
        nsPersistentContainer.replacePersistentStoreDescriptionsWithSingleInMemoryDescription()
        NSPersistentContainerLoader().syncLoad(nsPersistentContainer: nsPersistentContainer)
        return nsPersistentContainer
    }

    func replacePersistentStoreDescriptionsWithSingleInMemoryDescription() {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentStoreDescriptions = [description]
    }
}
