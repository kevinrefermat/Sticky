// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation

struct ValidatedKVCKeyPath {
    enum Error: Swift.Error {
        case kvcKeyPathStringWasNil
    }

    let _kvcKeyPathString: String

    init(keyPath: AnyKeyPath) throws {
        guard let _kvcKeyPathString = keyPath._kvcKeyPathString else {
            throw Error.kvcKeyPathStringWasNil
        }

        self._kvcKeyPathString = _kvcKeyPathString
    }
}
