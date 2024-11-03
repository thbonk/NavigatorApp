//
//  NSApplication+CustomExtension.swift
//  Navigator
//
//  Created by Thomas Bonk on 02.11.24.
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
import SwiftyLua

extension NSApplication: CustomExtension {
    
    // MARK: - CustomExtension
    
    static func `extension`(_ vm: LuaVirtualMachine) throws {
        let application = try! vm.createTable()
        vm.globals["Application"] = application
        
        application["keyWindow"] = try! vm.createFunction(fn: NSApplication.keyWindow)
        application["windows"] = try! vm.createFunction(fn: NSApplication.windows)
        application["window"] = try! vm.createFunction([Int.arg], fn: NSApplication.window)
        
        try! vm.protect("Application")
    }
    
    
    // MARK: - Functions
    
    private static func keyWindow(args: Arguments) -> SwiftReturnValue {
        guard
            let keyWindow = NSApp.keyWindow,
            keyWindow.isVisible
        else {
            return .value(nil)
        }
        
        return object(for: keyWindow)
    }
    
    private static func windows(args: Arguments) -> SwiftReturnValue {
        return .value(NSApp.windows.filter { $0.isVisible }.count)
    }
    
    private static func window(args: Arguments) -> SwiftReturnValue {
        let index = Int(args.number.toInteger())
        let windows = NSApp.windows
        
        guard
            index >= 0 && index < windows.count && windows[index].isVisible
        else {
            return .value(nil)
        }
        
        return object(for: windows[index])
    }
    
    private static func object(for window: NSWindow) -> SwiftReturnValue {
        let obj = try! LuaVirtualMachine.shared.createTable()
        
        obj["title"] = try! LuaVirtualMachine.shared.createFunction { args in .value(window.title) }
        obj["selectedFile"] = try! LuaVirtualMachine.shared.createFunction { args in
            let files = try! LuaVirtualMachine.shared.createTable()
            
            if let directoryViewController = window
                .contentViewController?
                .children
                .first(where: { controller in controller is DirectoryViewController })
                .map({ $0 as! DirectoryViewController }) {
                
                for i in 0..<directoryViewController.selectedFiles.count {
                    obj[i] = directoryViewController.selectedFiles[i]
                }
            }
            
            return .value(files)
        }
        
        return .value(obj)
    }
}
