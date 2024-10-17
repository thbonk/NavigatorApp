//
//  SidebarCategories.swift
//  Navigator
//
//  Created by Thomas Bonk on 07.10.24.
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


class SidebarCategory: NSObject {
    
    // MARK: - Public Properties
    
    public private(set) var name: String
    public fileprivate(set) var children: [Any]
    
    
    // MARK: - Initialization
    
    public init(name: String, children: [Any] = []) {
        self.name = name
        self.children = children
    }
}

class SidebarFavorites: SidebarCategory {
    
    // MARK: - Public Properties
    
    public var favorites: [FileInfo] {
        get {
            super.children as! [FileInfo]
        }
        set {
            super.children = newValue
        }
    }
    
    
    // MARK: - Initialization
    
    public init(favorites: [FileInfo] = []) {
        super.init(name: "Favorites", children: favorites)
    }
    
    
    // MARK: - Saving and Loading
    
    public func save() throws {
        let data = try JSONEncoder().encode(self.favorites.map({ $0.url }))
        
        UserDefaults.standard.set(data, forKey: "favorite-urls")
    }
    
    
    public class func load() throws -> SidebarFavorites {
        guard
            let data = UserDefaults.standard.data(forKey: "favorite-urls")
        else {
            return .init()
        }
        
        let urls = try JSONDecoder().decode([URL].self, from: data)
        return try .init(favorites: urls.map { try FileManager.default.fileInfo(from: $0) })
    }
    
}

class SidebarVolumes: SidebarCategory {
    
    // MARK: - Public Properties
    
    public var volumes: [VolumeInfo] {
        get {
            super.children as! [VolumeInfo]
        }
        set {
            super.children = newValue
        }
    }
    
    
    // MARK: - Initialization
    
    public init(volumes: [VolumeInfo] = []) {
        super.init(name: "Volumes", children: volumes)
    }
    
}
