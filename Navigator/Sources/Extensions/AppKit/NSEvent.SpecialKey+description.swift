//
//  NSEvent.SpecialKey+description.swift
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

extension NSEvent.SpecialKey: @retroactive CaseIterable, @retroactive CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .upArrow:
            return "↑"  // Unicode arrow symbol
        case .downArrow:
            return "↓"
        case .leftArrow:
            return "←"
        case .rightArrow:
            return "→"
        case .carriageReturn, .enter:
                return "⏎"  // Unicode return symbol
        case .delete:
            return "⌫"  // Unicode backspace/delete symbol
        case .tab:
            return "⇥"  // Unicode tab symbol (right tab)
        case .backspace:
            return "⌫"  // Backspace (same as delete)
        case .home:
            return "⇱"  // Unicode home symbol
        case .end:
            return "⇲"  // Unicode end symbol
        case .pageUp:
            return "⇞"  // Unicode page up symbol
        case .pageDown:
            return "⇟"  // Unicode page down symbol
        case .help:
            return "❓"  // Help (can also use ⍰ or a question mark)
        case .f1:
            return "F1"  // Function key (F1)
        case .f2:
            return "F2"
        case .f3:
            return "F3"
        case .f4:
            return "F4"
        case .f5:
            return "F5"
        case .f6:
            return "F6"
        case .f7:
            return "F7"
        case .f8:
            return "F8"
        case .f9:
            return "F9"
        case .f10:
            return "F10"
        case .f11:
            return "F11"
        case .f12:
            return "F12"
        case .f13:
            return "F13"
        case .f14:
            return "F14"
        case .f15:
            return "F15"
        case .f16:
            return "F16"
        case .f17:
            return "F17"
        case .f18:
            return "F18"
        case .f19:
            return "F19"
        case .f20:
            return "F20"
        default:
            return self.unicodeScalar.description  // Default for unknown special keys
        }
    }
    
    
    // MARK: - CaseIterable
    
    public static var allCases: [NSEvent.SpecialKey] {
        return [
            .upArrow, .downArrow, .leftArrow, .rightArrow, .carriageReturn, .enter, .delete,
            .tab, .backspace, .home, .end, .pageUp,.pageDown, .help, .f1, .f2, .f3, .f4, .f5,
            .f6, .f7, .f8, .f9, .f10, .f11, .f12, .f13, .f14, .f15, .f16, .f17, .f18, .f19, .f20
        ]
    }
    
    
    // MARK: - Public Static Methods
    
    public static func name(_ specialKey: NSEvent.SpecialKey) -> String? {
        switch specialKey {
        case .upArrow:
            return "upArrow"  // Unicode arrow symbol
        case .downArrow:
            return "downArrow"
        case .leftArrow:
            return "leftArrow"
        case .rightArrow:
            return "rightArrow"
        case .carriageReturn:
            return "carriageReturn"
        case .enter:
            return "enter"
        case .delete:
            return "delete"
        case .tab:
            return "tab"
        case .backspace:
            return "backspace"
        case .home:
            return "home"
        case .end:
            return "end"
        case .pageUp:
            return "pageUp"
        case .pageDown:
            return "pageDown"
        case .help:
            return "help"
        case .f1:
            return "F1"
        case .f2:
            return "F2"
        case .f3:
            return "F3"
        case .f4:
            return "F4"
        case .f5:
            return "F5"
        case .f6:
            return "F6"
        case .f7:
            return "F7"
        case .f8:
            return "F8"
        case .f9:
            return "F9"
        case .f10:
            return "F10"
        case .f11:
            return "F11"
        case .f12:
            return "F12"
        case .f13:
            return "F13"
        case .f14:
            return "F14"
        case .f15:
            return "F15"
        case .f16:
            return "F16"
        case .f17:
            return "F17"
        case .f18:
            return "F18"
        case .f19:
            return "F19"
        case .f20:
            return "F20"
        default:
            return nil
        }
    }
}
