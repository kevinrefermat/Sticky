// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

extension PersistentContainer {
    public class ContextProvider {
        private let nsPersistentContainer: NSPersistentContainerProtocol?
        private var fatalNSPersistentContainer: NSPersistentContainerProtocol {
            guard let nsPersistentContainer = nsPersistentContainer else { fatalError("methods on testDouble() are not functional") }
            return nsPersistentContainer
        }

        required init(nsPersistentContainer: NSPersistentContainerProtocol) {
            self.nsPersistentContainer = nsPersistentContainer
        }

        public static func testDouble() -> Self {
            return self.init(nsPersistentContainer: NSPersistentContainer.preloadedInMemoryDouble(for: self))
        }

        public var viewContext: NSManagedObjectContext {
            return fatalNSPersistentContainer.viewContext
        }

        public func newBackgroundContext() -> NSManagedObjectContext {
            return fatalNSPersistentContainer.newBackgroundContext()
        }
    }
}
