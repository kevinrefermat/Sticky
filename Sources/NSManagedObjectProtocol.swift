// Copyright © 2022 Kevin Refermat. All rights reserved.

import CoreData

public protocol NSManagedObjectProtocol {
    func setValue(_ value: Any?, forKey key: String)
}

extension NSManagedObjectProtocol {
    func setKeyValuePresets(_ presets: Set<Preset<Self>> = []) throws {
        try presets.forEach {
            try setValue($0.value, atAnyKeyPath: $0.keyPath)
        }
    }

    public func setValue<T>(_ value: T?, atKeyPath keyPath: KeyPath<Self, T>) throws {
        try setValue(value, atAnyKeyPath: keyPath)
    }

    private func setValue(_ value: Any?, atAnyKeyPath anyKeyPath: AnyKeyPath) throws {
        let keyPath = try ValidatedKVCKeyPath(keyPath: anyKeyPath)
        setValue(value, forKey: keyPath._kvcKeyPathString)
    }
}

extension NSManagedObjectProtocol where Self: NSManagedObject {
    @discardableResult
    public init(_ context: NSManagedObjectContext, with presets: Set<Preset<Self>> = []) throws {
        let entity = try context.entity(for: Self.self)
        self.init(entity: entity, insertInto: context)

        try setKeyValuePresets(presets)
    }
}
