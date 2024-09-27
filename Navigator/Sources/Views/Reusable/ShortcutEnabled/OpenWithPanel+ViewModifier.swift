//
//  OpenWithPanel+ViewModifier.swift
//  Navigator
//
//  Created by Thomas Bonk on 25.09.24.
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

import Causality
import CoreServices
import FloatingFilter
import Foundation
import SwiftUI

struct OpenWithPanel: ViewModifier {    
    
    // MARK: - Private Properties
    
    private let shortcut: Shortcut
    
    @Binding
    private var selectedFiles: Set<String>
    
    @EnvironmentObject
    private var eventBus: Causality.Bus
    
    
    // MARK: - Initializer
    
    init(_ shortcut: Shortcut, selectedFiles: Binding<Set<String>>) {
        self.shortcut = shortcut
        self._selectedFiles = selectedFiles
    }
    
    
    // MARK: - Public Methods
    
    func body(content: Content) -> some View {
        ZStack {
            KeyboardShortcut(
                title: "Show Open with Panel",
                key: shortcut.key,
                modifiers: shortcut.modifiers,
                action: self.showOpenWithPanel)
            
            content
        }
    }
    
    
    // MARK: - Private Methods
    
    private func showOpenWithPanel() {
        if validateSelectedFiles() {
            let applicationUrls: [URL] = applicationUrls(for: selectedFiles.first!)
            
            if applicationUrls.isEmpty {
                Events.publishShowAlertEvent(
                    eventBus: eventBus,
                    AlertView.Alert(
                        severity: .warning,
                        title: "No application found that can open the selected file."))
            }
            
            let items = applicationUrls.map { url in
                Item(
                    identifier: url,
                    title: url.lastPathComponent.deletingPathExtension,
                    icon: NSWorkspace.shared.icon(forFile: url.path()))
            }
            
            FloatingFilterModule.showFilterWindow(items: items, filterPlaceholderText: "Open with...") { application in
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                config.addsToRecentItems = true
                config.promptsUserIfNeeded = true
                
                NSWorkspace.shared.open(
                    [selectedFiles.first!.fileUrl],
                    withApplicationAt: application.first!.identifier as! URL,
                    configuration: config)
            }
        }
    }
    
    private func applicationUrls(for path: String) -> [URL] {
        guard let unmanagedAppURLs = LSCopyApplicationURLsForURL(path.fileUrl as CFURL, .all) else {
            return []
        }
        
        return (unmanagedAppURLs.takeRetainedValue() as! [URL])
    }
    
    private func validateSelectedFiles() -> Bool {
        var alert: AlertView.Alert? = nil
        
        if self.selectedFiles.isEmpty {
            alert = AlertView.Alert(
                severity: .info,
                title: "No directory or file selected.")
        } else if self.selectedFiles.count > 1 {
            alert = AlertView.Alert(
                severity: .info,
                title: "More than one directory or file selected.",
                subtitle: "You can only open one file at a time.")
        }
        
        if let alert {
            Events.publishShowAlertEvent(eventBus: eventBus, alert)
        }
        
        return alert == nil
    }
}

extension ShortcutEnabled {
    
    func openWithPanel(_ shortcut: Shortcut, selectedFiles: Binding<Set<String>>) -> some View {
        modifier(OpenWithPanel(shortcut, selectedFiles: selectedFiles))
    }
    
}
