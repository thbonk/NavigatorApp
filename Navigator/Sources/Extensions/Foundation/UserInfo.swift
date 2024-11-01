//
//  UserInfo.swift
//  Navigator
//
//  Created by Thomas Bonk on 29.10.24.
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

class UserInfo {
    
    // MARK: - Public Structs
    
    public struct Group: Codable, Identifiable {
        let name: String
        let id: UInt32
    }
    
    public struct User: Codable, Identifiable, Hashable {
        
        // MARK: - Properties
        
        let name: String
        let id: UInt32
        let group: Group
        
        
        // MARK: - Hashable
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(self.id)
        }
        
        public static func == (lhs: UserInfo.User, rhs: UserInfo.User) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    
    // MARK: - Public Static Properties
    
    public static var shared: UserInfo = {
        UserInfo()
    }()
    
    
    // MARK: - Public Properties
    
    public var allGroups: [Group] {
        var groups = [Group]()
        var grpPointer = getgrent()  // Start with the first group entry

        while let grp = grpPointer {
            if let groupName = String(validatingUTF8: grp.pointee.gr_name) {
                groups.append(Group(name: groupName, id: grp.pointee.gr_gid))
            }
            grpPointer = getgrent()  // Move to the next group entry
        }
        
        endgrent()
        
        return groups
    }
    
    public var allUsers: [User] {
        var users = Set<User>()
        
        // Initialize the user database to start enumeration
        setpwent()
        
        while let passwdEntry = getpwent() {
            // Retrieve the username and userID
            guard let username = String(validatingUTF8: passwdEntry.pointee.pw_name) else {
                continue
            }
            
            let userID = passwdEntry.pointee.pw_uid
            let groupID = passwdEntry.pointee.pw_gid
            
            // Retrieve the primary group name for the user's group ID
            var groupname = "Unknown"
            if let groupEntry = getgrgid(groupID),
               let validGroupName = String(validatingUTF8: groupEntry.pointee.gr_name) {
                
                groupname = validGroupName
            }
            
            // Create a UnixUser instance and add it to the list
            users.insert(User(name: username, id: userID, group: Group(name: groupname, id: groupID)))
        }
        
        // Close the user database
        endpwent()
        
        return Array(users)
    }
    
    
    // MARK: - Initialization
    
    private init() {
        // Empty by design
    }
    
}
