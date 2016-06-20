//
//  NSString+EmptyString.swift
//  Locative
//
//  Created by Marcus Kida on 27/03/2016.
//  Copyright © 2016 Marcus Kida. All rights reserved.
//

import Foundation

extension NSString {
    @objc(lct_isNotEmpty) func isNotEmpty () -> Bool {
        if self.length > 0 {
            return true
        }
        return false
    }
}