//
//  DirectoryView.swift
//  Navigator
//
//  Created by Thomas Bonk on 08.09.24.
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
import Combine
import SwiftUI

struct DirectoryView: View {
    
    // MARK: - Public Properties
    
    var body: some View {
        VStack {
            Table(directoryContents, selection: $selectedFiles, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name) { fileInfo in
                    HStack {
                        fileInfo.icon.resizable().frame(width: 24, height: 24)
                        Text(fileInfo.name)
                    }
                }
                TableColumn("Created At", value: \.createdAt)
                TableColumn("Modified At", value: \.modifiedAt)
                TableColumn("Size", value: \.size)
            }
            .contextMenu(forSelectionType: FileInfo.ID.self, menu: { ids in
                //self.menuForItems(ids)
            }, primaryAction: { ids in
                self.openItem(ids)
            })
            .onChange(of: sortOrder) { _, sortOrder in
                directoryContents.sort(using: sortOrder)
            }
            PathView(path: $path).padding([.horizontal, .bottom], 5)
        }
        .onAppear {
            loadDirectoryContents()
        }
        .onChange(of: path, self.loadDirectoryContents)
        .navigationTitle(path.removingPercentEncoding ?? path)
    }
    
    @Binding
    public var path: String
    
    
    // MARK: - Private Properties
    
    @State
    private var selectedFiles = Set<FileInfo.ID>()
    
    @State 
    private var sortOrder = [
        KeyPathComparator(\FileInfo.name),
        KeyPathComparator(\FileInfo.createdAt),
        KeyPathComparator(\FileInfo.modifiedAt),
        KeyPathComparator(\FileInfo.size)
    ]
    
    @State
    private var directoryContents: [FileInfo] = []
    
    @EnvironmentObject
    private var eventBus: Causality.Bus
    
    @Environment(\.openWindow)
    private var openWindow
    
    
    // MARK: - Private Methods
    
    private func loadDirectoryContents() {
        Task {
            await loadDirectoryContentsAsync()
        }
    }
    
    private func loadDirectoryContentsAsync() async {
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: path, withHiddenFiles: false) {
            directoryContents.removeAll()
            directoryContents.append(contentsOf: contents)
        }
    }
    
    private func menuForItems(_ ids: Set<FileInfo.ID>) {
        
    }
    
    private func openItem(_ ids: Set<FileInfo.ID>) {
        let severalDirectoriesSelected = directoryContents
            .filter { fileInfo in ids.contains(ObjectIdentifier(fileInfo)) }
            .filter { fileInfo in fileInfo.isDirectory }
            .count > 1
        directoryContents
            .filter { fileInfo in ids.contains(ObjectIdentifier(fileInfo)) }
            .forEach { fileInfo in
                let tempPath = path.appendingPathComponent(fileInfo.name)
                
                if fileInfo.isDirectory {
                    if severalDirectoriesSelected {
                        openWindow(id: "navigator.view", value: tempPath)
                    } else {
                        path = tempPath
                    }
                } else {
                    NSWorkspace.shared.open(path.appendingPathComponent(fileInfo.name).fileUrl)
                }
            }
    }
}
