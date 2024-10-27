//
//  MainViewController.swift
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

class MainViewController: NSSplitViewController {
    
    // MARK: - Private Properties
    
    private var toggleSidebarSubscription: Commands.ToggleSidebarSubscription?
    
    
    // MARK: - NSViewController
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.toggleSidebarSubscription = self.eventBus!.subscribe(Commands.ToggleSidebar, handler: self.toggleSidebar)
    }
    
    override func viewWillDisappear() {
        self.toggleSidebarSubscription?.unsubscribe()
    }
    
    
    // MARK: - Action Handlers
    
    @IBAction
    @objc private func showOrHideSidebar(sender: Any) {
        guard
            let primaryItem = splitViewItems.first
        else {
            return
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25 // Customize animation duration
            primaryItem.animator().isCollapsed.toggle()
        }
    }
    
    
    // MARK: - Event Handlers
    
    private func toggleSidebar(message: Causality.NoMessage) {
        self.showOrHideSidebar(sender: self)
    }
}

