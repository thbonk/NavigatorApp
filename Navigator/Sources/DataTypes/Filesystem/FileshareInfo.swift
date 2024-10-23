//
//  FileshareInfo.swift
//  Navigator
//
//  Created by Thomas Bonk on 20.10.24.
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

class FileshareInfo: FilesystemEntry {
    
    // MARK: - Public Properties
    
    let url: URL
    let hostname: String
    
    
    // MARK: - Initialization
    
    init(url: URL, hostname: String) {
        
        self.url = url
        self.hostname = hostname
        
        super.init(path: hostname)
    }
}
