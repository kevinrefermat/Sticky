// Copyright © 2019 Kevin Refermat. All rights reserved.

import Foundation

extension URL {
    func appendingToLastPathComponent(_ string: String) -> URL {
        var newURL = self
        let newLastPathComponent = newURL.lastPathComponent + string
        newURL.deleteLastPathComponent()
        newURL.appendPathComponent(newLastPathComponent)
        return newURL
    }
}
