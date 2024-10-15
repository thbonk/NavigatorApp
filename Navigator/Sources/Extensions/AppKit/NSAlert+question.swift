//
//  NSAlert+question.swift
//  Navigator
//
//  Created by Thomas Bonk on 15.10.24.
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

extension NSAlert {
    public class func question(for window: NSWindow,
                               messageText: String,
                               informativeText: String,
                               buttons: [(title: String, action: () -> Void)]) {
        
        let alert = NSAlert()
            .withMessageText(messageText)
            .withInformativeText(informativeText)
        
        alert.icon = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: messageText)
        
        for button in buttons {
            alert.addButton(withTitle: button.title)
        }
        
        Task {
            let result = await alert.beginSheetModal(for: window)
            
            buttons[result.rawValue - 1000].action()
        }
    }
}
