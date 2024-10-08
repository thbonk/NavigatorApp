//
//  FileInfo.swift
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

import AppKit
import Foundation
import UniformTypeIdentifiers

class FileInfo: FilesystemEntry {
    
    // MARK: - Public Properties
    
    public private(set) var name: String
    public private(set) var url: URL
    
    
    // MARK: - Private Static Properties
    
    private static let byteCountFormatter: ByteCountFormatter = {
        let bcf = ByteCountFormatter()
        
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        
        return bcf
    }()
    
    
    // MARK: - Private Properties
    
    private var parent: String
    private var resourceValues: URLResourceValues
    
    
    // MARK: - Initialization
    
    init(url: URL, resourceValues: URLResourceValues) {
        self.url = url
        self.parent = self.url.path().deletingLastPathComponent
        self.name = self.url.lastPathComponent.decomposedStringWithCompatibilityMapping
        self.resourceValues = resourceValues
        
        super.init(path: self.url.path())
    }
    
}

extension FileInfo: NSCopying {
    
    func copy(with zone: NSZone? = nil) -> Any {
        return FileInfo(url: self.url, resourceValues: self.resourceValues)
    }
}

extension FileInfo {
    
    var resolvedAlias: FileInfo? {
        do {
            guard
                self.isAliasFile
            else {
                return nil
            }
            
            let resolvedURL = try URL(resolvingAliasFileAt: self.url, options: .withSecurityScope)
            
            return try FileManager.default.fileInfo(from: resolvedURL)
        } catch {
            LOGGER.error("Error while resolving alias: \(error)")
            return nil
        }
    }
    
}


// MARK: - Resource Value Getters

extension FileInfo {
    
    fileprivate static let dateFormat = Date.FormatStyle(date: .numeric, time: .shortened)        
    
    public var creationDate: String? {
        return self.resourceValues.creationDate?.formatted(FileInfo.dateFormat)
    }
    
    public var accessDate: String? {
        return self.resourceValues.contentAccessDate?.formatted(FileInfo.dateFormat)
    }
    
    public var modificationDate: String? {
        return self.resourceValues.contentModificationDate?.formatted(FileInfo.dateFormat)
    }
    
    public var contentType: UTType? {
        return self.resourceValues.contentType
    }
    
    public var icon: NSImage? {
        if let customIcon = self.resourceValues.customIcon {
            return customIcon
        }
        
        return self.resourceValues.effectiveIcon as? NSImage
    }
    
    public var fileSize: String {
        if let size = self.resourceValues.fileSize {
            return FileInfo.byteCountFormatter.string(fromByteCount: Int64(size))
        }
        
        return "---"
    }
    
    public var isAliasFile: Bool {
        return self.resourceValues.isAliasFile ?? false
    }
    
    public var isVolumeKey: Bool {
        return self.resourceValues.isVolume ?? false
    }
    
    public var isPackage: Bool {
        return self.resourceValues.isPackage ?? false
    }
    
    public var isReadable: Bool {
        return self.resourceValues.isReadable ?? false
    }
    
    public var isWritable: Bool {
        return self.resourceValues.isWritable ?? false
    }
    
    public var isDirectory: Bool {
        return self.resourceValues.isDirectory ?? false
    }
    
    public var isExecutable: Bool {
        return self.resourceValues.isExecutable ?? false
    }
    
    public var isApplication: Bool {
        return self.resourceValues.isApplication ?? false
    }
    
    public var isRegularFile: Bool {
        return self.resourceValues.isRegularFile ?? false
    }
    
    public var isMountTrigger: Bool {
        return self.resourceValues.isMountTrigger ?? false
    }
    
    public var isSymbolicLink: Bool {
        return self.resourceValues.isSymbolicLink ?? false
    }
    
    public var volumeIsLocal: Bool {
        return self.resourceValues.volumeIsLocal ?? false
    }
    
    public var volumeIsInternal: Bool {
        return self.resourceValues.volumeIsInternal ?? false
    }
    
    public var volumeIsEjectable: Bool {
        return self.resourceValues.volumeIsEjectable ?? false
    }
    
    public var volumeIsReadOnly: Bool {
        return self.resourceValues.volumeIsReadOnly ?? false
    }
    
    public var volumeIsRemovable: Bool {
        return self.resourceValues.volumeIsRemovable ?? false
    }
    
    public var volumeLocalizedName: String? {
        return self.resourceValues.volumeLocalizedName
    }
    
    public var localizedName: String? {
        return self.resourceValues.localizedName
    }
}
