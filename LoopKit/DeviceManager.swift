//
//  DeviceManager.swift
//  LoopKit
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import Foundation


public protocol DeviceManager: class, CustomDebugStringConvertible {
    typealias RawStateValue = [String: Any]

    /// The identifier of the manager. This should be unique
    static var managerIdentifier: String { get }

    /// A title describing this type of manager
    static var localizedTitle: String { get }

    /// A title describing this manager
    var localizedTitle: String { get }

    /// Initializes the manager with its previously-saved state
    ///
    /// Return nil if the saved state is invalid to prevent restoration
    ///
    /// - Parameter rawState: The last state
    init?(rawState: RawStateValue)

    /// The current, serializable state of the manager
    var rawState: RawStateValue { get }
}


public extension DeviceManager {
    var localizedTitle: String {
        return type(of: self).localizedTitle
    }
}
