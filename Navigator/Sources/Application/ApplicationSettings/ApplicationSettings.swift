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
import Magnet
import SwiftyLua

class ApplicationSettings: CustomTypeImplementation {
    
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
        let lua = VirtualMachine.shared
        return ApplicationSettings()
    }()
    
    
    // MARK: - Public Properties
    
    public fileprivate(set) var openWindowOnStartup = true
    public fileprivate(set) var bringToFrontDoubleTapKey: KeyCombo = KeyCombo(doubledCocoaModifiers: .command)!
    public fileprivate(set) var editor = URL(fileURLWithPath: "/System/Applications/TextEdit.app")
    
    public private(set) var shortcuts: [String : Shortcut] = [
        "navigate-back":
            Shortcut(key: ShortcutKey(modifiers: [.command], key: .character(character: "b")), event: "navigate-back"),
        "navigate-to-parent":
            Shortcut(key: ShortcutKey(modifiers: [.command], key: .specialKey(key: .upArrow)), event: "navigate-to-parent"),
        "show-file-infos":
            Shortcut(key: ShortcutKey(modifiers: [.command], key: .character(character: "i")), event: "show-file-infos"),
        "show-action-bar":
            Shortcut(key: ShortcutKey(modifiers: [.shift, .command], key: .character(character: "p")), event: "show-action-bar"),
        "show-or-hide-hidden-files":
            Shortcut(key: ShortcutKey(modifiers: [.shift, .command], key: .character(character: "h")), event: "show-or-hide-hidden-files"),
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
    
    
    // MARK: - CustomTypeImplementation
    
    static func descriptor(_ vm: SwiftyLua.LuaVM) -> SwiftyLua.CustomTypeDescriptor {
        return CustomTypeDescriptor(
          constructor: ConstructorDescriptor { (args: Arguments) -> SwiftReturnValue in
              return .value(vm.toReference(ApplicationSettings.shared))
          },
          functions: [],
          methods: [
            MethodDescriptor("setOpenWindowOnStart", parameters: [Bool.arg], fn: setOpenWindowOnStart),
            MethodDescriptor("getOpenWindowOnStart", fn: getOpenWindowOnStart),
            MethodDescriptor("setBringToFrontDoubleTapKey", parameters: [Int.arg], fn: setBringToFrontDoubleTapKey),
            MethodDescriptor("getBringToFrontDoubleTapKey", fn: getBringToFrontDoubleTapKey),
            MethodDescriptor("setEditor", parameters: [String.arg], fn: setEditor),
            MethodDescriptor("getEditor", fn: getEditor),
            MethodDescriptor("setShortcutForEvent", parameters: [String.arg, Table.arg], fn: setShortcutForEvent),
            MethodDescriptor("getShortcutForEvent", fn: getShortcutForEvent),
          ]
        )
        
        func setOpenWindowOnStart(instance: CustomTypeImplementation, args: Arguments) -> SwiftReturnValue {
            let settings = instance as! ApplicationSettings
            settings.openWindowOnStartup = args.boolean
            
            return .nothing
        }
        
        func getOpenWindowOnStart(instance: CustomTypeImplementation, args: Arguments) -> SwiftReturnValue {
            let settings = instance as! ApplicationSettings
            return .value(settings.openWindowOnStartup)
        }
        
        func setBringToFrontDoubleTapKey(instance: CustomTypeImplementation, args: Arguments) -> SwiftReturnValue {
            let settings = instance as! ApplicationSettings
            settings.bringToFrontDoubleTapKey = KeyCombo(doubledCocoaModifiers: NSEvent.ModifierFlags(rawValue: UInt(args.number.toInteger())))!
            
            return .nothing
        }
        
        func getBringToFrontDoubleTapKey(instance: CustomTypeImplementation, args: Arguments) -> SwiftReturnValue {
            let settings = instance as! ApplicationSettings
            return .value(Int64(settings.bringToFrontDoubleTapKey.keyEquivalentModifierMask.rawValue))
        }
        
        func setEditor(instance: CustomTypeImplementation, args: Arguments) -> SwiftReturnValue {
            let settings = instance as! ApplicationSettings
            let editorPath = args.string
            settings.editor = URL(fileURLWithPath: editorPath)
            
            return .nothing
        }
        
        func getEditor(instance: CustomTypeImplementation, args: Arguments) -> SwiftReturnValue {
            let settings = instance as! ApplicationSettings
            return .value(settings.editor.path)
        }
        
        func setShortcutForEvent(instance: CustomTypeImplementation, args: Arguments) -> SwiftReturnValue {
            let settings = instance as! ApplicationSettings
            
            /*
             args:
             - eventName: String
             - shortcut: {
                modifiers: [Int]
                key or specialKey
             }
             */
            
            let eventName = args.string
            let shortcut = args.table
            
            guard
                let modifiersValue = shortcut["modifiers"] as? Table
            else {
                return .error("Invalid arguments: 'modifiers' is required as a table")
            }
            
            let keyValue = shortcut["key"] as? String
            let specialKeyValue = (shortcut["specialKey"] as? Number)?.toInteger()
            
            guard
                   (keyValue != nil && specialKeyValue == nil)
                || (keyValue == nil && specialKeyValue != nil)
            else {
                return .error("Invalid arguments: either 'key' or 'specialKey' is required")
            }
            
            let modifierFlags = (modifiersValue.asSequence() as [Number])
                .map { rawValue in
                    NSEvent.ModifierFlags(rawValue: UInt(rawValue.toInteger()))
                }
                .reduce(NSEvent.ModifierFlags()) { partialResult, flag in
                    partialResult.union(flag)
                }
            let key: ShortcutKey.ShortcutKeyType =
                keyValue != nil
                    ? .character(character: keyValue!)
                    : .specialKey(key: NSEvent.SpecialKey(rawValue: Int(specialKeyValue!)))
            
            settings.shortcuts[eventName] = Shortcut(key: ShortcutKey(modifiers: modifierFlags, key: key), event: eventName)
            
            return .nothing
        }
        
        func getShortcutForEvent(instance: CustomTypeImplementation, args: Arguments) -> SwiftReturnValue {
            let settings = instance as! ApplicationSettings
            let eventName = args.string
            let shortcut = settings.shortcuts[eventName]
            let modifiers = NSEvent.ModifierFlags
                .allCases
                .filter { shortcut!.key.modifiers.contains($0) }
                .map { $0.rawValue }
            let result = VirtualMachine.shared.luaVM.vm.createTable()

            result["modifiers"] = modifiers as! any Value
            if case let .character(character) = shortcut!.key.key {
                result["key"] = character
            }
            if case let .specialKey(specialKey) = shortcut!.key.key {
                result["specialKey"] = specialKey.rawValue
            }
            
            return .value(result)
        }
    }
    
    
    // MARK: - Initialization
    
    private init() {
        do {
            try initializeConstants()
            try initializeApplicationSettingsObject()
        } catch {
            fatalError("Error while initializing application settings for the Lua VM: \(error). Please file a bug report at https://github.com/thbonk/NavigatorApp/issues")
        }
        
        func initializeApplicationSettingsObject() throws {
            VirtualMachine.shared.luaVM.registerCustomType(type: ApplicationSettings.self)
        }
        
        func initializeConstants() throws {
            // SpecialKey
            let specialKey = VirtualMachine.shared.luaVM.vm.createTable()
            NSEvent.SpecialKey.allCases.forEach { key in
                specialKey[NSEvent.SpecialKey.name(key)!] = key.rawValue
            }
            VirtualMachine.shared.luaVM.vm.globals["SpecialKey"] = specialKey
            
            
            // ModifierFlags
            let modifierFlags = VirtualMachine.shared.luaVM.vm.createTable()
            NSEvent.ModifierFlags.allCases.forEach { flag in
                modifierFlags[NSEvent.ModifierFlags.name(flag)!] = Int64(flag.rawValue)
            }
            VirtualMachine.shared.luaVM.vm.globals["ModifierFlags"] = modifierFlags
            
            
            // Events
            let events = VirtualMachine.shared.luaVM.vm.createTable()
            self.shortcuts.keys.sorted().forEach { eventName in
                events[eventName.camelcased()] = eventName
            }
            VirtualMachine.shared.luaVM.vm.globals["Events"] = events
            
            
            // Protect the constants
            try VirtualMachine.shared.luaVM.execute(string: """
                SpecialKey = protect(SpecialKey);
                ModifierFlags = protect(ModifierFlags);
                Events = protect(Events);
            """)
        }
    }
    
    public class func initializeSettingsFile() throws {
        let exists = FileManager.default.fileExists(url: AppDelegate.ApplicationConfigDirectory)
        
        if !exists {
            try FileManager.default.createDirectory(at: AppDelegate.ApplicationConfigDirectory, withIntermediateDirectories: true)
        } else if exists && !FileManager.default.isDirectory(url: AppDelegate.ApplicationConfigDirectory) {
            try FileManager.default.removeItem(at: AppDelegate.ApplicationConfigDirectory)
            try FileManager.default.createDirectory(at: AppDelegate.ApplicationConfigDirectory, withIntermediateDirectories: true)
        }
        
        if !FileManager.default.fileExists(url: AppDelegate.ApplicationSettingsFile) {
            let defaultSettingsFile = Bundle.main.url(forResource: "default-settings", withExtension: "lua")!
            try FileManager.default.copyItem(at: defaultSettingsFile, to: AppDelegate.ApplicationSettingsFile)
        }
    }
    
        
    // MARK: - Public Methods
    
    public func loadSettings() throws {
        try VirtualMachine.shared.luaVM.execute(url: AppDelegate.ApplicationSettingsFile)
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
