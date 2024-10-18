//
//  FileOperationsQueue.swift
//  Navigator
//
//  Created by Thomas Bonk on 15.10.24.
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

import Causality
import CoreFoundation
import Foundation

@objc class FileOperationsQueue: NSObject {
    
    // MARK: - Public Properties
    
    public var executeSequentially: Bool {
        get { self.queue.maxConcurrentOperationCount == 1 }
        set { self.queue.maxConcurrentOperationCount = newValue ? 1 : Int.max }
    }
    
    
    // MARK: - Private Properties
    
    private var eventBus: Causality.Bus
    private var queue = OperationQueue()
    
    
    // MARK: - Initialization
    
    init(eventBus: Causality.Bus) {
        self.eventBus = eventBus
        
        super.init()
        
        self.queue.maxConcurrentOperationCount = 1
        self.queue.qualityOfService = .background
        self.queue.name = "Navigator.FileOperationsQueue"
    }
    
    
    // MARK: - File Operations
    
    public func enqueueMoveToBinOperations(_ fileInfos: [FileInfo]) {
        self.queue.addOperations(fileInfos.map { MoveToBinOperation($0) }, waitUntilFinished: false)
    }
    
    public func enqueueMoveToBinOperation(_ fileInfo: FileInfo) {
        self.enqueueMoveToBinOperations([fileInfo])
    }
    
    public func enqueueDeleteOperations(_ fileInfos: [FileInfo]) {
        self.queue.addOperations(fileInfos.map { DeleteOperation($0) }, waitUntilFinished: false)
        self.queue.addOperation {
            Commands.reloadDirectoryContents(eventBus: self.eventBus)
        }
    }
    
    public func enqueueDeleteOperation(_ fileInfo: FileInfo) {
        self.enqueueDeleteOperations([fileInfo])
    }
    
    public func enqeueCopyOperations(_ fileInfos: [FileInfo], to folderUrl: URL) {
        self.queue.addOperations(fileInfos.map({
            CopyOperation($0, destinationUrl: folderUrl.appendingPathComponent($0.url.lastPathComponent))
        }), waitUntilFinished: false)
    }
    
    public func enqeueCopyOperation(_ fileInfo: FileInfo, to folderUrl: URL) {
        self.enqeueCopyOperations([fileInfo], to: folderUrl)
    }
    
    public func enqeueCutOperations(_ fileInfos: [FileInfo], to folderUrl: URL) {
        self.queue.addOperations(fileInfos.map({
            CutOperation($0, destinationUrl: folderUrl.appendingPathComponent($0.url.lastPathComponent))
        }), waitUntilFinished: false)
    }
    
    public func enqeueCutOperation(_ fileInfo: FileInfo, to folderUrl: URL) {
        self.enqeueCutOperations([fileInfo], to: folderUrl)
    }
}

public protocol FileOperation {
    
    var descripition: String { get }
    
}

public class CopyOperation: BlockOperation, FileOperation, @unchecked Sendable {
    
    // MARK: - Public Properties
    
    public var descripition: String {
        "Copy \(fileInfo.path) to \(destinationUrl.path)"
    }
    
    
    // MARK: - Private Properties
    
    private let fileInfo: FileInfo
    private let destinationUrl: URL
    
    
    // MARK: - Initialization
    
    init(_ fileInfo: FileInfo, destinationUrl: URL) {
        self.fileInfo = fileInfo
        self.destinationUrl = destinationUrl
        
        super.init()
        self.addExecutionBlock(self.copyFile)
    }
    
    
    // MARK: - Private Methods
    
    private func copyFile() {
        do {
            try FileManager.default.copyItem(at: fileInfo.url, to: destinationUrl)
        } catch {
            // TODO error handling
        }
    }
}

public class CutOperation: BlockOperation, FileOperation, @unchecked Sendable {
    
    // MARK: - Public Properties
    
    public var descripition: String {
        "Move \(fileInfo.path) to \(destinationUrl.path)"
    }
    
    
    // MARK: - Private Properties
    
    private let fileInfo: FileInfo
    private let destinationUrl: URL
    
    
    // MARK: - Initialization
    
    init(_ fileInfo: FileInfo, destinationUrl: URL) {
        self.fileInfo = fileInfo
        self.destinationUrl = destinationUrl
        
        super.init()
        self.addExecutionBlock(self.cutFile)
    }
    
    
    // MARK: - Private Methods
    
    private func cutFile() {
        do {
            try FileManager.default.moveItem(at: fileInfo.url, to: destinationUrl)
        } catch {
            // TODO error handling
        }
    }
}

public class MoveToBinOperation: BlockOperation, FileOperation, @unchecked Sendable {
    
    // MARK: - Public Properties
    
    public var descripition: String {
        "Move \(fileInfo.name) to Bin"
    }
    
    
    // MARK: - Private Properties
    
    private let fileInfo: FileInfo
    
    
    // MARK: - Initialization
    
    init(_ fileInfo: FileInfo) {
        self.fileInfo = fileInfo
        
        super.init()
        self.addExecutionBlock(self.moveToBin)
    }
    
    
    // MARK: - Private Methods
    
    private func moveToBin() {
        do {
            try FileManager.default.trashItem(at: fileInfo.url, resultingItemURL: nil)
        } catch {
            // TODO error handling
        }
    }
    
}

public class DeleteOperation: BlockOperation, FileOperation, @unchecked Sendable {
    
    // MARK: - Public Properties
    
    public var descripition: String {
        "Delete \(fileInfo.name)"
    }
    
    
    // MARK: - Private Properties
    
    private let fileInfo: FileInfo
    
    
    // MARK: - Initialization
    
    init(_ fileInfo: FileInfo) {
        self.fileInfo = fileInfo
        
        super.init()
        self.addExecutionBlock(self.delete)
    }
    
    
    // MARK: - Private Methods
    
    private func delete() {
        do {
            try FileManager.default.removeItem(at: fileInfo.url)
        } catch {
            // TODO error handling
        }
    }
}
