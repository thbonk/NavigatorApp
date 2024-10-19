//
//  ApplicationSettings.swift
//  Navigator
//
//  Created by Thomas Bonk on 04.10.24.
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

class ApplicationSettings {
    
    // MARK: - Public Structs
    
    struct ShortcutKey: CustomStringConvertible {
        
        enum ShortcutKeyType {
            case specialKey(key: NSEvent.SpecialKey)
            case character(character: String)
        }
        
        let modifiers: NSEvent.ModifierFlags
        let key: ShortcutKeyType
        
        var description: String {
            var str: [String] = []
            
            if self.modifiers != [] {
                str.append(self.modifiers.description)
            }
            
            switch key {
            case .specialKey(let key):
                str.append(key.description)
                break
                
            case .character(let character):
                str.append(character.localizedUppercase)
            }
            
            return str.joined(separator: " ")
        }
    }
    
    struct Shortcut {
        let key: ShortcutKey
        let event: String
    }
    
    
    // MARK: - Public Static Properties
    
    static var shared: ApplicationSettings = {
        .init()
    }()
    
    
    // MARK: - Public Properties
    
    public private(set) var openWindowOnStartup = true
    
    public private(set) var shortcuts: [String : Shortcut] = [
        "navigate-back":
            Shortcut(key: ShortcutKey(modifiers: [.command], key: .character(character: "b")), event: "navigate-back"),
        "navigate-to-parent":
            Shortcut(key: ShortcutKey(modifiers: [.command], key: .specialKey(key: .upArrow)), event: "navigate-to-parent"),
        "show-or-hide-hidden-files":
            Shortcut(key: ShortcutKey(modifiers: [.shift, .command], key: .character(character: "i")), event: "show-or-hide-hidden-files"),
        "reload-directory-contents":
            Shortcut(key: ShortcutKey(modifiers: [.command], key: .character(character: "r")), event: "reload-directory-contents"),
        "rename-selected-file":
            Shortcut(key: ShortcutKey(modifiers: [.option], key: .character(character: "r")), event: "rename-selected-file"),
        "move-selected-files-to-bin":
            Shortcut(key: ShortcutKey(modifiers: [ ], key: .specialKey(key: .delete)), event: "move-selected-files-to-bin"),
        "delete-selected-files":
            Shortcut(key: ShortcutKey(modifiers: [ .control ], key: .specialKey(key: .delete)), event: "delete-selected-files"),
        "delete-favorite":
            Shortcut(key: ShortcutKey(modifiers: [ .command ], key: .specialKey(key: .delete)), event: "delete-favorite"),
        "eject-volume":
            Shortcut(key: ShortcutKey(modifiers: [ .option ], key: .specialKey(key: .delete)), event: "eject-volume"),
        "paste-files":
            Shortcut(key: ShortcutKey(modifiers: [ .command ], key: .character(character: "v")), event: "paste-files"),
        "copy-files":
            Shortcut(key: ShortcutKey(modifiers: [ .command ], key: .character(character: "c")), event: "copy-files"),
        "cut-files":
            Shortcut(key: ShortcutKey(modifiers: [ .command ], key: .character(character: "x")), event: "cut-files"),
    ]
    
    
    // MARK: - Initialization
    
    private init() {
        // Empty By Design
    }
    
    
    // MARK: - Public Methods
    
    public func retrieveSettings(from document: MarcoDocument) {
        let outerObject = document.value as! MarcoObject
        
        self.openWindowOnStartup = outerObject["open_window_on_start"]?.asBool ?? true
        retrieveShortcuts(from: outerObject["shortcuts"] as! MarcoArray)
    }
    
    
    // MARK: - Private Methods
    
    private func retrieveShortcuts(from shortcuts: MarcoArray) {
        shortcuts.forEach { object in
            if let obj = object.asObject {
                if let event = obj["event"]?.asString {
                    if let shortcutKey = self.retrieveShortcutKey(from: obj) {
                        self.shortcuts[event] = Shortcut(key: shortcutKey, event: event)
                    }
                }
            }
        }
    }
    
