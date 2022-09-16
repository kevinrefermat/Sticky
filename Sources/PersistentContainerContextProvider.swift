// Copyright © 2022 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

extension PersistentContainer {
    public class ContextProvider {
        private let nsPersistentContainer: NSPersistentContainerProtocol

        required init(nsPersistentContainer: NSPersistentContainerProtocol) {
            self.nsPersistentContainer = nsPersistentContainer
        }

        public static func testDouble(name: String) -> Self {
            return self.init(nsPersistentContainer: NSPersistentContainer.preloadedInMemoryDouble(name: name, managedObjectModel: .init()))
        }

        public var viewContext: NSManagedObjectContext {
            return nsPersistentContainer.viewContext
        }

        public func newBackgroundContext() -> NSManagedObjectContext {
            return nsPersistentContainer.newBackgroundContext()
        }
    }
}
