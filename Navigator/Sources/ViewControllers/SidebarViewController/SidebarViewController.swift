//
//  SidebarViewController.swift
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

class SidebarViewController: NSViewController, NSOutlineViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet
    @objc private var outlineView: NSOutlineView!
    @IBOutlet
    @objc private var outlineViewDataSource: SidebarViewOutlineDataSource!
    
    
    // MARK: - NSViewController
    
    override func viewWillAppear() {
        DispatchQueue.main.async {
            for category in self.outlineViewDataSource.categories {
                self.outlineView.expandItem(category)
            }
        }
    }
    
    
    // MARK: - NSOutlineViewDelegate
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return (item is SidebarFavorites) || (item is SidebarVolumes)
    }
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
        return (item is SidebarFavorites) || (item is SidebarVolumes)
    }
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return !((item is SidebarFavorites) || (item is SidebarVolumes))
    }
    
    @MainActor
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if self.outlineView.selectedRow >= 0 {
            let item = self.outlineView.item(atRow: self.outlineView.selectedRow)!
            
            if let filesystemEntry = item as? FilesystemEntry {
                Commands.changePath(eventBus: self.eventBus!, filesystemEntry.path)
            }
        }
    }
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
        
        if let item = item as? SidebarFavorites {
            view.textField?.stringValue = item.name
            view.textField?.font = NSFont.systemFont(ofSize: view.textField!.font!.pointSize, weight: .bold)
            view.imageView?.image = NSImage(systemSymbolName: "heart", accessibilityDescription: "Favorite Folders")
        } else if let item = item as? SidebarVolumes {
            view.textField?.stringValue = item.name
            view.textField?.font = NSFont.systemFont(ofSize: view.textField!.font!.pointSize, weight: .bold)
            view.imageView?.image = NSImage(systemSymbolName: "internaldrive", accessibilityDescription: "Mounted Drives")
        } else if let volumeInfo = item as? VolumeInfo {
            view.textField?.stringValue = volumeInfo.name
            view.imageView?.image = volumeInfo.icon
        }
        
        return view
    }
    
}
