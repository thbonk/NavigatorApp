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

import CoreFoundation
import Foundation

@objc class FileOperationsQueue: NSObject {
    
    // MARK: - Public Properties
    
    public var executeSequentially: Bool {
        get { self.queue.maxConcurrentOperationCount == 1 }
        set { self.queue.maxConcurrentOperationCount = newValue ? 1 : Int.max }
    }
    
    
    // MARK: - Private Properties
    
    private var queue = OperationQueue()
    
    
    // MARK: - Initialization
    
    override init() {
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
}

public protocol FileOperation {
    
    var descripition: String { get }
    
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
