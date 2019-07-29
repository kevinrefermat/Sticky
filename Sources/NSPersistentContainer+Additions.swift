// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

extension NSPersistentContainer {
    static func preloadedInMemoryDouble(for owner: Any) -> Self {
        let nsPersistentContainer = self.init(name: "\(String(describing: type(of: owner)))DB", managedObjectModel: .singleEntityModel)
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
