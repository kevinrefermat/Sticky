// Copyright © 2022 Kevin Refermat. All rights reserved.

import Foundation

extension PersistentContainer {
    public enum State {
        case reset
        case loading
        case loaded(ContextProvider)
        case failedToLoad(Swift.Error)
    }
}
