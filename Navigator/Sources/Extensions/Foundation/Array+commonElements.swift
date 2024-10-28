//
//  Array+commonElements.swift
//  Navigator
//
//  Created by Thomas Bonk on 27.10.24.
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

extension Array {
    public static func commonElements<T: Hashable>(in arrays: [[T]]) -> [T] {
        guard
            let firstArray = arrays.first
        else {
            return []
        }

        // Start with the first array converted to a Set
        var commonSet = Set(firstArray)

        // Intersect with each subsequent array
        for array in arrays.dropFirst() {
            commonSet.formIntersection(array)
        }
        
        // Convert back to array
        return commonSet.map { $0 }
    }
}
