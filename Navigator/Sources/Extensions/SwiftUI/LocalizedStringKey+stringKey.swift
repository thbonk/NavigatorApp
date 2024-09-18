//
//  LocalizedStringKey+stringKey.swift
//  Navigator
//
//  Created by Thomas Bonk on 14.09.24.
//  Copyright 2024 Thomas Bonk
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI

extension LocalizedStringKey {

    // This will mirror the `LocalizedStringKey` so it can access its
    // internal `key` property. Mirroring is rather expensive, but it
    // should be fine performance-wise, unless you are
    // using it too much or doing something out of the norm.
    var stringKey: String {
        Mirror(reflecting: self).children.first(where: { $0.label == "key" })?.value as! String
    }
    
    var localizedString: String {
        let language = Locale.current.language.languageCode?.identifier
        
        if let path = Bundle.main.path(forResource: language, ofType: "lproj") {
            let bundle = Bundle(path: path)!
            let localizedString = NSLocalizedString(stringKey, bundle: bundle, comment: "")
            
            return localizedString
        }
        
        return stringKey
    }
    
}
