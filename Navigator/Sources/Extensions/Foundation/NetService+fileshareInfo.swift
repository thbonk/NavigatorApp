//
//  NetService+fileshareInfo.swift
//  Navigator
//
//  Created by Thomas Bonk on 23.10.24.
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

extension NetService {
    
    public enum ServiceType: RawRepresentable {
        
        // MARK: - Cases
        
        case smb
        case afp
        case other
        
        
        // MARK: - RawRepresentable
        
        public init?(rawValue: String) {
            switch rawValue {
            case "_smb._tcp.":
                self = .smb
                break
                
            case "_afpovertcp._tcp.":
                self = .afp
                break
                
            default:
                self = .other
                break
            }
        }
        
        public var rawValue: String {
            switch self {
            case .afp:
                return "_afpovertcp._tcp."
            case.smb:
                return "_smb._tcp."
            case .other:
                return ""
            }
        }
        
        
        // MARK: - Public Properties
        
        public var scheme: String {
            switch self {
            case .afp:
                return "afp"
            case.smb:
                return "smb"
            case .other:
                return ""
            }
        }
        
    }
    
    var fileshareInfo: FileshareInfo {
        let type = ServiceType(rawValue: self.type)!
        
        return FileshareInfo(url: URL(string: "\(type.scheme)://\(self.hostName!)")!, hostname: self.hostName!)
    }
}
