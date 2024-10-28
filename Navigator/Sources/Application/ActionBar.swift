//
//  ActionBar.swift
//  Navigator
//
//  Created by Thomas Bonk on 14.10.24.
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
import DSFQuickActionBar

class ActionBar: NSObject, DSFQuickActionBarContentSource {
    
    // MARK: - Private Properties
    
    private var eventBus: Causality.Bus
    private var quickActionBar: DSFQuickActionBar
    
    // MARK: - Initialization
    
    class func create(with eventBus: Causality.Bus) -> ActionBar {
        return ActionBar(with: eventBus)
    }
    
    private init(with eventBus: Causality.Bus) {
        self.eventBus = eventBus
        self.quickActionBar = DSFQuickActionBar()
        
        super.init()
        
        self.quickActionBar.contentSource = self
    }
    
    
    // MARK: - Public Methods
    
    public func present(for window: NSWindow) {
        self.quickActionBar.present(parentWindow: window, showKeyboardShortcuts: true)
    }
    
    
    // MARK: - DSFQuickActionBarContentSource
    
    func quickActionBar(_ quickActionBar: DSFQuickActionBar, itemsForSearchTermTask task: DSFQuickActionBar.SearchTask) {
        if task.searchTerm.isEmpty {
            let items = EventRegistry.shared.actionEvents
            
            task.complete(with: items)
        } else {
            let items = EventRegistry.shared.actionEvents
                .filter {
                    $0.description
                        .lowercased()
                        .localizedCaseInsensitiveContains(task.searchTerm.lowercased())
                }
            
            task.complete(with: items)
        }
    }
    
    func quickActionBar(_ quickActionBar: DSFQuickActionBar, viewForItem item: AnyHashable, searchTerm: String) -> NSView? {
        let actionEvent = item as! EventRegistry.ActionEvent
        let label = NSTextField(labelWithString: actionEvent.description)
        
        label.font = .systemFont(ofSize: max(NSFont.systemFontSize, 16))
        
        return label
    }
    
    func quickActionBar(_ quickActionBar: DSFQuickActionBar, didSelectItem item: AnyHashable) {
        // Empty by design
    }
    
    func quickActionBar(_ quickActionBar: DSFQuickActionBar, didActivateItem item: AnyHashable) {
        let actionEvent = item as! EventRegistry.ActionEvent
        
        EventRegistry.shared.publish(eventBus: self.eventBus, event: actionEvent.label)
    }
}
