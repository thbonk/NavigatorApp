//
//  SettingsWindowController.swift
//  Navigator
//
//  Created by Thomas Bonk on 02.10.24.
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

@objc class SettingsWindowController: NSWindowController, NSWindowDelegate, NSWindowStateRestoration {
    
    // MARK: - Public Properties
    
    @objc public dynamic var identifier: String?
    
    
    // MARK: - Private Properties
    
    private var settingsViewController: SettingsViewController? {
        contentViewController as? SettingsViewController
    }
    
    
    // MARK: - NSWindowDelegate
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        do {
            try self.settingsViewController?.save()
            return true
        } catch {
            Commands.showErrorAlert(window: self.window!, title: "Error while saving settings.", error: error)
        }
        
        return false
    }
    
    
    // MARK: - NSWindowStateRestoration
    
    func encodeState(with coder: NSCoder) {
        try? self.settingsViewController?.save()
        
        if let frame = self.window?.frame {
            coder.encode(NSString(string: NSStringFromRect(frame)), forKey: "window-frame")
        }
    }
    
    func decodeState(with coder: NSCoder) {
        if let rectString: NSString = coder.decodeObject(of: NSString.self, forKey: "window-frame") {
            let frame = NSRectFromString(rectString as String)
            self.window?.setFrame(frame, display: true)
        }
    }
    
}
