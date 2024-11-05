//
//  LuaVirtualMachine.swift
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

class LuaVirtualMachine {
    
    // MARK: - Public Static Properties
    
    public static let shared: LuaVirtualMachine = {
        LuaVirtualMachine()
    }()
    
    
    // MARK: - Public Properties
    
    public private(set) var lastError: String?
    
    
    // MARK: - Private Properties
    
    private var luaVM: LuaVM
    
    
    // MARK: - Initialization
    
    private  init() {
        luaVM = LuaVM(openLibs: true)
        self.initialize()
    }
    
    
    // MARK: - Registering Custom Extensions
    
    public func registerCustomTypeImplementation<T: CustomTypeImplementation>(type: T.Type, library: Table? = nil) {
        self.luaVM.registerCustomType(type: type, library: library)
    }
    
    public func registerCustomExtensions<T: CustomExtension>(type: T.Type, library: Table? = nil) {
        do {
            try T.extension(self)
        } catch {
            fatalError("Error while registering custom extension \(T.self): \(error). Please file a bug report at https://github.com/thbonk/NavigatorApp/issues")
        }
    }
    
    
    // MARK: - Private Methods
    
    private func initialize() {
        do {
            luaVM.vm.errorHandler = self.errorHandler
            let libraryUrl = Bundle.main.url(forResource: "navigator_base_library", withExtension: "lua")!
            try self.execute(url: libraryUrl)
            
            if let configDirectoryPath = configDirectoryPath() {
                try self.execute(string: "package.path = package.path .. ';' .. '\(configDirectoryPath)' .. '/?.lua'")
            }
        } catch {
            fatalError("Error while initializing Lua VM: \(error). Please file a bug report at https://github.com/thbonk/NavigatorApp/issues")
        }
    }
    
    private func errorHandler(_ error: String) {
        self.lastError = error
    }
    
    private func configDirectoryPath() -> String? {
        do {
            let configDirectoryPathExists = FileManager.default.fileExists(url: AppDelegate.ApplicationConfigDirectory)
            
            if !configDirectoryPathExists {
                try FileManager.default.createDirectory(at: AppDelegate.ApplicationConfigDirectory, withIntermediateDirectories: true)
            } else if configDirectoryPathExists
                        && !FileManager.default.isDirectory(url: AppDelegate.ApplicationConfigDirectory) {
                
                try FileManager.default.removeItem(at: AppDelegate.ApplicationConfigDirectory)
                try FileManager.default.createDirectory(at: AppDelegate.ApplicationConfigDirectory, withIntermediateDirectories: true)
            }
            
            return AppDelegate.ApplicationConfigDirectory.path
        } catch {
            // TODO error handling
        }
        
        return nil
    }
}


// MARK: - API Routing Error

enum LuaVirtualMachineError: Error {
    
    // MARK: - Errors
    
    case error(Error, String)
    case errorMessage(String)
    

    // MARK: - Properties
    
    var localizedDescription: String {
        switch self {
        case .error(let error, let message):
            return "\(error):\n\(message)"
            
        case .errorMessage(let message):
            return message
        }
    }

}


// MARK: - VirtualMachien API Routing

extension LuaVirtualMachine {
    
    // MARK: - Properties
    
    /// The globals table
    public var globals: Table {
        return self.luaVM.globals
    }

    /// The registry table
    public var registry: Table {
        return self.luaVM.registry
    }
    
    
    // MARK: - Methods
    
    func protect(_ globalName: String) throws {
        try luaVM.execute(string: "\(globalName) = protect(\(globalName));")
    }
    
    @discardableResult
    func execute(url: URL, args: [Value] = []) throws(LuaVirtualMachineError) -> VirtualMachine.EvalResults {
        return try self.performWithErrorHandling {
            return try self.luaVM.execute(url: url, args: args)
        }
    }
    
    @discardableResult
    func execute(string: String, args: [Value] = []) throws(LuaVirtualMachineError) -> VirtualMachine.EvalResults {
        return try self.performWithErrorHandling {
            return try self.luaVM.execute(string: string, args: args)
        }
    }
    
    func createFunction(_ body: URL) throws(LuaVirtualMachineError) -> MaybeFunction {
        return try self.performWithErrorHandling {
            return self.luaVM.vm.createFunction(body)
        }
    }
    
    func createFunction(_ body: String) throws(LuaVirtualMachineError) -> MaybeFunction {
        return try self.performWithErrorHandling {
            return self.luaVM.vm.createFunction(body)
        }
    }
    
    func createTable(_ sequenceCapacity: Int = 0, keyCapacity: Int = 0) throws(LuaVirtualMachineError) -> Table {
        return try self.performWithErrorHandling {
            return self.luaVM.vm.createTable(sequenceCapacity, keyCapacity: keyCapacity)
        }
    }
    
    func createUserdataMaybe<T: CustomTypeInstance>(_ o: T?) throws (LuaVirtualMachineError)-> Userdata? {
        return try self.performWithErrorHandling {
            return self.luaVM.vm.createUserdataMaybe(o)
        }
    }
    
    func createUserdata<T: CustomTypeInstance>(_ o: T) throws(LuaVirtualMachineError) -> Userdata {
        return try self.performWithErrorHandling {
            return self.luaVM.vm.createUserdata(o)
        }
    }
    
    func eval(_ url: URL, args: [Value] = []) throws(LuaVirtualMachineError) -> VirtualMachine.EvalResults {
        return try self.performWithErrorHandling {
            return self.luaVM.vm.eval(url, args: args)
        }
    }

    func eval(_ str: String, args: [Value] = []) throws(LuaVirtualMachineError) -> VirtualMachine.EvalResults {
        return try self.performWithErrorHandling {
            return self.luaVM.vm.eval(str, args: args)
        }
    }
    
    func createFunction(_ typeCheckers: [TypeChecker] = [], fn: @escaping SwiftFunction) throws(LuaVirtualMachineError) -> Function {
        return try self.performWithErrorHandling {
            return self.luaVM.vm.createFunction(typeCheckers, fn)
        }
    }
    
    func createCustomType<T>(_ setup: (CustomType<T>) -> Void) throws(LuaVirtualMachineError) -> CustomType<T> {
        return try self.performWithErrorHandling {
            return self.luaVM.vm.createCustomType(setup)
        }
    }
    
    
    // MARK: - Private Methods
    
    private func performWithErrorHandling<R>(_ fn: () throws -> R) throws(LuaVirtualMachineError) -> R {
        self.lastError = nil
        
        do {
            let result = try fn()
            
            if let errorMessage = self.lastError {
                self.lastError = nil
                throw LuaVirtualMachineError.errorMessage(errorMessage)
            }
            
            return result
        } catch {
            let errorMessage = self.lastError!
            
            self.lastError = nil
            throw LuaVirtualMachineError.error(error, errorMessage)
        }
    }
}
