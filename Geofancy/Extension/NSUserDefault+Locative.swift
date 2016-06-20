//
//  NSUserDefault+Locative.swift
//  Locative
//
//  Created by Marcus Kida on 28/03/2016.
//  Copyright © 2016 Marcus Kida. All rights reserved.
//

import Foundation

extension NSUserDefaults {
    static func sharedSuite() -> NSUserDefaults? {
        return NSUserDefaults(suiteName: "group.marcuskida.Geofancy")
    }
}