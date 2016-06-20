//
//  NSString+Paths.swift
//  Locative
//
//  Created by Marcus Kida on 28/03/2016.
//  Copyright © 2016 Marcus Kida. All rights reserved.
//

import Foundation

extension NSString {
    class func documentsDirectory() -> String? {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first
    }
    
    class func oldSettingsPath() -> String? {
        return documentsDirectory()?.stringByAppendingString("/settings.plist")
    }
    
    class func settingsPath() -> String? {
        return documentsDirectory()?.stringByAppendingString("/.settings.plist")
    }
}