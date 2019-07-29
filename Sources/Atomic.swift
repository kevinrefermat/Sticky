// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation

final class Atomic<Value> {
    private let queue = DispatchQueue(label: "com.\(String(reflecting: Atomic.self))<\(String(describing: Value.self))>", attributes: .concurrent)

    private var _value: Value

    init(_ value: Value) {
        self._value = value
    }

    var value: Value {
        get {
            return queue.sync {
                return _value
            }
        }
        set {
            queue.sync(flags: .barrier) {
                _value = newValue
            }
        }
    }

    func modify(block: (inout Value) throws -> ()) rethrows {
        try queue.sync(flags: .barrier) {
            try block(&_value)
        }
    }
}
