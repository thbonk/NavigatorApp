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
import Causality
import Combine

class SidebarViewController: NSViewController, NSOutlineViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet
    @objc private var outlineView: NSOutlineView!
    @IBOutlet
    @objc private var outlineViewDataSource: SidebarViewOutlineDataSource!
    
    
    // MARK: - Private Properties
    
    private var moveSelectedFilesToBinSubscription: Commands.MoveSelectedFilesToBinSubscription?
    private var volumesChangedCancellable: Cancellable?
    
    
    // MARK: - NSViewController
    
    override func viewDidLoad() {
        // Accept file promises from apps like Safari.
        self.outlineView.registerForDraggedTypes(
            NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        
        self.outlineView.registerForDraggedTypes([
            .fileURL // Accept dragging of image file URLs from other apps.
        ])
        // Determine the kind of source drag originating from this app.
        // Note, if you want to allow your app to drag items to the Finder's trash can, add ".delete".
        self.outlineView.setDraggingSourceOperationMask([.copy], forLocal: false)
    }
    
    override func viewWillAppear() {
        self.moveSelectedFilesToBinSubscription = self.eventBus!.subscribe(Commands.MoveSelectedFilesToBin, handler: self.removeFavorite)
        
        self.volumesChangedCancellable = FileManager.default.observeVolumes(
            onMount: self.volumentMounted(_:), onUnmount: self.volumeWillUnmount(_:))
        
        DispatchQueue.main.async {
            for category in self.outlineViewDataSource.categories {
                self.outlineView.expandItem(category)
            }
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        self.moveSelectedFilesToBinSubscription?.unsubscribe()
        self.volumesChangedCancellable?.cancel()
    }
    
    
    // MARK: - Event Handlers
    
    private func volumentMounted(_ volume: VolumeInfo) {
        self.outlineViewDataSource.volumesCategory.volumes.append(volume)
        self.outlineView.reloadData()
    }
    
    private func volumeWillUnmount(_ url: URL) {
        self.outlineViewDataSource.volumesCategory.volumes.removeAll { $0.url == url }
        self.outlineView.reloadData()
    }
    
    private func removeFavorite(_ message: Causality.NoMessage) {
        guard
            // TODO make hasFocus a property of NSView
            self.view.window?.firstResponder == self.outlineView
        else {
            return
        }
        
        guard
            self.outlineView.selectedRow >= 0
        else {
            return
        }
        
        guard
            let item = self.outlineView.item(atRow: self.outlineView.selectedRow) as? FileInfo
        else {
            return
        }
        
        DispatchQueue.main.async {
            self.outlineViewDataSource.favoritesCategory.favorites.removeAll { $0 == item }
            self.outlineView.reloadData()
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
        } else if let fileInfo = item as? FileInfo {
            view.textField?.stringValue = fileInfo.name
            view.imageView?.image = fileInfo.icon
        }
        
        return view
    }
    
}
