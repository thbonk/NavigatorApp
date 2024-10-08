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

import Combine
import DiskArbitration
import Foundation

extension FileManager {
    
    func mountedVolumes() throws -> [VolumeInfo] {
        var result = [VolumeInfo]()
        let resourceValueKeys: [URLResourceKey] = [
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
        
        if let volumes = self.mountedVolumeURLs(
            includingResourceValuesForKeys: resourceValueKeys,
            options: .skipHiddenVolumes) {
            
            try volumes.forEach { url in
                let resourceValues = try url.resourceValues(forKeys: Set(resourceValueKeys))
                result.append(
                    VolumeInfo(
                        url: url,
                        name: resourceValues.name!,
                        resourceValues: resourceValues)
                )
            }
        }
        
        return result
    }
    
    func observeVolumes(onChange: @escaping ([VolumeInfo]) -> Void) -> Cancellable? {
        return VolumeMonitor {
            // TODO error handling
            if let volumes = try? self.mountedVolumes() {
                onChange(volumes)
            }
        }
    }
    
}

fileprivate func invokeCallback(context: UnsafeMutableRawPointer?) {
    guard
        let context = context
    else {
        return
    }
    let volumeMonitor = Unmanaged<VolumeMonitor>.fromOpaque(context).takeUnretainedValue()
    
    volumeMonitor.callback()
}

fileprivate class VolumeMonitor: Cancellable {
    
    // MARK: - Private Properties
    
    private var session: DASession!
    fileprivate var callback: () -> Void
    
    
    // MARK: - Initialization
    
    init(callback: @escaping () -> Void) {
        // Create a Disk Arbitration session
        session = DASessionCreate(kCFAllocatorDefault)
        self.callback = callback
        
        // Register for volume mount events
        DARegisterDiskAppearedCallback(session, nil, { _, context in
            invokeCallback(context: context)
        }, nil)
        
        // Register for volume unmount events
        DARegisterDiskDisappearedCallback(session, nil, { _, context in
            invokeCallback(context: context)
        }, nil)
        
        // Schedule the session in the run loop
        DASessionScheduleWithRunLoop(session, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    }
    
    func cancel() {
        DASessionUnscheduleFromRunLoop(session, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    }
}
