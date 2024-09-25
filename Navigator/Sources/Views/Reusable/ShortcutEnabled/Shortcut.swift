//
//  Shortcut.swift
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

public struct Shortcut: Hashable, Identifiable {
    
    // MARK: - Public Properties
    
    public private(set) var key: KeyEquivalent
    public private(set) var modifiers: EventModifiers
    
    public var id: Int {
        return self.hashValue
    }
    
    public var description: String {
        return "\(self.modifiers.description) \(self.key.description)"
    }
    
    
    // MARK: - Initialization
    
    public init(_ key: KeyEquivalent, modifiers: EventModifiers = [], title: LocalizedStringKey? = nil) {
        self.key = key
        self.modifiers = modifiers
    }
    
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(modifiers.rawValue)
    }
}
