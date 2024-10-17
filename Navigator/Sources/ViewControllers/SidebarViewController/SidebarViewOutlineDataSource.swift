//
//  SidebarViewOutlineDataSource.swift
//  Navigator
//
//  Created by Thomas Bonk on 06.10.24.
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
import Combine
import UniformTypeIdentifiers

class SidebarViewOutlineDataSource: NSObject, NSOutlineViewDataSource {
    
    // MARK: - Public Properties
    
    public private(set) var categories: [SidebarCategory] = [
        SidebarFavorites(),
        SidebarVolumes()
    ]
    
    public var favoritesCategory: SidebarFavorites {
        self.categories.first(where: { type(of: $0) == SidebarFavorites.self }) as! SidebarFavorites
    }
    
    public var volumesCategory: SidebarVolumes {
        self.categories.first(where: { type(of: $0) == SidebarVolumes.self }) as! SidebarVolumes
    }
    

    // MARK: - NSObject
    
    override func awakeFromNib() {
        do {
            self.favoritesCategory.favorites = try SidebarFavorites.load().favorites
            self.volumesCategory.volumes = try FileManager.default.mountedVolumes()
        } catch {
            Commands.showErrorAlert(window: NSApp.keyWindow, title: "Error while reading mounted volumes", error: error)
        }
    }

    
    // MARK: - NSOutlineViewDataSource
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return (item is SidebarFavorites) || (item is SidebarVolumes)
    }
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        var result = 0
        
        if item == nil {
            result = self.categories.count
        } else if let item = item as? SidebarCategory {
            result = item.children.count
        }
        
        return result
    }
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return self.categories[index]
        } else {
            return (item as! SidebarCategory).children[index]
        }
    }
    
    
    // MARK: - NSOutlineViewDataSource Drag&Drop
    
    func outlineView(_ outlineView: NSOutlineView,
                     validateDrop info: any NSDraggingInfo,
                     proposedItem item: Any?,
                     proposedChildIndex index: Int) -> NSDragOperation {
        
        var dragOperation: NSDragOperation = []
        
        // Drag source came from another app.
        // Search through the array of NSPasteboardItems.
        let pasteboard = info.draggingPasteboard
        guard
            let items = pasteboard.pasteboardItems
        else {
            return dragOperation
        }
        
        for item in items {
            //var type = (kUTTypeFileURL as NSPasteboard.PasteboardType)
            //var type = (UTType.fileURL as NSPasteboard.PasteboardType)
            let type = NSPasteboard.PasteboardType.fileURL
            
            if item.availableType(from: [type]) != nil {
                // Drag source is coming from another app as a promised file URL
                dragOperation = [.copy]
            }
        }
        
        // Has a drop operation been determined yet?
        if dragOperation == [] {
            // Look for possible URLs we can consume.
            let acceptedTypes = [UTType.fileURL.identifier]
            let options = [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true,
                           NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes: acceptedTypes]
                as [NSPasteboard.ReadingOptionKey: Any]
            let pasteboard = info.draggingPasteboard
            
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) {
                if !urls.isEmpty {
                    dragOperation = [.copy]
                }
            }
        }
        
        return dragOperation
    }
        
    func outlineView(_ outlineView: NSOutlineView,
                     acceptDrop info: any NSDraggingInfo,
                     item: Any?,
                     childIndex index: Int) -> Bool {
        
        /** The drop source is from another app (Finder, Mail, Safari, etc.) and there may
            be more than one file.
            Drop each dragged file to their new place.
        */
        info.enumerateDraggingItems(
            options: NSDraggingItemEnumerationOptions.concurrent,
            for: outlineView,
            classes: [NSPasteboardItem.self],
            searchOptions: [:],
            using: { (draggingItem, idx, stop) in
                if let pasteboardItem = draggingItem.item as? NSPasteboardItem {
                    // Are we being passed a file URL as the drag type?
                    if  let itemType = pasteboardItem.availableType(from: [.fileURL]),
                        let filePath = pasteboardItem.string(forType: itemType),
                        let url = URL(string: filePath) {
                            do {
                                if info.draggingSourceOperationMask.contains(.copy) {
                                    let fileInfo = try FileManager.default.fileInfo(from: url)
                                    self.favoritesCategory.favorites.insert(fileInfo, at: index)
                                    try self.favoritesCategory.save()
                                }
                            } catch {
                                Commands.showErrorAlert(window: NSApp.keyWindow, title: "Error during Drag&Drop", error: error)
                            }
                        }
                }
            })
        
        DispatchQueue.main.async {
            outlineView.reloadData()
        }
        
        return true
    }
    
}