    private func retrieveShortcutKey(from obj: MarcoObject) -> ShortcutKey? {
        if let shortcut = obj["shortcut"]?.asObject {
            var modifiers: NSEvent.ModifierFlags?
            var key: ShortcutKey.ShortcutKeyType?
            
            if let modifiersObject = shortcut["modifiers"]?.asArray {
                if let mods = retrieveKeyModifiers(from: modifiersObject) {
                    modifiers = mods
                }
            }
            
            if let keyString = shortcut["key"]?.asString {
                if let specialKey = parseSpecialKey(keyString) {
                    key = .specialKey(key: specialKey)
                } else {
                    key = .character(character: keyString)
                }
            }
            
            if let modifiers, let key {
                return ShortcutKey(modifiers: modifiers, key: key)
            }
        }
        
        return nil
    }
    
    private func retrieveKeyModifiers(from modifiersObject: MarcoArray) -> NSEvent.ModifierFlags? {
        var modifiers: NSEvent.ModifierFlags?
        
        if modifiersObject.all(predicate: { $0.asString != nil }) {
            modifiers = []
            
            modifiersObject
                .elements
                .map { $0.asString! }
                .forEach { name in
                    if let mod = parseModifier(name) {
                        modifiers?.update(with: mod)
                    }
                }
        }
        
        return modifiers
    }
    
    private func parseModifier(_ name: String) -> NSEvent.ModifierFlags? {
        let normalizedName = normalizeName(name)
        var modifier: NSEvent.ModifierFlags?
        
        switch normalizedName {
        case "capslock":
            modifier = .capsLock
            break
        case "shift":
            modifier = .shift
            break
        case "control":
            modifier = .control
            break
        case "option":
            modifier = .option
            break
        case "command":
            modifier = .command
            break
        case "numericpad":
            modifier = .numericPad
            break
        case "help":
            modifier = .help
            break
        case "function":
            modifier = .function
            break
        default:
            break
        }
        
        return modifier
    }
    
