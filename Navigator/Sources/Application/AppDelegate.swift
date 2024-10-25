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
import Magnet
import os

public let LOGGER = Logger()

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Static Properties
    
    public static let ApplicationConfigDirectory: URL = {
        let applicationConfigDirectory = FileManager.default.userHomeDirectoryPath.appendingPathComponent(".config/Navigator")
        return applicationConfigDirectory.fileUrl
    }()
    
    public static let ApplicationSettingsFile: URL = {
        let applicationSettingFile = AppDelegate.ApplicationConfigDirectory.appendingPathComponent("settings.lua")
        return applicationSettingFile
    }()
    
    public static let globalEventBus = Causality.Bus(label: "globalEventBus")
    
    
    // MARK: - Private Properties
    
    private var bringToFrontHotKey: HotKey!
    
    private var showAlertSubscription: Commands.ShowAlertSubscription!
    
    private var settingsWindowController: SettingsWindowController? = nil
    private var settingsFileObserver: Cancellable?
    

    // MARK: - NSApplicationDelegate
    
    override func awakeFromNib() {
        EventRegistry.initialize()
        
        self.showAlertSubscription = AppDelegate.globalEventBus.subscribe(Commands.ShowAlert, handler: self.showAlert)
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        /* TODO Refactor settings to use Lua as configuration lamguage
        self.initializeSettingsFile()
        self.settingsFileObserver = FileManager.default.observeFileForChanges(
            AppDelegate.ApplicationSettingsFile, handler: self.settingsFileChanged)
        self.loadSettings()*/
        
        DispatchQueue.main.async {
            self.bringToFrontHotKey = HotKey(identifier: "Bring Navigator to front",
                            keyCombo: ApplicationSettings.shared.bringToFrontDoubleTapKey,
                            target: self,
                            action: #selector(self.bringApplicationToFront))
            self.bringToFrontHotKey.register()
            
            do {
                try self.restoreWindows()
            } catch {
                if NSApp.windows.count == 0 {
                    if ApplicationSettings.shared.openWindowOnStartup {
                        self.newWindow(self)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            FileshareBrowser.shared.start(eventBus: AppDelegate.globalEventBus)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.settingsFileObserver?.cancel()
        self.storeWindows()
    }
    
    
    // MARK: - Actions
    
    @IBAction
    func newWindow(_ sender: Any) {
        let windowController = StoryboardScene.Main.navigatorWindowController.instantiate()

        windowController.showWindow(self)
    }
    
    @IBAction
    func newTab(_ sender: Any) {
        // Step 1: Get the focused window (key window)
        guard let currentWindow = NSApp.keyWindow else {
            // no focused window
            return
        }

        // Step 2: Create a new window or window controller
        let windowController = StoryboardScene.Main.navigatorWindowController.instantiate()
        guard let window = windowController.window else {
            return
        }

        // Step 3: Add the new window as a tab to the focused window
        currentWindow.addTabbedWindow(window, ordered: .above)
        window.makeKeyAndOrderFront(self)  // Optionally make the new tab active
    }
    
    @IBAction
    func showSettings(_ sender: Any) {
        /* TODO use an external text editor to open the settings
        if let settingsWindowController {
            settingsWindowController.window?.makeKeyAndOrderFront(self)
            return
        }
        
        self.settingsWindowController = StoryboardScene.Main.settingsWindowController.instantiate()
        self.settingsWindowController?.showWindow(self)
        self.settingsWindowController?.window?.makeKeyAndOrderFront(self)*/
    }
    
    @IBAction
    func bringApplicationToFront(_ sender: Any) {
        if NSApp.windows.isEmpty {
            DispatchQueue.main.async {
                self.newWindow(self)
            }
        }
        
        DispatchQueue.main.async {
            if let window = NSApp.windows.first {
                window.makeKeyAndOrderFront(self)
            }
            NSApp.activate()
        }
    }
    
    
    // MARK: - Event Handlers
    
    private func showAlert(command: ShowAlertMessage) {
        if let window = command.window {
            command.alert.beginSheetModal(for: window)
        } else {
            command.alert.runModal()
        }
    }
    
    
    // MARK: - Private Methods
    
    private func settingsFileChanged() {
        self.loadSettings()
    }
    
    private func loadSettings() {
        do {
            let code = try String(contentsOf: AppDelegate.ApplicationSettingsFile, encoding: .utf8)
            let document = try Marco.parse(code)
            
            ApplicationSettings.shared.retrieveSettings(from: document)
            Events.settingsChanged(eventBus: AppDelegate.globalEventBus)
        } catch {
            Commands.showErrorAlert(window: NSApp.keyWindow, title: "Error while loading settings", error: error)
        }
    }
    
    private func initializeSettingsFile() {
        do {
            let fileManager = FileManager.default
            
            if fileManager.fileExists(url: AppDelegate.ApplicationConfigDirectory) && fileManager.isDirectory(url: AppDelegate.ApplicationConfigDirectory) {
                if !fileManager.fileExists(url: AppDelegate.ApplicationSettingsFile) {
                    try self.copyDefaultSettingsFile()
                }
            } else {
                try fileManager.removeItem(at: AppDelegate.ApplicationConfigDirectory)
                try fileManager.createDirectory(at: AppDelegate.ApplicationConfigDirectory, withIntermediateDirectories: true)
                
                try self.copyDefaultSettingsFile()
            }
        } catch let error {
            Commands.showErrorAlert(window: NSApp.keyWindow, title: "Error while initializing settings file. Using the default settings.", error: error)
        }
    }
    
    private func copyDefaultSettingsFile() throws {
        // Copy default file
        let defaultFileUrl = Bundle.main.url(forResource: "default-settings.marco", withExtension: "")
        try FileManager.default.copyItem(
            at: defaultFileUrl!,
            to: AppDelegate.ApplicationConfigDirectory.appendingPathComponent("settings.marco"))
    }
    
    private func storeWindows() {
        var windowStates: [String: Any] = [:]
        
        for window in NSApp.windows {
            guard
                window.isVisible
            else {
                continue
            }
            
            if let windowStorer = window.windowController as? NSWindowStateRestoration,
               let identifier = windowStorer.identifier {
                var windowStorers = windowStates[identifier] as? [Data] ?? [Data]()
                
                let archiver = NSKeyedArchiver(requiringSecureCoding: true)
                
                windowStorer.encodeState(with: archiver)
                
                if let windowController = windowStorer as? NSWindowController {
                    self.storeViewStates(windowController: windowController, with: archiver)
                }
                
                
                archiver.finishEncoding()
                windowStorers.append(archiver.encodedData)
                windowStates[identifier] = windowStorers
            }
        }
        
        UserDefaults.standard.set(windowStates, forKey: "window-states")
    }
    
    private func storeViewStates(windowController: NSWindowController, with coder: NSCoder) {
        if let view = windowController.contentViewController?.view {
            self.storeViewState(view: view, with: coder)
        }
    }
    
    private func storeViewState(view: NSView, with coder: NSCoder) {
        if let viewStorer = view as? NSViewStateRestoration {
            viewStorer.encodeState(with: coder)
        }
        
        for subview in view.subviews {
            self.storeViewState(view: subview, with: coder)
        }
    }
    
    private func restoreWindows() throws {
        guard
            let windowStates = UserDefaults.standard.dictionary(forKey: "window-states"),
            windowStates.keys.count > 0
        else {
            if ApplicationSettings.shared.openWindowOnStartup {
                newWindow(self)
            }
            
            return
        }
        
        let storyboard = NSStoryboard(name: "Main", bundle: Bundle.main)
        
        for identifier in windowStates.keys {
            if let windowStorers = windowStates[identifier] as? [Data] {
                let id = NSStoryboard.SceneIdentifier(identifier)
                
                for windowStorerData in windowStorers {
                    if let windowController = storyboard.instantiateController(withIdentifier: id) as? NSWindowStateRestoration {
                        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: windowStorerData)
                        
                        windowController.decodeState(with: unarchiver)
                        
                        if let winCtrl = windowController as? NSWindowController {
                            self.restoreViewStates(windowController: winCtrl, with: unarchiver)
                        }
                        
                        (windowController as! NSWindowController).showWindow(self)
                    }
                }
            }
        }
    }
    
    private func restoreViewStates(windowController: NSWindowController, with coder: NSCoder) {
        if let view = windowController.contentViewController?.view {
            self.restoreViewState(view: view, with: coder)
        }
    }
    
    private func restoreViewState(view: NSView, with coder: NSCoder) {
        if let viewStorer = view as? NSViewStateRestoration {
            viewStorer.decodeState(with: coder)
        }
        
        for subview in view.subviews {
            restoreViewState(view: subview, with: coder)
        }
    }

}

