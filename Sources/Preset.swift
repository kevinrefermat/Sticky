// Copyright © 2019 Kevin Refermat. All rights reserved.

import CoreData

public struct Preset<Receiver> {
    let keyPath: AnyKeyPath
    let value: Any

    public init<T>(key keyPath: KeyPath<Receiver, T>, value: T) {
        self.keyPath = keyPath
        self.value = value
    }
}

extension Preset: Hashable {
    public static func == (lhs: Preset<Receiver>, rhs: Preset<Receiver>) -> Bool {
        return lhs.keyPath == rhs.keyPath
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(keyPath)
    }
}
