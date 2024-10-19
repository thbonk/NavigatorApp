//
//  VolumeInfo.swift
//  Navigator
//
//  Created by Thomas Bonk on 30.09.24.
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

import Foundation
import AppKit


fileprivate var byteCountFormatter: ByteCountFormatter = {
    let bcf = ByteCountFormatter()
    
    bcf.allowedUnits = [.useBytes, .useKB, .useMB]
    bcf.countStyle = .file
    
    return bcf
}()
fileprivate let dateFormat = Date.FormatStyle(date: .numeric, time: .shortened)


class VolumeInfo: FilesystemEntry {
    
    // MARK: - Public Properties
    
    let url: URL
    let name: String
    let resourceValues: URLResourceValues
    
    
    // MARK: - Initialization
    
    init(url: URL,
         name: String,
         resourceValues: URLResourceValues) {
        
        self.url = url
        self.name = name
        self.resourceValues = resourceValues
        
        super.init(path: url.path())
    }
}

extension VolumeInfo {
    
    var isLocal: Bool {
        resourceValues.volumeIsLocal ?? false
    }
    
    var isEjectable: Bool {
        resourceValues.volumeIsEjectable ?? false
    }
    
    var isRemovable: Bool {
        resourceValues.volumeIsRemovable ?? false
    }
    
    var isReadOnly: Bool {
        resourceValues.volumeIsReadOnly ?? false
    }
    
    var creationDate: String? {
        resourceValues.volumeCreationDate?.formatted(dateFormat)
    }
    
    var totalCapacity: String {
        if let size = self.resourceValues.volumeTotalCapacity {
            return byteCountFormatter.string(fromByteCount: Int64(size))
        }
        
        return "---"
    }
    
    var availableCapacity: String {
        if let size = self.resourceValues.volumeAvailableCapacity {
            return byteCountFormatter.string(fromByteCount: Int64(size))
        }
        
        return "---"
    }
    
    var icon: NSImage? {
        if let customIcon = self.resourceValues.customIcon {
            return customIcon
        }
        
        return self.resourceValues.effectiveIcon as? NSImage
    }
    
}
