//
//  FileManager+directoryContents.swift
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

private let properties: [URLResourceKey] = [
    .creationDateKey,
    .contentAccessDateKey,
    .contentModificationDateKey,
    .contentTypeKey,
    .customIconKey,
    .effectiveIconKey,
    .fileSizeKey,
    .isAliasFileKey,
    .isVolumeKey,
    .isPackageKey,
    .isReadableKey,
    .isWritableKey,
    .isDirectoryKey,
    .isExecutableKey,
    .isApplicationKey,
    .isAliasFileKey,
    .isRegularFileKey,
    .isMountTriggerKey,
    .isSymbolicLinkKey,
    .volumeIsLocalKey,
    .volumeIsInternalKey,
    .volumeIsEjectableKey,
    .volumeIsReadOnlyKey,
    .volumeIsRemovableKey,
    .volumeLocalizedNameKey,
    .localizedNameKey
]
private let propertiesSet: Set<URLResourceKey> = Set(properties)

extension FileManager {
    
    func contentsOfDirectory(atPath path: String, withHiddenFiles: Bool = false) throws -> [FileInfo] {
        let options: FileManager.DirectoryEnumerationOptions = withHiddenFiles ? [] : [.skipsHiddenFiles]
        
        return try FileManager
            .default
            .contentsOfDirectory(at: path.fileUrl, includingPropertiesForKeys: properties, options: options)
            .map {
                if self.fileExists(url: $0) {
                    let attributes = try self.attributesOfItem(at: $0)
                    
                    return FileInfo(url: $0.path.precomposedStringWithCanonicalMapping.fileUrl,
                                    resourceValues: try $0.resourceValues(forKeys: propertiesSet),
                                    attributes: attributes)
                } else {
                    return FileInfo(url: $0.path.precomposedStringWithCanonicalMapping.fileUrl, resourceValues: URLResourceValues(), attributes: [:])
                }
            }
            .sorted { $0.name < $1.name }
    }
    
    func fileInfo(from url: URL) throws -> FileInfo {
        let resourceValues = try url.resourceValues(forKeys: propertiesSet)
        let attributes = try self.attributesOfItem(at: url)
        
        return FileInfo(url: url, resourceValues: resourceValues, attributes: attributes)
    }
    
    func fileInfo(from path: String) throws -> FileInfo {
        return try fileInfo(from: path.fileUrl)
    }
    
}