    private func parseSpecialKey(_ name: String) -> NSEvent.SpecialKey? {
        let normalizedName = normalizeName(name)
        var specialKey: NSEvent.SpecialKey?
        
        switch(normalizedName) {
        case "backspace":
            specialKey = .backspace
            break
        case "carriagereturn":
            specialKey = .carriageReturn
            break
        case "newline":
            specialKey = .newline
            break
        case "enter":
            specialKey = .enter
            break
        case "delete":
            specialKey = .delete
            break
        case "deleteforward":
            specialKey = .deleteForward
            break
        case "backtab":
            specialKey = .backTab
            break
        case "tab":
            specialKey = .tab
            break
        case "uparrow":
            specialKey = .upArrow
            break
        case "downarrow":
            specialKey = .downArrow
            break
        case "leftarrow":
            specialKey = .leftArrow
            break
        case "rightarrow":
            specialKey = .rightArrow
            break
        case "pageup":
            specialKey = .pageUp
            break
        case "pagedown":
            specialKey = .pageDown
            break
        case "home":
            specialKey = .home
            break
        case "end":
            specialKey = .end
            break
        case "prev":
            specialKey = .prev
            break
        case "next":
            specialKey = .next
            break
        case "begin":
            specialKey = .begin
            break
        case "break":
            specialKey = .break
            break
        case "cleardisplay":
            specialKey = .clearDisplay
            break
        case "clearline":
            specialKey = .clearLine
            break
        case "deletecharacter":
            specialKey = .deleteCharacter
            break
        case "deleteline":
            specialKey = .deleteLine
            break
        case "execute":
            specialKey = .execute
            break
        case "find":
            specialKey = .find
            break
        case "formfeed":
            specialKey = .formFeed
            break
        case "help":
            specialKey = .help
            break
        case "insert":
            specialKey = .insert
            break
        case "insertcharacter":
            specialKey = .insertCharacter
            break
        case "insertline":
            specialKey = .insertLine
            break
        case "lineseparator":
            specialKey = .lineSeparator
            break
        case "menu":
            specialKey = .menu
            break
        case "modeswitch":
            specialKey = .modeSwitch
            break
        case "paragraphseparator":
            specialKey = .paragraphSeparator
            break
        case "pause":
            specialKey = .pause
            break
        case "print":
            specialKey = .print
            break
        case "printscreen":
            specialKey = .printScreen
            break
        case "redo":
            specialKey = .redo
            break
        case "reset":
            specialKey = .reset
            break
        case "scrolllock":
            specialKey = .scrollLock
            break
        case "select":
            specialKey = .select
            break
        case "stop":
            specialKey = .stop
            break
        case "sysreq":
            specialKey = .sysReq
            break
        case "system":
            specialKey = .system
            break
        case "undo":
            specialKey = .undo
            break
        case "user":
            specialKey = .user
            break
        case "f1":
            specialKey = .f1
            break
        case "f2":
            specialKey = .f2
            break
        case "f3":
            specialKey = .f3
            break
        case "f4":
            specialKey = .f4
            break
        case "f5":
            specialKey = .f5
            break
        case "f6":
            specialKey = .f6
            break
        case "f7":
            specialKey = .f7
            break
        case "f8":
            specialKey = .f8
            break
        case "f9":
            specialKey = .f9
            break
        case "f10":
            specialKey = .f10
            break
        case "f11":
            specialKey = .f11
            break
        case "f12":
            specialKey = .f12
            break
        case "f13":
            specialKey = .f13
            break
        case "f14":
            specialKey = .f14
            break
        case "f15":
            specialKey = .f15
            break
        case "f16":
            specialKey = .f16
            break
        case "f17":
            specialKey = .f17
            break
        case "f18":
            specialKey = .f18
            break
        case "f19":
            specialKey = .f19
            break
        case "f20":
            specialKey = .f20
            break
        case "f21":
            specialKey = .f21
            break
        case "f22":
            specialKey = .f22
            break
        case "f23":
            specialKey = .f23
            break
        case "f24":
            specialKey = .f24
            break
        case "f25":
            specialKey = .f25
            break
        case "f26":
            specialKey = .f26
            break
        case "f27":
            specialKey = .f27
            break
        case "f28":
            specialKey = .f28
            break
        case "f29":
            specialKey = .f29
            break
        case "f30":
            specialKey = .f30
            break
        case "f31":
            specialKey = .f31
            break
        case "f32":
            specialKey = .f32
            break
        case "f33":
            specialKey = .f33
            break
        case "f34":
            specialKey = .f34
            break
        case "f35":
            specialKey = .f35
            break
        default:
            break
        }
        
        return specialKey
    }
    
    private func normalizeName(_ name: String) -> String {
        var normalized = name.lowercased()
        
        normalized.removeFirst()
        return normalized
    }
}

extension ApplicationSettings.ShortcutKey.ShortcutKeyType: Equatable {
    static func == (lhs: ApplicationSettings.ShortcutKey.ShortcutKeyType, rhs: ApplicationSettings.ShortcutKey.ShortcutKeyType) -> Bool {
        switch (lhs, rhs) {
        case (.specialKey(let key1), .specialKey(let key2)):
            return key1 == key2
        case (.character(let char1), .character(let char2)):
            return char1.lowercased() == char2.lowercased()
        default:
            return false
        }
    }
}


/// How to handle a key event:
/*
 // Option 1: Override keyDown to detect specific keys
     override func keyDown(with event: NSEvent) {
         // Check if it's the hotkey (e.g., Command + Shift + A)
         if event.modifierFlags.contains([.command, .shift]) && event.characters == "A" {
             handleHotkey()
         } else {
             super.keyDown(with: event)
         }
     }
 */
