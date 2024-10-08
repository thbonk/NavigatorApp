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

class SidebarViewOutlineDataSource: NSObject, NSOutlineViewDataSource {
    
    // MARK: - Public Properties
    
    public private(set) var categories: [SidebarCategory] = [
        SidebarFavorites(),
        SidebarVolumes()
    ]
    
    public var volumesCategory: SidebarVolumes {
        self.categories.first(where: { type(of: $0) == SidebarVolumes.self }) as! SidebarVolumes
    }
    
    
    // MARK: - Private Properties
    
    private var volumesChangedCancellable: Cancellable?
    
    
    // MARK: - Initialization
    
    deinit {
        self.volumesChangedCancellable?.cancel()
    }
    

    // MARK: - NSObject
    
    override func awakeFromNib() {
        self.volumesChangedCancellable = FileManager.default.observeVolumes(onChange: self.update(volumes:))
        // TODO error handling
        self.volumesCategory.volumes = (try? FileManager.default.mountedVolumes()) ?? []
    }

    
    // MARK: - NSOutlineViewDataSource
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return (item is SidebarFavorites) || (item is SidebarVolumes)
    }
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? SidebarCategory {
            return item.children.count
        } else {
            return categories.count
        }
    }
    
    @MainActor
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? SidebarCategory {
            return item.children[index]
        } else {
            return categories[index]
        }
    }
    
    
    // MARK: - Private Methods (Volumes)
    
    private func update(volumes: [VolumeInfo]) {
        volumesCategory.volumes = volumes
    }
}
