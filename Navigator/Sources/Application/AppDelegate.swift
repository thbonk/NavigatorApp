//
//  AppDelegate.swift
//  Navigator
//
//  Created by Thomas Bonk on 29.09.24.
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
import Causality
import Combine
import os

public let LOGGER = Logger()

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Static Properties
    
    public static let ApplicationSupportDirectory: URL = {
        let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return applicationSupportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier!)
    }()
    
    public static let ApplicationSettingsFile: URL = {
        let applicationSettingFile = AppDelegate.ApplicationSupportDirectory.appendingPathComponent("settings.marco")
        return applicationSettingFile
    }()
    
    public static let globalEventBus = Causality.Bus(label: "globalEventBus")
    
    
    // MARK: - Public Properties
    
    public private(set) var windowControllers: Set<NavigatorWindowController> = Set()
    
    
    // MARK: - Private Properties
    
    private var settingsWindowController: SettingsWindowController? = nil
    private var settingsFileObserver: Cancellable?
    

    // MARK: - NSApplicationDelegate
    
    override func awakeFromNib() {
        EventRegistry.initialize()
        
        initializeSettingsFile()
        self.settingsFileObserver = FileManager.default.observeFileForChanges(
            AppDelegate.ApplicationSettingsFile, handler: self.settingsFileChanged)
        // TODO error handling
        try? loadSettings()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        for window in NSApp.windows {
            if let windowController = window.windowController as? NavigatorWindowController {
                windowControllers.insert(windowController)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.settingsFileObserver?.cancel()
    }
    
    
    // MARK: - Actions
    
    @IBAction
    func newWindow(_ sender: Any) {
        let windowController = StoryboardScene.Main.navigatorWindowController.instantiate()
        
        windowController.showWindow(self)
        self.windowControllers.insert(windowController)
    }
    
    @IBAction
    func showSettings(_ sender: Any) {
        if let settingsWindowController {
            settingsWindowController.window?.makeKeyAndOrderFront(self)
            return
        }
        
        self.settingsWindowController = StoryboardScene.Main.settingsWindowController.instantiate()
        self.settingsWindowController?.showWindow(self)
        self.settingsWindowController?.window?.makeKeyAndOrderFront(self)
    }
    
    
    // MARK: - Private Methods
    
    private func settingsFileChanged() {
        // TODO error handling
        try? loadSettings()
        
    }
    
    private func loadSettings() throws {
        let code = try String(contentsOf: AppDelegate.ApplicationSettingsFile, encoding: .utf8)
        
        do {
            let document = try Marco.parse(code)
            
            ApplicationSettings.shared.retrieveSettings(from: document)
            Events.settingsChanged(eventBus: AppDelegate.globalEventBus)
        } catch {
            // TODO error handling
            let err = error as! MarcoParsingError
            print("\(err.message) (\(err.range.lowerBound)")
        }
    }
    
    private func initializeSettingsFile() {
        let fileManager = FileManager.default
        
        if fileManager.isDirectory(url: AppDelegate.ApplicationSupportDirectory) {
            if !fileManager.fileExists(url: AppDelegate.ApplicationSettingsFile) {
                try? copyDefaultSettingsFile()
            }
        } else {
            try? fileManager.removeItem(at: AppDelegate.ApplicationSupportDirectory)
            try? fileManager.createDirectory(at: AppDelegate.ApplicationSupportDirectory, withIntermediateDirectories: true)
            
            try? copyDefaultSettingsFile()
        }
    }
    
    private func copyDefaultSettingsFile() throws {
        // Copy default file
        let defaultFileUrl = Bundle.main.url(forResource: "default-settings.marco", withExtension: "")
        try FileManager.default.copyItem(
            at: defaultFileUrl!,
            to: AppDelegate.ApplicationSupportDirectory.appendingPathComponent("settings.marco"))
    }

}

