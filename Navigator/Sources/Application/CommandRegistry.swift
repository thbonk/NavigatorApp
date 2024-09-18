//
//  CommandRegistry.swift
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

import Foundation

class CommandRegistry: ObservableObject, Equatable {
    
    // MARK: - Public Properties
    
    @Published
    public private(set) var commands: Set<Command> = Set()
    
    
    // MARK: - Public Methods
    
    func add(command: Command) {
        self.commands.insert(command)
    }
    
    func add(contentsOf cmds: [Command]) {
        cmds.forEach { self.commands.insert($0) }
    }
    
    func remove(command: Command) {
        self.commands.remove(command)
    }
    
    
    // MARK: - Equatable
    
    static func == (lhs: CommandRegistry, rhs: CommandRegistry) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
