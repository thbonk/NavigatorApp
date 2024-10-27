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
import Observation

class SidebarViewController: NSViewController, NSOutlineViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet
    @objc private var outlineView: NSOutlineView!
    @IBOutlet
    @objc private var outlineViewDataSource: SidebarViewOutlineDataSource!
    
    
    // MARK: - Private Properties
    
    private var deleteFavoriteSubscription: Commands.DeleteFavoriteSubscription?
    private var ejectVolumeSubscription: Commands.EjectVolumeSubscription?
    private var volumesChangedCancellable: Cancellable?
    private var fileshareFoundSubscription: Events.FileshareFoundSubscription?
    private var fileshareRemovedSubscription: Events.FileshareRemovedSubscription?
    
    
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
        self.deleteFavoriteSubscription = self.eventBus!.subscribe(Commands.DeleteFavorite, handler: self.deleteFavorite)
        self.ejectVolumeSubscription = self.eventBus!.subscribe(Commands.EjectVolume, handler: self.ejectVolume)
        self.fileshareFoundSubscription = AppDelegate.globalEventBus.subscribe(Events.FileshareFound, handler: self.fileshareFound)
        self.fileshareRemovedSubscription = AppDelegate.globalEventBus.subscribe(Events.FileshareRemoved, handler: self.fileshareRemoved)
        
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
        
        self.deleteFavoriteSubscription?.unsubscribe()
        self.volumesChangedCancellable?.cancel()
        self.fileshareFoundSubscription?.unsubscribe()
        self.fileshareRemovedSubscription?.unsubscribe()
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
    
    private func deleteFavorite(_ message: Causality.NoMessage) {
        DispatchQueue.main.async {
            guard
                // TODO make hasFocus a property of NSView
                self.view.window?.firstResponder == self.outlineView
            else {
                NSBeep()
                return
            }
            
            guard
                self.outlineView.selectedRow >= 0
            else {
                NSBeep()
                return
            }
            
            guard
                let item = self.outlineView.item(atRow: self.outlineView.selectedRow) as? FileInfo
            else {
                NSBeep()
                return
            }
        
            do {
                self.outlineViewDataSource.favoritesCategory.favorites.removeAll { $0 == item }
                try self.outlineViewDataSource.favoritesCategory.save()
                self.outlineView.reloadData()
            } catch {
                Commands.showErrorAlert(window: NSApp.keyWindow, title: "Error when removing favorite", error: error)
            }
        }
    }
    
    private func ejectVolume(_ message: Causality.NoMessage) {
        DispatchQueue.main.async {
            guard
                // TODO make hasFocus a property of NSView
                self.view.window?.firstResponder == self.outlineView
            else {
                NSBeep()
                return
            }
            
            guard
                self.outlineView.selectedRow >= 0
            else {
                NSBeep()
                return
            }
            
            guard
                let volume = self.outlineView.item(atRow: self.outlineView.selectedRow) as? VolumeInfo
            else {
                NSBeep()
                return
            }
            
            guard
                volume.isEjectable || !volume.isLocal
            else {
                NSBeep()
                return
            }
        
            do {
                Commands.changePath(eventBus: self.eventBus!, "/Volumes")
                try NSWorkspace.shared.unmountAndEjectDevice(at: volume.url)
                DispatchQueue.main.async {
                    self.outlineView.reloadData()
                }
            } catch {
                Commands.showErrorAlert(window: NSApp.keyWindow, title: "Error ejecting volume", error: error)
            }
        }
    }
    
    private func fileshareFound(message: FileshareFoundMessage) {
        DispatchQueue.main.async {
            self.outlineViewDataSource.filesharesCategory.fileshares.append(message.service.fileshareInfo)
        }
        DispatchQueue.main.async {
            self.outlineView.reloadData()
        }
    }
    
    private func fileshareRemoved(message: FileshareRemovedMessage) {
        DispatchQueue.main.async {
            self.outlineViewDataSource.filesharesCategory.fileshares.removeAll(where: { $0.id == message.service.fileshareInfo.id })
        }
        DispatchQueue.main.async {
            self.outlineView.reloadData()
        }
    }
    
    
    // MARK: - NSOutlineViewDelegate
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return (item is SidebarFavorites) || (item is SidebarVolumes) || (item is SidebarFileshares)

    }
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
        return (item is SidebarFavorites) || (item is SidebarVolumes) || (item is SidebarFileshares)
    }
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return !((item is SidebarFavorites) || (item is SidebarVolumes) || (item is SidebarFileshares))
    }
    
    @MainActor
    func outlineViewSelectionDidChange(_ notification: Notification) {
        if self.outlineView.selectedRow >= 0 {
            let item = self.outlineView.item(atRow: self.outlineView.selectedRow)!
            
            if let fileshareInfo = item as? FileshareInfo {
                NSWorkspace.shared.open(fileshareInfo.url)
            } else if let filesystemEntry = item as? FilesystemEntry {
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
        } else if let item = item as? SidebarFileshares {
            view.textField?.stringValue = item.name
            view.textField?.font = NSFont.systemFont(ofSize: view.textField!.font!.pointSize, weight: .bold)
            view.imageView?.image = NSImage(systemSymbolName: "server.rack", accessibilityDescription: "Mounted Drives")
        } else if let volumeInfo = item as? VolumeInfo {
            view.textField?.stringValue = volumeInfo.name
            view.imageView?.image = volumeInfo.icon
        } else if let fileInfo = item as? FileInfo {
            view.textField?.stringValue = fileInfo.name
            view.imageView?.image = fileInfo.icon
        } else if let fileshareInfo = item as? FileshareInfo {
            view.textField?.stringValue = "\(fileshareInfo.hostname) (\(fileshareInfo.url.scheme!))"
            view.imageView?.image = Asset.fileshareIcon.image
        }
        
        return view
    }
}
