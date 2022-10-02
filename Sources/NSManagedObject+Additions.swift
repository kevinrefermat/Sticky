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

extension NSManagedObject: NSManagedObjectProtocol {

    /// This initializer has been defined so that a compiler error is generated (ambigious use of `init(context: NSManagedObjectContext)`) in the event that this initializer's identical CoreData twin is called.
    ///
    /// The Apple version of this initializer does not use the passed in `context` arg to get the appropriate `NSManagedObjectModel`. Instead, it does it in such a way that `NSManagedObject.entity()` is called, which looks up to see which model should be used. If more than one model is in memory that contains the entity, it gets confused and spews warnings and errors in the console. This happens during tests when multiple `PersistentContainers` are often in memory at once due to concurrent tests.
    ///
    /// When running unit tests, it is not uncommon to have the same model loaded twice: once for the core data stack running in your application and once for the in memory core data stack being used by your unit tests. When the CoreData version of this method is called, instead of
    ///
    /// why
    ///
    /// why detailed
    ///
    /// https://stackoverflow.com/a/53498777
    convenience init(context: NSManagedObjectContext) { fatalError() }
}
