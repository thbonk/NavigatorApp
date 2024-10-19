//
//  NSEvent.ModifierFlags+description.swift
//  Navigator
//
//  Created by Thomas Bonk on 19.10.24.
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

import AppKit

extension NSEvent.ModifierFlags: @retroactive CustomStringConvertible {
    
    public var description: String {
        var symbols: [String] = []
            
        if self.contains(.command) {
            symbols.append("⌘")  // Command symbol
        }
        if self.contains(.option) {
            symbols.append("⌥")  // Option symbol
        }
        if self.contains(.control) {
            symbols.append("⌃")  // Control symbol
        }
        if self.contains(.shift) {
            symbols.append("⇧")  // Shift symbol
        }
        if self.contains(.capsLock) {
            symbols.append("⇪")  // Caps Lock symbol
        }
        if self.contains(.function) {
            symbols.append("fn")  // Function key (represented as "fn")
        }

        return symbols.joined(separator: "+")
    }
    
}
