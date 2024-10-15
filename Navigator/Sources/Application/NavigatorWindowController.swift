//
//  NavigatorWindowController.swift
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

@objc class NavigatorWindowController: NSWindowController, NSWindowDelegate, NSWindowStateRestoration {
    
    // MARK: - Public Properties
    
    @objc public dynamic var identifier: String?
    
    public private(set) var path = NavigatorWindowController.initalPath {
        willSet {
            if navigatingBack {
                navigatingBack = false
                return
            }
            
            let comparison = newValue.compare(NavigatorWindowController.initalPath, options: .caseInsensitive)
            let storeInHistory = comparison != .orderedSame
            
            if storeInHistory {
                self.history.push(path)
            }
        }
        didSet {
            DispatchQueue.main.async {
                Events.pathChanged(eventBus: self.eventBus, self.path)
            }
        }
    }
    public let eventBus = Causality.Bus(label: "EventBus-\(UUID().uuidString)")
    
    
    // MARK: - Private Static Properties
    
    private static let initalPath = FileManager.default.userHomeDirectoryPath
    
    
    // MARK: - Private Properties
    
    private var actionBar: ActionBar!
    private var history = Stack<String>()
    private var navigatingBack = false
    
    private var changePathSubscription: Commands.ChangePathSubscription?
    private var navigateBackSubscription: Commands.NavigateBackSubscription?
    private var pathChangedSubscription: Events.PathChangedSubscription?
    private var showActionBarSubscription: Commands.ShowActionBarSubscription?
    
    
    // MARK: - NSWindowController/NSWindowDelegate
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.delegate = self
        
        self.actionBar = ActionBar.create(with: self.eventBus)
        
        self.changePathSubscription = self.eventBus.subscribe(Commands.ChangePath, handler: self.changePath)
        self.navigateBackSubscription = self.eventBus.subscribe(Commands.NavigateBack, handler: self.navigateBack)
        self.pathChangedSubscription = self.eventBus.subscribe(Events.PathChanged, handler: self.pathChanged)
        self.showActionBarSubscription = self.eventBus.subscribe(Commands.ShowActionBar, handler: self.showActionBar)
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        Events.pathChanged(eventBus: eventBus, self.path)
    }
    
    func windowWillClose(_ notification: Notification) {
        self.changePathSubscription?.unsubscribe()
        self.navigateBackSubscription?.unsubscribe()
        self.pathChangedSubscription?.unsubscribe()
        self.showActionBarSubscription?.unsubscribe()
        
        NSApp.windows.first { $0 == self.window }.map { $0.windowController! }?.dismissController(self)
    }
    
    override func keyDown(with event: NSEvent) {
        // Check if it's the hotkey (e.g., Command + Shift + A)
        if let shortcut = ApplicationSettings.shared.shortcut(for: event) {
            EventRegistry.shared.publish(eventBus: self.eventBus, event: shortcut.event)
        } else {
            super.keyDown(with: event)
        }
    }
    
    
    // MARK: - Command/Event Handlers
    
    private func changePath(command: ChangePathMessage) {
        self.path = command.path
    }
    
    private func navigateBack(command: Causality.NoMessage) {
        if let previous = self.history.pop() {
            DispatchQueue.main.async {
                self.navigatingBack = true
                Commands.changePath(eventBus: self.eventBus, previous)
            }
        }
    }
    
    private func pathChanged(message: PathChangedMessage) {
        self.window?.title = message.path.removingPercentEncoding!
    }
    
    private func showActionBar(message: Causality.NoMessage) {
        self.actionBar.present(for: self.window!)
    }
    
    
    // MARK: - NSWindowStateRestoration
    
    func encodeState(with coder: NSCoder) {
        if let frame = self.window?.frame {
            coder.encode(NSString(string: NSStringFromRect(frame)), forKey: "window-frame")
        }
        
        coder.encode(NSString(string: path), forKey: "path")
    }
    
    func decodeState(with coder: NSCoder) {
        if let rectString: NSString = coder.decodeObject(of: NSString.self, forKey: "window-frame") {
            let frame = NSRectFromString(rectString as String)
            self.window?.setFrame(frame, display: true)
        }
        
        if let path = coder.decodeObject(of: NSString.self, forKey: "path"),
           !path.isEqual(to: self.path) {
            
            Commands.changePath(eventBus: self.eventBus, path.removingPercentEncoding!)
        }
    }

}

extension ApplicationSettings {
    
    func shortcut(for event: NSEvent) -> Shortcut? {
        if let specialKey = event.specialKey {
            return self
                .shortcuts
                .values
                .first(where: { shortcut in
                    shortcut.key.key == .specialKey(key: specialKey)
                    && shortcut.key.modifiers.subtracting(event.modifierFlags).isEmpty
                })
        } else if let keyCode = event.characters?.lowercased() {
            return self
                .shortcuts
                .values
                .first(where: { shortcut in
                    shortcut.key.key == .character(character: keyCode)
                    && shortcut.key.modifiers.subtracting(event.modifierFlags).isEmpty
                })
        }
        
        return nil
    }
    
}
