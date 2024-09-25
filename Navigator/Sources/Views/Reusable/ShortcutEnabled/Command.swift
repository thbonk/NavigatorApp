//
//  Command.swift
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

public struct Command: Hashable, Identifiable {
    
    // MARK: - Public Properties
    
    let shortcut: Shortcut?
    let title: LocalizedStringKey
    let icon: NSImage?
    let action: () -> Void
    
    var titleWithShortcut: String {
        guard
            let shortcut
        else {
            return self.title.localizedString
        }
        
        var title = self.title.localizedString
        
        title += " ("
        if !shortcut.modifiers.isEmpty {
            title += shortcut.modifiers.description + " "
        }
        title += shortcut.key.description
        title += ")"
        
        return title
    }
    
    
    // MARK: - Initialization
    
    public init(_ shortcut: Shortcut? = nil,
                title: LocalizedStringKey,
                icon: NSImage? = nil,
                action: @escaping () -> Void) {
        
        self.shortcut = shortcut
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.title.stringKey)
    }
    
    public static func == (lhs: Command, rhs: Command) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    
    // MARK: - Identifiable
    
    public var id: Int {
        return self.title.stringKey.hashValue
    }
}
