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

extension NSManagedObjectModel {
    func entity(for className: String) throws -> NSEntityDescription {
        enum Error: Swift.Error {
            case modelDoesNotContainEntityWithClassName(String)
            case modelContainsMultipleEntitiesWithClassName(String, Int)
        }

        let matchingEntities = entities.filter { $0.managedObjectClassName == className }

        if let entity = matchingEntities.first {
            if matchingEntities.count > 1 {
                throw Error.modelContainsMultipleEntitiesWithClassName(className, matchingEntities.count)
            } else {
                return entity
            }
        } else {
            throw Error.modelDoesNotContainEntityWithClassName(className)
        }
    }
}
