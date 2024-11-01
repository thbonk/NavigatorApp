//
//  VirtualMachine.swift
//  Navigator
//
//  Created by Thomas Bonk on 26.10.24.
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
import SwiftyLua

class VirtualMachine {
    
    // MARK: - Public Static Properties
    
    public static let shared: VirtualMachine = {
        VirtualMachine()
    }()
    
    
    // MARK: - Public Properties
    
    public private(set) var luaVM: LuaVM
    
    
    // MARK: - Initialization
    
    private  init() {
        luaVM = LuaVM(openLibs: true)
        self.initialize()
    }
    
    
    // MARK: - Private Methods
    
    private func initialize() {
        do {
            let libraryUrl = Bundle.main.url(forResource: "navigator_base_library", withExtension: "lua")!
            try self.luaVM.execute(url: libraryUrl)
        } catch {
            fatalError("Error while initializing Lua VM: \(error). Please file a bug report at https://github.com/thbonk/NavigatorApp/issues")
        }
    }
    
}
