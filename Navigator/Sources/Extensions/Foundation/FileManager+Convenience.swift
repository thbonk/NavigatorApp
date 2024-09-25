//
//  FileManager+ConvenienceMethods.swift
//  Navigator
//
//  Created by Thomas Bonk on 11.09.24.
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
import SwiftUI

extension FileManager {
    
    var userHomeDirectoryPath: String {
        let pw = getpwuid(getuid())
        let home = pw?.pointee.pw_dir
        let homePath = FileManager.default.string(withFileSystemRepresentation: home!, length: Int(strlen(home!)))

        return homePath
    }
    
    var userHomeDirectory: FileInfo {
        let path = userHomeDirectoryPath
        let icon = Image(nsImage: NSWorkspace.shared.icon(forFile: path))
        
        return FileInfo(parent: path.deletingLastPathComponent,
                        name: path.lastPathComponent,
                        icon: icon,
                        isDirectory: true,
                        createdAt: "",
                        modifiedAt: "",
                        sizeInBytes: 0)
    }
    
    var userDocumentDirectoryPath: String {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path
    }
    
    var userDocumentDirectory: FileInfo {
        let path = userDocumentDirectoryPath
        let icon = Image(nsImage: NSWorkspace.shared.icon(forFile: path))
        
        return FileInfo(parent: path.deletingLastPathComponent,
                        name: path.lastPathComponent,
                        icon: icon,
                        isDirectory: true,
                        createdAt: "",
                        modifiedAt: "",
                        sizeInBytes: 0)
    }
    
    func isDirectory(path: String) -> Bool {
        var isDir: ObjCBool = false
        
        self.fileExists(atPath: path, isDirectory: &isDir)
        
        return isDir.boolValue
    }
    
    func isApplicationBundle(path: String) -> Bool {
        return isDirectory(path: path) && path.hasSuffix("app")
    }
}
