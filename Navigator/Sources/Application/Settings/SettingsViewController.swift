//
//  SettingsViewController.swift
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

class SettingsViewController: NSViewController {
    
    // MARK: - Private Properties
    
    @IBOutlet
    private var textView: NSTextView!
    
    
    // MARK: - NSViewController
    
    override func awakeFromNib() {
        self.textView.font = NSFont.monospacedSystemFont(ofSize: 14.0, weight: .regular)
    }
    
    override func viewWillAppear() {
        // TODO: Error handling
        let code = (try? String(contentsOf: AppDelegate.ApplicationSettingsFile, encoding: .utf8)) ?? ""
        
        self.textView.string = code
    }
    
    
    // MARK - Public Methods
    
    public func save() throws {
        let code = self.textView.string
        
        _ = try Marco.parse(code)
        try code.write(to: AppDelegate.ApplicationSettingsFile, atomically: true, encoding: .utf8)
    }
    
}
