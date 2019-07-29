// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

extension NSPersistentContainerProtocol {
    func replacePersistentStoreDescriptionsWithSingleInMemoryDescription() {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentStoreDescriptions = [description]
    }
}
