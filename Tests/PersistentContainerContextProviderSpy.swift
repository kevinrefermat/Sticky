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
import CoreData
@testable import Sticky

extension PersistentContainer {
    public final class ContextProviderSpy: ContextProvider {
        private static let queue = DispatchQueue(label: "com.\(String(reflecting: ContextProviderSpy.self))")

        private let _viewContextCallCount = Atomic(0)
        public var viewContextCallCount: Int { return _viewContextCallCount.value }
        public override var viewContext: NSManagedObjectContext {
            _viewContextCallCount.modify { $0 += 1 }
            return super.viewContext
        }

        private let _newBackgroundContextCallCount = Atomic(0)
        public var newBackgroundContextCallCount: Int { return _newBackgroundContextCallCount.value }
        public override func newBackgroundContext() -> NSManagedObjectContext {
            _newBackgroundContextCallCount.modify { $0 += 1 }
            return super.newBackgroundContext()
        }
    }
}
