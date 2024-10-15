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
    
    
    // MARK: - Private Properties
    
    private var showAlertSubscription: Commands.ShowAlertSubscription!
    
    private var settingsWindowController: SettingsWindowController? = nil
    private var settingsFileObserver: Cancellable?
    

    // MARK: - NSApplicationDelegate
    
    override func awakeFromNib() {
        EventRegistry.initialize()
        
        self.showAlertSubscription = AppDelegate.globalEventBus.subscribe(Commands.ShowAlert, handler: self.showAlert)
            //.subscribe(Commands.ShowAlert, handler: self.showAlert)
        
        initializeSettingsFile()
        self.settingsFileObserver = FileManager.default.observeFileForChanges(
            AppDelegate.ApplicationSettingsFile, handler: self.settingsFileChanged)
        loadSettings()
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            do {
                try self.restoreWindows()
            } catch {
                if NSApp.windows.count == 0 {
                    self.newWindow(self)
                }
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.settingsFileObserver?.cancel()
        storeWindows()
    }
    
    
    // MARK: - Actions
    
    @IBAction
    func newWindow(_ sender: Any) {
        let windowController = StoryboardScene.Main.navigatorWindowController.instantiate()

        windowController.showWindow(self)
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
        loadSettings()
        
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
            
            if fileManager.isDirectory(url: AppDelegate.ApplicationSupportDirectory) {
                if !fileManager.fileExists(url: AppDelegate.ApplicationSettingsFile) {
                    try copyDefaultSettingsFile()
                }
            } else {
                try fileManager.removeItem(at: AppDelegate.ApplicationSupportDirectory)
                try fileManager.createDirectory(at: AppDelegate.ApplicationSupportDirectory, withIntermediateDirectories: true)
                
                try copyDefaultSettingsFile()
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
            to: AppDelegate.ApplicationSupportDirectory.appendingPathComponent("settings.marco"))
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
            storeViewState(view: subview, with: coder)
        }
    }
    
    private func restoreWindows() throws {
        guard
            let windowStates = UserDefaults.standard.dictionary(forKey: "window-states")
        else {
            newWindow(self)
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

