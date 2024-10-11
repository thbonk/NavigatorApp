//
//  FileManager+attributesOfItem.swift
//  Navigator
//
//  Created by Thomas Bonk on 09.10.24.
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

extension FileAttributeKey {
    
    static var ownerAccountName: FileAttributeKey { .init(rawValue: "ownerAccountName") }
    static var groupOwnerAccountName: FileAttributeKey { .init(rawValue: "groupOwnerAccountName") }
    static var accessRights: FileAttributeKey { .init(rawValue: "accessRights") }
    static var readableAccessRights: FileAttributeKey { .init(rawValue: "readableAccessRights") }
}

extension FileManager {
    
    func attributesOfItem(at url: URL) throws -> [FileAttributeKey : Any] {
        return try attributesOfItem(at: url.path)
    }
    
    func attributesOfItem(at path: String) throws -> [FileAttributeKey : Any] {
        var attributes = try FileManager.default.attributesOfItem(atPath: path)
                
        // Get the owner and group as numeric IDs
        attributes[.ownerAccountID] = (attributes[.ownerAccountID] as? Int) ?? -1
        attributes[.groupOwnerAccountID] = (attributes[.groupOwnerAccountID] as? Int) ?? -1
        
        // Get the owner and group names using POSIX functions
        attributes[.ownerAccountName] = getUserName(from: attributes[.ownerAccountID] as! Int)
        attributes[.groupOwnerAccountName] = getGroupName(from: attributes[.groupOwnerAccountID] as! Int)
        
        // Step 2: Get access rights using the 'stat' system call
        attributes[.accessRights] = 0
        attributes[.readableAccessRights] = "---------"
        var fileStat = stat()
        if stat(path, &fileStat) == 0 {
            attributes[.accessRights] = fileStat.st_mode & 0o777  // File permissions as numeric (e.g., 0755)
            attributes[.readableAccessRights] = permissionStringFromMode(fileStat.st_mode) // File permissions as string
        }
        
        return attributes
    }
}

// Helper function to get the owner name from UID
fileprivate func getUserName(from uid: Int) -> String {
    let pwd = getpwuid(uid_t(uid))
    
    if let pwd = pwd, let name = pwd.pointee.pw_name {
        return String(cString: name)
    }
    
    return "unknown"
}

// Helper function to get the group name from GID
fileprivate func getGroupName(from gid: Int) -> String {
    let grp = getgrgid(gid_t(gid))
    
    if let grp = grp, let name = grp.pointee.gr_name {
        return String(cString: name)
    }
    
    return "unknown"
}

// Helper function to convert the file mode into a permission string (e.g., rwxr-xr-x)
fileprivate func permissionStringFromMode(_ mode: mode_t) -> String {
    let ownerPermissions = [
        (mode & S_IRUSR != 0) ? "r" : "-",
        (mode & S_IWUSR != 0) ? "w" : "-",
        (mode & S_IXUSR != 0) ? "x" : "-"
    ].joined()
    
    let groupPermissions = [
        (mode & S_IRGRP != 0) ? "r" : "-",
        (mode & S_IWGRP != 0) ? "w" : "-",
        (mode & S_IXGRP != 0) ? "x" : "-"
    ].joined()
    
    let othersPermissions = [
        (mode & S_IROTH != 0) ? "r" : "-",
        (mode & S_IWOTH != 0) ? "w" : "-",
        (mode & S_IXOTH != 0) ? "x" : "-"
    ].joined()
    
    return ownerPermissions + groupPermissions + othersPermissions
}
