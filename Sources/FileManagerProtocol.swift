// Copyright © 2022 Kevin Refermat. All rights reserved.

import Foundation

public protocol FileManagerProtocol {
    func fileExists(atPath path: String) -> Bool
    func removeItem(atPath path: String) throws
}

extension FileManager: FileManagerProtocol {}
