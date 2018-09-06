//
//  KeychainManager.swift
//  Loop
//
//  Created by Nate Racklyeft on 6/26/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation
import Security


public enum KeychainManagerError: Error {
    case add(OSStatus)
    case copy(OSStatus)
    case delete(OSStatus)
    case unknownResult
}


/**

 Influenced by https://github.com/marketplacer/keychain-swift
 */
public struct KeychainManager {
    typealias Query = [String: NSObject]

    public init() { }

    var accessibility: CFString = kSecAttrAccessibleAfterFirstUnlock

    var accessGroup: String?

    public struct InternetCredentials: Equatable {
        public let username: String
        public let password: String
        public let url: URL

        public init(username: String, password: String, url: URL) {
            self.username = username
            self.password = password
            self.url = url
        }
    }

    // MARK: - Convenience methods

    private func query(by class: CFString) -> Query {
        var query: Query = [kSecClass as String: `class`]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as NSObject?
        }

        return query
    }

    private func queryForGenericPassword(by service: String) -> Query {
        var query = self.query(by: kSecClassGenericPassword)

        query[kSecAttrService as String] = service as NSObject?

        return query
    }

    private func queryForInternetPassword(account: String? = nil, url: URL? = nil, label: String? = nil) -> Query {
        var query = self.query(by: kSecClassInternetPassword)

        if let account = account {
            query[kSecAttrAccount as String] = account as NSObject?
        }

        if let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            for (key, value) in components.keychainAttributes {
                query[key] = value
            }
        }

        if let label = label {
            query[kSecAttrLabel as String] = label as NSObject?
        }

        return query
    }

    private func updatedQuery(_ query: Query, withPassword password: String) throws -> Query {
        var query = query

        guard let value = password.data(using: String.Encoding.utf8) else {
            throw KeychainManagerError.add(errSecDecode)
        }

        query[kSecValueData as String] = value as NSObject?
        query[kSecAttrAccessible as String] = accessibility

        return query
    }

    func delete(_ query: Query) throws {
        let statusCode = SecItemDelete(query as CFDictionary)

        guard statusCode == errSecSuccess || statusCode == errSecItemNotFound else {
            throw KeychainManagerError.delete(statusCode)
        }
    }

    // MARK: – Generic Passwords

    public func replaceGenericPassword(_ password: String?, forService service: String) throws {
        var query = queryForGenericPassword(by: service)

        try delete(query)

        guard let password = password else {
            return
        }

        query = try updatedQuery(query, withPassword: password)

        let statusCode = SecItemAdd(query as CFDictionary, nil)

        guard statusCode == errSecSuccess else {
            throw KeychainManagerError.add(statusCode)
        }
    }

    public func getGenericPasswordForService(_ service: String) throws -> String {
        var query = queryForGenericPassword(by: service)

        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?

        let statusCode = SecItemCopyMatching(query as CFDictionary, &result)

        guard statusCode == errSecSuccess else {
            throw KeychainManagerError.copy(statusCode)
        }

        guard let passwordData = result as? Data, let password = String(data: passwordData, encoding: String.Encoding.utf8) else {
            throw KeychainManagerError.unknownResult
        }

        return password
    }

    // MARK – Internet Passwords

    public func setInternetPassword(_ password: String, account: String, atURL url: URL, label: String? = nil) throws {
        var query = try updatedQuery(queryForInternetPassword(account: account, url: url, label: label), withPassword: password)

        query[kSecAttrAccount as String] = account as NSObject?

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            for (key, value) in components.keychainAttributes {
                query[key] = value
            }
        }

        if let label = label {
            query[kSecAttrLabel as String] = label as NSObject?
        }

        let statusCode = SecItemAdd(query as CFDictionary, nil)

        guard statusCode == errSecSuccess else {
            throw KeychainManagerError.add(statusCode)
        }
    }

    public func replaceInternetCredentials(_ credentials: InternetCredentials?, forAccount account: String) throws {
        let query = queryForInternetPassword(account: account)

        try delete(query)

        if let credentials = credentials {
            try setInternetPassword(credentials.password, account: credentials.username, atURL: credentials.url)
        }
    }

    public func replaceInternetCredentials(_ credentials: InternetCredentials?, forLabel label: String) throws {
        let query = queryForInternetPassword(label: label)

        try delete(query)

        if let credentials = credentials {
            try setInternetPassword(credentials.password, account: credentials.username, atURL: credentials.url, label: label)
        }
    }

    public func replaceInternetCredentials(_ credentials: InternetCredentials?, forURL url: URL) throws {
        let query = queryForInternetPassword(url: url)

        try delete(query)

        if let credentials = credentials {
            try setInternetPassword(credentials.password, account: credentials.username, atURL: credentials.url)
        }
    }

    public func getInternetCredentials(account: String? = nil, url: URL? = nil, label: String? = nil) throws -> InternetCredentials {
        var query = queryForInternetPassword(account: account, url: url, label: label)

        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?

        let statusCode: OSStatus = SecItemCopyMatching(query as CFDictionary, &result)

        guard statusCode == errSecSuccess else {
            throw KeychainManagerError.copy(statusCode)
        }

        if  let result = result as? [AnyHashable: Any], let passwordData = result[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8),
            let url = URLComponents(keychainAttributes: result)?.url,
            let username = result[kSecAttrAccount as String] as? String
        {
            return InternetCredentials(username: username, password: password, url: url)
        }

        throw KeychainManagerError.unknownResult
    }
}


private enum SecurityProtocol {
    case http
    case https

    init?(scheme: String?) {
        switch scheme?.lowercased() {
        case "http"?:
            self = .http
        case "https"?:
            self = .https
        default:
            return nil
        }
    }

    init?(secAttrProtocol: CFString) {
        if secAttrProtocol == kSecAttrProtocolHTTP {
            self = .http
        } else if secAttrProtocol == kSecAttrProtocolHTTPS {
            self = .https
        } else {
            return nil
        }
    }

    var scheme: String {
        switch self {
        case .http:
            return "http"
        case .https:
            return "https"
        }
    }

    var secAttrProtocol: CFString {
        switch self {
        case .http:
            return kSecAttrProtocolHTTP
        case .https:
            return kSecAttrProtocolHTTPS
        }
    }
}


private extension URLComponents {
    init?(keychainAttributes: [AnyHashable: Any]) {
        self.init()

        if let secAttProtocol = keychainAttributes[kSecAttrProtocol as String] {
            scheme = SecurityProtocol(secAttrProtocol: secAttProtocol as! CFString)?.scheme
        }

        host = keychainAttributes[kSecAttrServer as String] as? String

        if let port = keychainAttributes[kSecAttrPort as String] as? Int, port > 0 {
            self.port = port
        }

        if let path = keychainAttributes[kSecAttrPath as String] as? String {
            self.path = path
        }
    }

    var keychainAttributes: [String: NSObject] {
        var query: [String: NSObject] = [:]

        if let `protocol` = SecurityProtocol(scheme: scheme) {
            query[kSecAttrProtocol as String] = `protocol`.secAttrProtocol
        }

        if let host = host {
            query[kSecAttrServer as String] = host as NSObject
        }

        if let port = port {
            query[kSecAttrPort as String] = port as NSObject
        }

        if !path.isEmpty {
            query[kSecAttrPath as String] = path as NSObject
        }

        return query
    }
}

