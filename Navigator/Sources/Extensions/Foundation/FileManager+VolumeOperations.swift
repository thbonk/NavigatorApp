//
//  FileManager+VolumeOperations.swift
//  Navigator
//
//  Created by Thomas Bonk on 20.09.24.
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

import SwiftUI
import Foundation

extension FileManager {
    
    func mountedVolumes() throws -> [VolumeInfo] {
        var result = [VolumeInfo]()
        let resourceValueKeys: [URLResourceKey] = [.volumeIsLocalKey, .volumeIsEjectableKey, .nameKey]
        
        if let volumes = self.mountedVolumeURLs(
            includingResourceValuesForKeys: resourceValueKeys,
            options: .skipHiddenVolumes) {
            
            try volumes.forEach { url in
                let resourceValues = try url.resourceValues(forKeys: Set(resourceValueKeys))
                result.append(
                    VolumeInfo(
                        name: resourceValues.name!,
                        path: url.path,
                        isLocal: resourceValues.volumeIsLocal!,
                        isEjectable: resourceValues.volumeIsEjectable!,
                        icon: Image(nsImage: NSWorkspace.shared.icon(forFile: url.path)))
                )
            }
        }
        
        return result
    }
    
}

class VolumeInfo: FileSystemEntry {
    
    // MARK: - Public Properties
    
    let name: String
    let isLocal: Bool
    let isEjectable: Bool
    let icon: Image
    
    
    // MARK: - Initialization
    
    init(name: String,
         path: String,
         isLocal: Bool,
         isEjectable: Bool,
         icon: Image) {
        
        self.name = name
        self.isLocal = isLocal
        self.isEjectable = isEjectable
        self.icon = icon
        
        super.init(path: path)
    }
}
