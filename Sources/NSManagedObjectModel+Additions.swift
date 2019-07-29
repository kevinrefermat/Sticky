// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

@objc(ExampleEntity)
final class ExampleEntity: NSManagedObject {
    @objc @NSManaged var uuidString: String?
}

extension NSManagedObjectModel {
    static var singleEntityModel: NSManagedObjectModel {
        let attributeDescription = NSAttributeDescription()
        attributeDescription.name = #keyPath(ExampleEntity.uuidString)
        attributeDescription.attributeType = .stringAttributeType
        attributeDescription.isOptional = false

        let entity = NSEntityDescription()
        entity.name = String(describing: ExampleEntity.self)
        entity.managedObjectClassName = String(reflecting: ExampleEntity.self)
        entity.properties = [attributeDescription]

        let managedObjectModel = self.init()
        managedObjectModel.entities = [entity]
        return managedObjectModel
    }
}
