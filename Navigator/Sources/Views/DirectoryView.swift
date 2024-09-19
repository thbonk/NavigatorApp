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
            Table(directoryContents, selection: $selectedFiles, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
                TableColumn("Name", value: \.name) { fileInfo in
                    HStack {
                        fileInfo.icon.resizable().frame(width: 24, height: 24)
                        Text(fileInfo.name)
                    }
                }.customizationID("name-column")
                TableColumn("Created At", value: \.createdAt)
                    .customizationID("created-at-column")
                TableColumn("Modified At", value: \.modifiedAt)
                    .customizationID("modified-at-column")
                TableColumn("Size", value: \.size)
                    .customizationID("size-column")
            }
            .contextMenu(
                forSelectionType: FileInfo.ID.self,
                menu: self.menuForItems(_:),
                primaryAction: self.openItem(_:))
            .onChange(of: sortOrder, self.sortDirectoryContents(oldSortOrder:newSortOrder:))
            
            PathView(path: $path).padding([.horizontal, .bottom], 5)
                .focusable(interactions: [.activate, .automatic, .edit])
        }
        .onAppear(perform: self.registerCommands)
        .onAppear(perform: self.loadDirectoryContents)
        .onChange(of: path, self.loadDirectoryContents)
        .navigationTitle(path.removingPercentEncoding ?? path)
        .alert(isPresented: $showQuestionAlert) {
            Alert(
                title: questionAlertTitle,
                message: questionAlertMessage,
                primaryButton: questionAlertPrimaryButton,
                secondaryButton: questionAlertSecondaryButton)
        }
    }
    
    @Binding
    public var path: String
    
    
    // MARK: - Private Properties
    
    @AppStorage("DirectoryView.columnCustomization")
    private var columnCustomization: TableColumnCustomization<FileInfo>
    
    @State
    private var selectedFiles = Set<FileInfo.ID>()
    
    private var selectedFileInfos: [FileInfo] {
        self.directoryContents
            .filter { fileInfo in self.selectedFiles.contains(ObjectIdentifier(fileInfo)) }
    }
    
    @State 
    private var sortOrder = [
        KeyPathComparator(\FileInfo.name),
        KeyPathComparator(\FileInfo.modifiedAt),
        KeyPathComparator(\FileInfo.createdAt),
        KeyPathComparator(\FileInfo.size)
    ]
    
    @State
    private var directoryContents: [FileInfo] = []
    
    @State
    private var directoryObserver: Cancellable?
    
    @State
    private var showQuestionAlert: Bool = false
    @State
    private var questionAlertTitle: Text!
    @State
    private var questionAlertMessage: Text!
    @State
    private var questionAlertPrimaryButton: Alert.Button!
    @State
    private var questionAlertSecondaryButton: Alert.Button!
    
    
    @EnvironmentObject
    private var eventBus: Causality.Bus
    
    @EnvironmentObject
    private var commandRegistry: CommandRegistry
    
    @EnvironmentObject
    private var pasteboard: Pasteboard
    
    @Environment(\.openWindow)
    private var openWindow
    
    
    // MARK: - Private Methods
    
    private func registerCommands() {
        commandRegistry.add(command: Command(
            Shortcut(.upArrow, modifiers: [.command]), title: "Go up", action: self.goUp))
        commandRegistry.add(command: Command(
            Shortcut("c", modifiers: [.command]), title: "Copy", action: self.copySelectedFiles))
        commandRegistry.add(command: Command(
            Shortcut("x", modifiers: [.command]), title: "Cut", action: self.cutSelectedFiles))
        commandRegistry.add(command: Command(
            Shortcut("v", modifiers: [.command]), title: "Paste", action: self.pasteFiles))
        commandRegistry.add(command: Command(
            Shortcut(.delete, modifiers: []), title: "Move to Trash", action: self.deleteSelectedFiles))
        commandRegistry.add(command: Command(
            Shortcut(.delete, modifiers: [.option]), title: "Delete", action: self.deleteSelectedFilesFinally))
        commandRegistry.add(command: Command(
            Shortcut("r", modifiers: [.command]), title: "Refresh", action: self.loadDirectoryContents))
    }
    
    private func loadDirectoryContents() {
        Task {
            await loadDirectoryContentsAsync()
        }
    }
    
    private func loadDirectoryContentsAsync() async {
        self.directoryObserver?.cancel()
        
        if FileManager.default.isReadableFile(atPath: path) {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: path, withHiddenFiles: false) {
                directoryContents.removeAll()
                
                let filesInPasteboard = Set(self.pasteboard.readObjects(asType: FileInfo.self).map({ $0.url }))
                
                directoryContents.append(contentsOf: contents.filter({ fi in
                    if self.pasteboard.operation == .cut {
                        return !filesInPasteboard.contains(fi.url)
                    }
                    return true
                }))
            }
            
            self.directoryObserver = FileManager
                .default
                .observeDirectory(self.path.fileUrl, callback: self.loadDirectoryContents)
        } else {
            // TODO Show error: No access or file does not exist.
            path = path.deletingLastPathComponent
        }
    }
    
    private func sortDirectoryContents(oldSortOrder: [KeyPathComparator<FileInfo>],
                                       newSortOrder: [KeyPathComparator<FileInfo>]) {
        
        directoryContents.sort(using: newSortOrder)
    }
    
    @ViewBuilder private func menuForItems(_ ids: Set<FileInfo.ID>) -> some View {
        EmptyView()
    }
    
    private func showQuestion(
        title: Text,
        message: Text? = nil,
        primaryButton: Alert.Button,
        secondaryButton: Alert.Button) {
        
        self.questionAlertTitle = title
        self.questionAlertMessage = message
        self.questionAlertPrimaryButton = primaryButton
        self.questionAlertSecondaryButton = secondaryButton
        self.showQuestionAlert = true
    }
    
    
    // MARK: - Action Handlers
    
    private func openItem(_ ids: Set<FileInfo.ID>) {
        let severalDirectoriesSelected = directoryContents
            .filter { fileInfo in ids.contains(ObjectIdentifier(fileInfo)) }
            .filter { fileInfo in fileInfo.isDirectory }
            .count > 1
        directoryContents
            .filter { fileInfo in ids.contains(ObjectIdentifier(fileInfo)) }
            .forEach { fileInfo in
                let tempPath = path.appendingPathComponent(fileInfo.name)
                
                if fileInfo.isDirectory && !fileInfo.isApplication {
                    if severalDirectoriesSelected {
                        openWindow(id: "navigator.view", value: tempPath)
                    } else {
                        self.path = tempPath
                    }
                } else {
                    NSWorkspace.shared.open(path.appendingPathComponent(fileInfo.name).fileUrl)
                }
            }
    }
    
    private func goUp() {
        self.path = self.path.deletingLastPathComponent
    }
    
    private func copySelectedFiles() {
        if !self.selectedFiles.isEmpty {
            self.pasteboard.writeObjects(self.selectedFileInfos, operation: .copy)
        }
    }
    
    private func cutSelectedFiles() {
        if !self.selectedFiles.isEmpty {
            self.pasteboard.writeObjects(self.selectedFileInfos, operation: .cut)
            self.loadDirectoryContents()
        }
    }
    
    private func pasteFiles() {
        let fileInfos = self.pasteboard.readObjects(asType: FileInfo.self)
        
        fileInfos.forEach { fileInfo in
            do {
                switch self.pasteboard.operation {
                case .copy:
                    try FileManager
                        .default
                        .copyItem(
                            at: fileInfo.url,
                            to: self.path.appendingPathComponent(fileInfo.name).fileUrl)
                    break
                    
                case .cut:
                    try FileManager
                        .default
                        .moveItem(
                            at: fileInfo.url,
                            to: self.path.appendingPathComponent(fileInfo.name).fileUrl)
                    self.pasteboard.clear()
                    break
                    
                default:
                    break
                }
                
            } catch {
                // TODO error handling
            }
        }
    }
    
    private func deleteSelectedFiles() {
        self.showQuestion(
            title: Text("Do you want to move the selected files to the bin?"),
            primaryButton: .default(Text("Yes"), action: {
                let fileManager = FileManager.default
                
                self.selectedFileInfos
                    .forEach { fileInfo in
                        try? fileManager.trashItem(at: fileInfo.url, resultingItemURL: nil)
                    }
                
                self.loadDirectoryContents()
            }), secondaryButton: .cancel())
    }
    
    private func deleteSelectedFilesFinally() {
        self.showQuestion(
            title: Text("Do you want to delete the selected files?"),
            message: Text("There is no undo!"),
            primaryButton: .default(Text("Yes"), action: {
                let fileManager = FileManager.default
                
                self.selectedFileInfos
                    .forEach { fileInfo in
                        try? fileManager.removeItem(at: fileInfo.url)
                    }
                
                self.loadDirectoryContents()
            }), secondaryButton: .cancel())
    }
}
