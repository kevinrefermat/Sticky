// Copyright © 2022 Kevin Refermat. All rights reserved.

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
