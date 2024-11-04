//
//  LuaCommandRegistry.swift
//  Navigator
//
//  Created by Thomas Bonk on 03.11.24.
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

import Causality
import Foundation
import SwiftyLua

class LuaCommandRegistry: CustomExtension {
    
    // MARK: - Public Structs
    
    struct LuaCommand: CommandExecutor {
        
        // MARK: - Public Properties
        
        let description: String
        let function: Function
        
        
        // MARK: - CommandExecutor
        
        var name: String {
            self.description
        }
        
        func execute(eventBus: Causality.Bus) {
            DispatchQueue.main.async {
                _ = function.call([])
            }
        }
        
    }
    
    // MARK: - Public Static Properties
    
    public static var shared: LuaCommandRegistry = {
        LuaCommandRegistry()
    }()
    
    
    // MARK: - Public Properties
    
    public private(set) var commands = [LuaCommand]()
    
    
    // MARK: - CustomExtension
    
    static func `extension`(_ vm: LuaVirtualMachine) throws {
        let cmdReg = try LuaVirtualMachine.shared.createTable()
        LuaVirtualMachine.shared.globals["CommandRegistry"] = cmdReg
        
        cmdReg["registerCommand"] = try LuaVirtualMachine.shared.createFunction([Table.arg], fn: registerCommand)
        cmdReg["commands"] = try LuaVirtualMachine.shared.createFunction(fn: commands)
        
        try LuaVirtualMachine.shared.protect("CommandRegistry")
        
        func registerCommand(args: Arguments) -> SwiftReturnValue {
            let command = args.table
            
            guard
                let description = command["description"] as? String
            else {
                return .error("No description is given.")
            }
            
            guard
                let function = command["func"] as? Function
            else {
                return .error("No function given.")
            }
            
            LuaCommandRegistry.shared.commands.append(LuaCommand(description: description, function: function))
            
            return .nothing
        }
        
        func commands(args: Arguments) -> SwiftReturnValue {
            let result = try! LuaVirtualMachine.shared.createTable()
            
            let cmds = LuaCommandRegistry.shared
                .commands
                .map {
                    let cmd = try! LuaVirtualMachine.shared.createTable()
                    
                    cmd["description"] = $0.description
                    cmd["func"] = $0.function
                    
                    return cmd
                }
                
            for i in 0..<cmds.count {
                result[i] = cmds[i]
            }
            
            return .value(result)
        }
    }
    
}
