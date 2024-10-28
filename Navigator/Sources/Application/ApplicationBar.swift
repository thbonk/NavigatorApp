//
//  ApplicationBar.swift
//  Navigator
//
//  Created by Thomas Bonk on 28.10.24.
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
import DSFQuickActionBar
import UniformTypeIdentifiers

class ApplicationBar: NSObject, DSFQuickActionBarContentSource {
    
    // MARK: - Private Properties
    
    private let openConfiguration: NSWorkspace.OpenConfiguration = {
        let config = NSWorkspace.OpenConfiguration()
        
        config.promptsUserIfNeeded = true
        config.addsToRecentItems = true
        config.activates = true
        config.hides = false
        config.hidesOthers = false
        config.isForPrinting = false
        
        return config
    }()
    
    private var parentWindow: NSWindow
    private var quickActionBar: DSFQuickActionBar
    
    private var fileUrls: [URL] = []
    private var applicationUrls: [URL] = []
    
    
    // MARK: - Initialization
    
    class func create(with window: NSWindow) -> ApplicationBar {
        return ApplicationBar(with: window)
    }
    
    private init(with window: NSWindow) {
        self.parentWindow = window
        self.quickActionBar = DSFQuickActionBar()
        
        super.init()
        
        self.quickActionBar.contentSource = self
    }
    
    
    // MARK: - Public Methods
    
    public func present(for urls: [URL]) {
        self.fileUrls = urls
        self.applicationUrls = applicationUrls(for: urls)
        self.quickActionBar.present(parentWindow: self.parentWindow, showKeyboardShortcuts: true)
    }
    
    
    // MARK: - DSFQuickActionBarContentSource
    
    func quickActionBar(_ quickActionBar: DSFQuickActionBar, itemsForSearchTermTask task: DSFQuickActionBar.SearchTask) {
        if task.searchTerm.isEmpty {
            let items = self.applicationUrls
            
            task.complete(with: items)
        } else {
            let items = self.applicationUrls
                .filter {
                    $0.lastPathComponent
                        .deletingPathExtension
                        .lowercased()
                        .localizedCaseInsensitiveContains(task.searchTerm.lowercased())
            }
            
            task.complete(with: items)
        }
    }
    
    func quickActionBar(_ quickActionBar: DSFQuickActionBar, viewForItem item: AnyHashable, searchTerm: String) -> NSView? {
        let displayName = FileManager.default.displayName(atPath: (item as! URL).path)
        let label = NSTextField(labelWithString: displayName)
        label.font = .systemFont(ofSize: max(NSFont.systemFontSize, 16))
        
        return label
    }
    
    func quickActionBar(_ quickActionBar: DSFQuickActionBar, didSelectItem item: AnyHashable) {
        // Empty by design
    }
    
    func quickActionBar(_ quickActionBar: DSFQuickActionBar, didActivateItem item: AnyHashable) {
        let applicationUrl = item as! URL
        
        NSWorkspace.shared.open(self.fileUrls, withApplicationAt: applicationUrl, configuration: self.openConfiguration)

        self.applicationUrls.removeAll()
        self.fileUrls.removeAll()
    }
    
    
    // MARK: - Private Methods
    
    private func applicationUrls(for fileUrls: [URL]) -> [URL] {
        let appUrls: [[URL]] = fileUrls.map { fileUrl in
            guard
                let resourceValues = try? fileUrl.resourceValues(forKeys: [.typeIdentifierKey])
            else {
                return [URL]()
            }
            
            guard
                let typeIdentifier = resourceValues.typeIdentifier,
                let type = UTType(typeIdentifier)
            else {
                return [URL]()
            }

            
            let appUrls = NSWorkspace.shared.urlsForApplications(toOpen: type)
            return appUrls
        }
        
        let commonAppUrls = Array<URL>.commonElements(in: appUrls)
        
        return commonAppUrls.sorted { $0.path < $1.path }
    }
}
