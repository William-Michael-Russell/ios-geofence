//
//  SecureCredentials.swift
//  Locative
//
//  Created by Marcus Kida on 26/03/2016.
//  Copyright © 2016 Marcus Kida. All rights reserved.
//

import UIKit
import KeychainAccess

class SecureCredentials: NSObject {
    
    var service: String { get { return keychain.service } }
    let keychain: Keychain
    
    required init(service: String) {
        keychain = Keychain(service: "\(UIApplication.bundleIdentifier()).\(service)")
            .accessibility(.AfterFirstUnlock)
            .synchronizable(true)
        super.init()
    }
    
    subscript(key: String) -> String? {
        get {
            return keychain[key]
        }
        set {
            keychain[key] = newValue
        }
    }
}
