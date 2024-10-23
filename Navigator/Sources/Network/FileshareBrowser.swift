//
//  FileshareBrowser.swift
//  Navigator
//
//  Created by Thomas Bonk on 19.10.24.
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
import Foundation

@objc class FileshareBrowser: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    
    // MARK: - Public Static Properties
    
    public static let shared: FileshareBrowser = {
        .init()
    }()
    
    
    // MARK: - Public Properties
    
    public private(set) var services: Set<NetService> = []
    
    
    // MARK: - Private Properties
    
    private var eventBus: Causality.Bus!
    
    private var smbBrowser = NetServiceBrowser()
    private var afpBrowser = NetServiceBrowser()
    private var discoveredServices: Set<NetService> = []
    
    
    // MARK: - Public Methods
    
    public func start(eventBus: Causality.Bus) {
        self.eventBus = eventBus
        
        self.smbBrowser.delegate = self
        self.smbBrowser.searchForServices(ofType: "_smb._tcp.", inDomain: "")
        
        self.afpBrowser.delegate = self
        self.afpBrowser.searchForServices(ofType: "_afpovertcp._tcp.", inDomain: "")
    }
    
    
    // MARK: - NetServiceBrowserDelegate
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        service.resolve(withTimeout: 10)
        self.discoveredServices.insert(service)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        Events.fileshareRemoved(eventBus: self.eventBus, service)
        self.services.remove(service)
    }
    
    
    // MARK: - NetServiceDelegate
    
    func netServiceDidResolveAddress(_ service: NetService) {
        self.services.insert(service)
        self.discoveredServices.remove(service)
        
        Events.fileshareFound(eventBus: self.eventBus, service)
    }
    
}
