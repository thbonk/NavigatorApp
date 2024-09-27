//
//  CommandPanel+ViewModifier.swift
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

import FloatingFilter
import SwiftUI

struct CommandPanel: ViewModifier {
    
    // MARK: - Private Properties
    
    private let shortcut: Shortcut
    private let commands: [Command]
    
    @EnvironmentObject
    private var commandRegistry: CommandRegistry
    
    
    // MARK: - Initialization
    
    init(_ shortcut: Shortcut, commands: [Command]) {
        self.shortcut = shortcut
        self.commands = commands
    }
    
    
    // MARK: - Public Methods
    
    func body(content: Content) -> some View {
        ZStack {
            KeyboardShortcut(
                title: "Show Command Panel",
                key: shortcut.key,
                modifiers: shortcut.modifiers,
                action: self.showCommandPanel)
            
            ForEach(mergedCommands()) { command in
                if let shortcut = command.shortcut {
                    KeyboardShortcut(
                        title: command.title,
                        key: shortcut.key,
                        modifiers: shortcut.modifiers,
                        action: command.action)
                }
            }
            
            content
        }
    }
    
    
    // MARK: - Private Methods
    
    private func showCommandPanel() {
        FloatingFilterModule.showFilterWindow(items: items()) { selectedItems in
            selectedItems.forEach { item in
                (item.identifier as! Command).action()
            }
        }
    }
    
    private func mergedCommands() -> [Command] {
        var commands = [Command]()
        
        commands.append(contentsOf: self.commands)
        commands.append(contentsOf: Array(commandRegistry.commands) as [Command])
        
        return commands
    }
    
    private func items() -> [Item] {
        var items: [Item] = []
        
        items.append(contentsOf: self.commands.map { command in
            Item(identifier: command, title: command.titleWithShortcut, icon: command.icon)
        })
        
        items.append(contentsOf: (Array(commandRegistry.commands) as [Command]).map { command in
            Item(identifier: command, title: command.titleWithShortcut, icon: command.icon)
        })
        
        return items.sorted { i1, i2 in
            i1.title < i2.title
        }
    }
}

extension ShortcutEnabled {
    
    func commandPanel(_ shortcut: Shortcut, commands: [Command] = []) -> some View {
        modifier(CommandPanel(shortcut, commands: commands))
    }
    
}
