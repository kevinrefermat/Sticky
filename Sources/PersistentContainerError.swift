// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

extension PersistentContainer {
    public enum Error: Swift.Error {
        case failedToLoadPersistentStores([NSPersistentStoreDescription: Swift.Error])
        case invalidStateToCallStartFrom(PersistentContainer.State)
        case cannotDeleteSQLLiteStoresWhileLoading
        case restartRequired
    }
}
