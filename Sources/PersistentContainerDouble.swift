// Copyright © 2022 Kevin Refermat. All rights reserved.

import Foundation
import CoreData

public final class PersistentContainerDouble: PersistentContainerProtocol {
    public var state: PersistentContainer.State = .reset
    public var startResult: Result<PersistentContainer.ContextProvider, Error> = .success(.testDouble(name: "PersistentContainerDoubleDB"))
    public var shouldAutoCallCompletion = false

    public init() {}

    public struct StartInvocation {
        public let queue: DispatchQueue
        public let completion: (Result<PersistentContainer.ContextProvider, Error>) -> Void
    }
    public var startInvocations = [StartInvocation]()
    public func start(queue: DispatchQueue = .main, completion: @escaping (Result<PersistentContainer.ContextProvider, Error>) -> Void) {
        let result = startResult
        startInvocations.append(StartInvocation(queue: queue, completion: completion))

        if shouldAutoCallCompletion {
            queue.async {
                completion(result)
            }
        }
    }

    public func start() throws -> PersistentContainer.ContextProvider {
        switch startResult {
        case .success(let contextProvider):
            return contextProvider
        case .failure(let error):
            throw error
        }
    }
}

