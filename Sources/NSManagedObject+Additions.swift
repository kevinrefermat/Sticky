// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

extension NSManagedObject {
    public convenience init(_ context: NSManagedObjectContext) throws {
        let entity = try context.entity(for: type(of: self))

        self.init(entity: entity, insertInto: context)
    }

    /// This initializer has been defined so that a compiler error is generated (ambigious
    /// use of `init(context: NSManagedObjectContext)`) in the event that this initializer's
    /// identical CoreData twin is called. The Apple version of this initializer does not use
    /// the context arg to get the appropriate NSManagedObjectModel. Instead it does it in
    /// such a way that `+entity()` is called on the `NSManagedObject` type, which looks up to
    /// see which model should be used. If more than one model is in memory that contains the entity,
    /// it gets confused and spews warnings and errors in the console. This happens during
    /// tests when multiple `PersistentContainers` are often in memory at once due to concurrent tests.
    ///
    /// - Parameter context: The context that has a `nonnull persistentStoreCoordinator` with an
    /// `NSManagedObjectModel` that contains an entity with the class name of the initialized
    /// object.
    convenience init(context: NSManagedObjectContext) { fatalError() }
}
