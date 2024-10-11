//
//  FileManager+observeFileSystemEntries.swift
//  Navigator
//
//  Created by Thomas Bonk on 04.10.24.
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

import Combine
import Foundation

extension FileManager {
    
    public func observeFileForChanges(_ url: URL, handler: @escaping () -> Void) -> Cancellable? {
        return FileSystemEntryObserver(url: url, eventMask: .all, handler: handler)
    }
    
    public func observeDirectory(_ url: URL, handler: @escaping () -> Void) -> Cancellable? {
        return FileSystemEntryObserver(url: url, eventMask: .all, handler: handler)
    }
    
}

private class FileSystemEntryObserver: Cancellable {
   
    // MARK: - Private Properties
    
    private let fileDescriptor: CInt
    private let source: DispatchSourceProtocol
    
    
    // MARK: - Initialization
    
    init?(url: URL, eventMask: DispatchSource.FileSystemEvent, handler: @escaping () -> Void) {
        self.fileDescriptor = open(url.path, O_EVTONLY)
        
        guard
            self.fileDescriptor >= 0
        else {
            return nil
        }

        self.source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: self.fileDescriptor, eventMask: eventMask, queue: DispatchQueue.global())
        self.source.setEventHandler {
            DispatchQueue.global().async {
                handler()
            }
        }
        self.source.resume()
    }
    
    
    // MARK: - Cancellable

    func cancel() {
      self.source.cancel()
      close(fileDescriptor)
    }

}
