//
//  BundleIdentifier.swift
//  Locative
//
//  Created by Marcus Kida on 26/03/2016.
//  Copyright © 2016 Marcus Kida. All rights reserved.
//

import UIKit

extension UIApplication {
    static func bundleIdentifier() -> String {
        guard let infoDict = NSBundle.mainBundle().infoDictionary else {
            return "com.unknown"
        }
        return infoDict["CFBundleIdentifier"] as! String
    }
}
