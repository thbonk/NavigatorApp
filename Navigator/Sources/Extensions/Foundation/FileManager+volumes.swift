//
//  FileManager+volumes.swift
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

import AppKit
import Combine
import Foundation

fileprivate let resourceValueKeys: [URLResourceKey] = [
    .nameKey,
    .volumeIsLocalKey,
    .volumeIsEjectableKey,
    .volumeIsRemovableKey,
    .volumeIsReadOnlyKey,
    .volumeCreationDateKey,
    .volumeTotalCapacityKey,
    .volumeAvailableCapacityKey,
    .effectiveIconKey,
    .customIconKey
]

extension FileManager {
    
    func mountedVolumes() throws -> [VolumeInfo] {
        var result = [VolumeInfo]()
        
        if let volumes = self.mountedVolumeURLs(
            includingResourceValuesForKeys: resourceValueKeys,
            options: [.produceFileReferenceURLs]) {
            
            result = try volumes
                .filter { $0.path.hasPrefix("/Volumes") || $0.path == "/" }
                .filter { !$0.path.hasPrefix("/Volumes/com.apple.TimeMachine") }
                .filter { self.fileExists(url: $0) }
                .map { try self.volume(for: $0) }
        }
        
        return result
    }
    
    func volume(for url: URL) throws -> VolumeInfo {
        let resourceValues = try url.resourceValues(forKeys: Set(resourceValueKeys))
        return VolumeInfo(url: url, name: resourceValues.name!, resourceValues: resourceValues)
    }
    
    func observeVolumes(onMount: @escaping (VolumeInfo) -> Void,
                        onUnmount: @escaping (URL) -> Void) -> Cancellable? {
        
        return VolumeObserver(onMount: onMount, onUnmount: onUnmount)
    }
    
}

fileprivate class VolumeObserver: Cancellable {
    
    // MARK: - Private Properties
    
    private var onMount: (VolumeInfo) -> Void
    private var onUnmount: (URL) -> Void
    
    
    // MARK: - Initialization
    
    init(onMount: @escaping (VolumeInfo) -> Void,
         onUnmount: @escaping (URL) -> Void) {
        
        self.onMount = onMount
        self.onUnmount = onUnmount
        
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(
            self, selector: #selector(didMount(_:)), name: NSWorkspace.didMountNotification, object: nil)
        notificationCenter.addObserver(
            self, selector: #selector(willUnMount(_:)), name: NSWorkspace.willUnmountNotification, object: nil)
    }
    
    
    // MARK: - Cancellable
    
    func cancel() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    
    // MARK: - Handlers
    
    @objc private func didMount(_ notification: Notification) throws {
        guard
            let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL
        else {
            return
        }
        onMount(try FileManager.default.volume(for: volumeURL))
    }
    
    @objc private func willUnMount(_ notification: Notification) {
        guard
            let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL
        else {
            return
        }
        
        onUnmount(volumeURL)
    }
    
}
