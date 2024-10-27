//
//  String+camelCased.swift
//  Navigator
//
//  Created by Thomas Bonk on 26.10.24.
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

import Foundation

extension String {
    
    public func camelcased() -> String {
        // Split the string by spaces or hyphens
        let words = self.split { $0 == " " || $0 == "-" }
        
        // Capitalize each word except the first one
        let camelCaseString = words.enumerated().map { index, word in
            index == 0 ? word.lowercased() : word.capitalized
        }.joined()
        
        return camelCaseString
    }
}
