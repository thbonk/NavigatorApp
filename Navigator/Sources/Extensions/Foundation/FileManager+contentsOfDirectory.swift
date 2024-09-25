//
//  FileInfo.swift
//  Navigator
//
//  Created by Thomas Bonk on 08.09.24.
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
import SwiftUI
import UniformTypeIdentifiers

extension FileManager {
    
    func contentsOfDirectory(atPath path: String, withHiddenFiles: Bool = false) throws -> [FileInfo] {
        let contents = try FileManager
            .default
            .contentsOfDirectory(atPath: path)
            .filter { withHiddenFiles || !$0.hasPrefix(".") }
            .sorted()
            .map { try self.toFileInfo(parent: path, name: $0) }
            
        return contents
    }
    
    private func toFileInfo(parent: String, name: String) throws -> FileInfo {
        let filePath = parent.appendingPathComponent(name)
        var isDirectory: ObjCBool = false
        
        FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
        
        let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
        
        return FileInfo(
            parent: parent,
            name: name,
            icon: Image(nsImage: NSWorkspace.shared.icon(forFile: filePath)),
            isDirectory: isDirectory.boolValue,
            createdAt: (attributes[.creationDate] as? Date)?.formatted() ?? "---",
            modifiedAt: (attributes[.modificationDate] as? Date)?.formatted() ?? "---",
            sizeInBytes: (attributes[.size] as? NSNumber)?.int64Value ?? 0)
    }
}

class FileInfo: FileSystemEntry, ObservableObject, PasteboardObject, Codable {
    
    // MARK: - Public Properties
    
    public var ID: Int {
        return self.parent.appendingPathComponent(name).hashValue
    }
    
    @Published
    public private(set) var icon: Image
    @Published
    public private(set) var name: String
    @Published
    public private(set) var isDirectory: Bool
    @Published
    public private(set) var createdAt: String
    @Published
    public private(set) var modifiedAt: String
    @Published
    public private(set) var sizeInBytes: Int64
    public var url: URL {
        URL(fileURLWithPath: self.parent.appendingPathComponent(self.name))
    }
    public var size: String {
        if !isDirectory {
            return FileInfo.byteCountFormatter.string(fromByteCount: sizeInBytes)
        } else {
            return "---"
        }
    }
    public var isApplication: Bool {
        return NSWorkspace.shared.isFilePackage(atPath: self.parent.appendingPathComponent(self.name))
                && self.name.hasSuffix("app")
    }
    
    
    // MARK: - Private Static Properties
    
    private static let byteCountFormatter: ByteCountFormatter = {
        let bcf = ByteCountFormatter()
        
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        
        return bcf
    }()
    
    
    // MARK: - Private Properties
    
    private var parent: String
    
    
    // MARK: - Initialization
    
    init(parent: String,
         name: String,
         icon: Image,
         isDirectory: Bool,
         createdAt: String,
         modifiedAt: String,
         sizeInBytes: Int64) {
    
        self.parent = parent
        self.icon = icon
        self.name = name
        self.isDirectory = isDirectory
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.sizeInBytes = sizeInBytes
        
        super.init(path: parent.appendingPathComponent(name))
    }
    
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case parent = "parent"
        case name = "name"
        case isDirectory = "isDirectory"
        case createdAt = "createdAt"
        case modifiedAt = "modifiedAt"
        case sizeInBytes = "sizeInBytes"
    }
    
    
    // MARK: - Encodable
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.parent, forKey: .parent)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.isDirectory, forKey: .isDirectory)
        try container.encode(self.createdAt, forKey: .createdAt)
        try container.encode(self.modifiedAt, forKey: .modifiedAt)
        try container.encode(self.sizeInBytes, forKey: .sizeInBytes)
    }
    
    
    // MARK: - Decodable
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.parent = try container.decode(String.self, forKey: .parent)
        let name = try container.decode(String.self, forKey: .name)
        self.name = name
        self.icon = Image(nsImage: NSWorkspace.shared.icon(forFile: self.parent.appendingPathComponent(name)))
        self.isDirectory = try container.decode(Bool.self, forKey: .isDirectory)
        self.createdAt = try container.decode(String.self, forKey: .createdAt)
        self.modifiedAt = try container.decode(String.self, forKey: .modifiedAt)
        self.sizeInBytes = try container.decode(Int64.self, forKey: .sizeInBytes)
        
        super.init(path: parent.appendingPathComponent(name))
    }
}

extension FileInfo: Transferable {
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .fileInfo) { fileInfo in
            try JSONEncoder().encode(fileInfo)
        } importing: { data in
            try JSONDecoder().decode(FileInfo.self, from: data)
        }
    }
    
}

extension UTType {
    static var fileInfo = UTType(importedAs: "com.github.thbonk.Navigator.fileInfo")
}

