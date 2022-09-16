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

public final class PersistentContainerDouble: PersistentContainerProtocol {
    public var state: PersistentContainer.State = .reset
    public var startResult: Result<PersistentContainer.ContextProvider, Error> = .success(
        .testDouble(name: "PersistentContainerDoubleDB")
    )
    public var shouldAutoCallCompletion = false

    public init() {}

    public struct StartInvocation {
        public let queue: DispatchQueue
        public let completion: (Result<PersistentContainer.ContextProvider, Error>) -> Void
    }
    public var startInvocations = [StartInvocation]()
    public func start(
        queue: DispatchQueue = .main,
        completion: @escaping (Result<PersistentContainer.ContextProvider, Error>) -> Void
    ) {
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
