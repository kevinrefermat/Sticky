// MIT License
//
// Copyright (c) 2022 Kevin Refermat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

final class Atomic<Value> {
    private let queue = DispatchQueue(
        label: "com.\(String(reflecting: Atomic.self))<\(String(describing: Value.self))>",
        attributes: .concurrent
    )

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

    func modify(block: (inout Value) throws -> Void) rethrows {
        try queue.sync(flags: .barrier) {
            try block(&_value)
        }
    }
}
