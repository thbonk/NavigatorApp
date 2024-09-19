//
//  FileManager+observeDirectory.swift
//  Navigator
//
//  Created by Thomas Bonk on 17.09.24.
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
    public func observeDirectory(_ directory: URL, callback: @escaping () -> Void) -> Cancellable? {
        return DirectoryObserver(url: directory, block: callback)
    }
}

private class DirectoryObserver: Cancellable {
   
    // MARK: - Private Properties
    
    private let fileDescriptor: CInt
    private let source: DispatchSourceProtocol
    
    
    // MARK: - Initialization
    
    init?(url: URL, block: @escaping () -> Void) {
        self.fileDescriptor = open(url.path, O_EVTONLY)
        
        guard
            self.fileDescriptor >= 0
        else {
            return nil
        }

        self.source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: self.fileDescriptor, eventMask: .all, queue: DispatchQueue.global())
        self.source.setEventHandler {
          block()
        }
        self.source.resume()
    }
    
    
    // MARK: - Cancellable

    func cancel() {
      self.source.cancel()
      close(fileDescriptor)
    }

}
