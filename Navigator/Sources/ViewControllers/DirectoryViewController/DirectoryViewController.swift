//
//  DirectoryViewController.swift
//  Navigator
//
//  Created by Thomas Bonk on 02.10.24.
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
import Causality
import Combine
import UniformTypeIdentifiers

class DirectoryViewController: NSViewController, NSTableViewDelegate, NSTextFieldDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet private var tableView: DirectoryTableView!
    @IBOutlet private var tableViewDataSource: DirectoryViewTableDataSource!
    @IBOutlet private var pathControl: NSPathControl!
    
    
    // MARK: - Private Properties
    
    private var applicationBar: ApplicationBar!
    private var progressIndicator: NSProgressIndicator!
    
    @objc private dynamic var path: URL?
    
    private var fileOperationsQueue: FileOperationsQueue!
    
    private var reloadDirectoryContentsSubscription: Commands.ReloadDirectoryContentsSubscription?
    private var showOrHideHiddenFilesSubscription: Commands.ShowOrHideHiddenFilesSubscription?
    private var pathChangedSubscription: Events.PathChangedSubscription?
    private var moveSelectedFilesToBinSubscription: Commands.MoveSelectedFilesToBinSubscription?
    private var deleteSelectedFilesSubscription: Commands.DeleteSelectedFilesSubscription?
    private var renameSelectedFileSubscription: Commands.RenameSelectedFileSubscription?
    private var pasteFilesSubscription: Commands.PasteFilesSubscription?
    private var copyFilesSubscription: Commands.CopyFilesSubscription?
    private var cutFilesSubscription: Commands.CutFilesSubscription?
    private var showFileInfosSubscription: Commands.ShowFileInfosSubscription?
    private var navigateToParentSubscription: Commands.NavigateToParentSubscription?
    private var showApplicationBarSubscription: Commands.ShowApplicationBarSubscription?
    private var createNewFilesystemEntrySubscription: Commands.CreateNewFilesystemEntrySubscription?
    
    private var directoryOberverCancellable: Cancellable?
    
    private let cellViewPopulators: [String: (FileInfo, NSTableCellView) -> Void] = [
        "name": populateName,
        "creationDate": populateCreationDate,
        "modificationDate": populateModificationDate,
        "accessDate": populateAccessDate,
        "fileSize": populateFileSize,
        "owner": populateOwner,
        "group": populateGroup,
        "permissions": populatePermissions
    ]
        
    
    
    // MARK: - NSViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupProgressIndicator()
        
        self.tableView.actionTarget = self
        self.tableView.actionSelector = #selector(self.onAction(_:))
        
        // Accept file promises from apps like Safari.
        tableView.registerForDraggedTypes(
            NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        
        tableView.registerForDraggedTypes([
            .fileURL // Accept dragging of image file URLs from other apps.
        ])
        // Determine the kind of source drag originating from this app.
        // Note, if you want to allow your app to drag items to the Finder's trash can, add ".delete".
        tableView.setDraggingSourceOperationMask([.copy, .delete, .link, .move], forLocal: false)
        
        self.setupHeaderMenu()
        self.tableView.sizeToFit()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.applicationBar = ApplicationBar.create(with: self.view.window!)
        
        self.fileOperationsQueue = FileOperationsQueue(eventBus: self.eventBus!)
        
        self.reloadDirectoryContentsSubscription = self.eventBus!.subscribe(Commands.ReloadDirectoryContents, handler: self.reloadDirectoryContents)
        self.showOrHideHiddenFilesSubscription = self.eventBus!.subscribe(Commands.ShowOrHideHiddenFiles, handler: self.showOrHideHiddenFiles)
        self.pathChangedSubscription = self.eventBus!.subscribe(Events.PathChanged, handler: self.pathChanged)
        self.moveSelectedFilesToBinSubscription = self.eventBus!.subscribe(Commands.MoveSelectedFilesToBin, handler: self.moveSelectedFilesToBin)
        self.deleteSelectedFilesSubscription = self.eventBus!.subscribe(Commands.DeleteSelectedFiles, handler: self.deleteSelectedFiles)
        self.renameSelectedFileSubscription = self.eventBus!.subscribe(Commands.RenameSelectedFile, handler: self.renameSelectedFile)
        self.pasteFilesSubscription = self.eventBus!.subscribe(Commands.PasteFiles, handler: self.pasteFiles)
        self.copyFilesSubscription = self.eventBus!.subscribe(Commands.CopyFiles, handler: self.copyFiles)
        self.cutFilesSubscription = self.eventBus!.subscribe(Commands.CutFiles, handler: self.cutFiles)
        self.showFileInfosSubscription = self.eventBus!.subscribe(Commands.ShowFileInfos, handler: self.showFileInfos)
        self.navigateToParentSubscription = self.eventBus!.subscribe(Commands.NavigateToParent, handler: self.navigateToParent)
        self.showApplicationBarSubscription = self.eventBus!.subscribe(Commands.ShowApplicationBar, handler: self.showApplicationBar)
        self.createNewFilesystemEntrySubscription = self.eventBus!.subscribe(Commands.CreateNewFilesystemEntry, handler: self.createNewFilesystemEntry)
        
        self.restoreColumnWidths()
    }
    
    override func viewWillDisappear() {
        self.reloadDirectoryContentsSubscription?.unsubscribe()
        self.showOrHideHiddenFilesSubscription?.unsubscribe()
        self.pathChangedSubscription?.unsubscribe()
        self.moveSelectedFilesToBinSubscription?.unsubscribe()
        self.deleteSelectedFilesSubscription?.unsubscribe()
        self.renameSelectedFileSubscription?.unsubscribe()
        self.pasteFilesSubscription?.unsubscribe()
        self.copyFilesSubscription?.unsubscribe()
        self.cutFilesSubscription?.unsubscribe()
        self.showFileInfosSubscription?.unsubscribe()
        self.navigateToParentSubscription?.unsubscribe()
        self.showApplicationBarSubscription?.unsubscribe()
        self.createNewFilesystemEntrySubscription?.unsubscribe()
        
        self.storeColumnWidths()
        
        super.viewWillDisappear()
    }
    
    
    // MARK: - NSTableViewDelegate
    
    @MainActor
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        
        if let columnIdentifier = tableColumn?.identifier,
           row < self.tableViewDataSource.directoryContents.count {
            
            let fileInfo = self.tableViewDataSource.directoryContents[row]
            let view = tableView.makeView(withIdentifier: columnIdentifier, owner: self) as! NSTableCellView
            
            self.cellViewPopulators[columnIdentifier.rawValue]?(fileInfo, view)
            
            if columnIdentifier.rawValue == "name" {
                view.textField?.delegate = self
            }
            
            return view
        }
        
        return nil
    }
    
    @MainActor
    func tableViewSelectionDidChange(_ notification: Notification) {
        if self.tableView!.selectedRow >= 0 && self.tableView!.selectedRowIndexes.count == 1 {
            Events.selectedFileChanged(eventBus: self.eventBus!,
                                       self.tableViewDataSource.directoryContents[self.tableView!.selectedRow])
        } else {
            var selectedFiles: [FileInfo] = []
            
            self.tableView!.selectedRowIndexes.forEach { index in
                selectedFiles.append(self.tableViewDataSource.directoryContents[index])
            }
            
            Events.selectedFilesChanged(eventBus: self.eventBus!, selectedFiles)
        }
    }
    
    
    // MARK: - NSTableView Actions
    
    @IBAction
    @objc private func onDoubleClick(_ sender: NSTableView) {
        if tableView.selectedRow >= 0 && tableView.selectedRowIndexes.count == 1 {
            onAction(tableView)
            return
        }
    }
    
    
    @IBAction
    @objc private func onAction(_ tableView: NSTableView) {
        if tableView.selectedRow >= 0 && tableView.selectedRowIndexes.count == 1 {
            let fileInfo = self.tableViewDataSource.directoryContents[tableView.selectedRow]
            
            performAction(for: fileInfo)
        }
    }
    
    
    // MARK: - NSTextFieldDelegate
    
    // NSTextFieldDelegate method called when the user finishes editing
    func controlTextDidEndEditing(_ notification: Notification) {
        if let textField = notification.object as? NSTextField {
            let row = self.tableView.row(for: textField)
            let fileInfo = self.tableViewDataSource.directoryContents[row]
            let newPath = fileInfo.url.deletingLastPathComponent().appendingPathComponent(textField.stringValue)
            
            guard
                fileInfo.url.standardizedFileURL != newPath.standardizedFileURL
            else {
                return
            }
            
            do {
                try FileManager.default.moveItem(at: fileInfo.url, to: newPath)
                Commands.reloadDirectoryContents(eventBus: self.eventBus!)
            } catch let error {
                Commands.showErrorAlert(window: self.view.window!,
                                        title: "Can't rename file to \(newPath.lastPathComponent)",
                                        error: error)
            }
        }
    }
    
    
    // MARK: - Event Handlers
    
    private func reloadDirectoryContents(message: Causality.NoMessage) {
        DispatchQueue.main.async {
            self.tableViewDataSource.reloadDirectoryContents()
            self.tableView.reloadData()
        }
    }
    
    private func showOrHideHiddenFiles(command: Causality.NoMessage) {
        DispatchQueue.main.async {
            var shouldShowHiddenFiles = UserDefaults.standard.bool(forKey: "shouldShowHiddenFiles")
            
            shouldShowHiddenFiles.toggle()
            UserDefaults.standard.set(shouldShowHiddenFiles, forKey: "shouldShowHiddenFiles")
            self.tableViewDataSource.reloadDirectoryContents()
            self.tableView.reloadData()
        }
    }
    
    private func pathChanged(message: PathChangedMessage) {
        DispatchQueue.main.async {
            self.directoryOberverCancellable?.cancel()
            
            self.path = message.path.fileUrl
            if let path = self.path {
                self.directoryOberverCancellable = FileManager.default.observeDirectory(path, handler: self.reloadDirectoryContents)
            }
            self.tableViewDataSource.path = message.path
            self.tableView.reloadData()
        }
    }
    
    private func reloadDirectoryContents() {
        self.tableViewDataSource.reloadDirectoryContents()
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func moveSelectedFilesToBin(message: Causality.NoMessage) {
        guard
            self.tableView.hasFocus
        else {
            return
        }
        
        guard
            self.tableView.selectedRowIndexes.count > 0
        else {
            NSBeep()
            return
        }
        
        NSAlert.question(for: self.view.window!,
                         messageText: "Do you really want to move the selected files to the Bin?",
                         informativeText: "You can always restore them later.",
                         buttons: [
                            (title: "No", action: {
                                // Empty by design
                            }),
                            (title: "Yes", action: {
                                self.fileOperationsQueue.enqueueMoveToBinOperations(
                                    self.tableView
                                        .selectedRowIndexes
                                        .map { self.tableViewDataSource.directoryContents[$0] }
                                )
                            })
                         ])
    }
    
    private func deleteSelectedFiles(message: Causality.NoMessage) {
        guard
            self.tableView.hasFocus
        else {
            return
        }
        
        guard
            self.tableView.selectedRowIndexes.count > 0
        else {
            NSBeep()
            return
        }
        
        NSAlert.question(for: self.view.window!,
                         messageText: "Do you really want to delete the selected files?",
                         informativeText: "This operation can't be undone!",
                         buttons: [
                            (title: "No", action: {
                                // Empty by design
                            }),
                            (title: "Yes", action: {
                                self.fileOperationsQueue.enqueueDeleteOperations(
                                    self.tableView
                                        .selectedRowIndexes
                                        .map { self.tableViewDataSource.directoryContents[$0] }
                                )
                            })
                         ])
    }
    
    private func renameSelectedFile(message: Causality.NoMessage) {
        guard
            self.tableView.hasFocus
        else {
            return
        }
        
        guard
            self.tableView.selectedRow >= 0 && self.tableView.selectedRowIndexes.count == 1
        else {
            NSBeep()
            return
        }
        
        if let textField = (self.tableView.view(atColumn: 0, row: self.tableView.selectedRow, makeIfNecessary: false) as? NSTableCellView)?.textField {
            self.view.window?.makeFirstResponder(textField)
        } else {
            NSBeep()
        }
    }
    
    private func pasteFiles(message: Causality.NoMessage) {
        // Check for the special type indicating a "cut" (move) operation
        // TODO check how PathFinder provides the URL for cutting it
        let pasteboard = NSPasteboard.general
        let isCutOperation = pasteboard.types?.contains(NSPasteboard.PasteboardType("com.apple.pasteboard.promisedMoveOperation")) ?? false
             
        var paths: [NSString]? = nil
        
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [NSURL] {
            paths = urls.map { NSString(string: $0.path!) }
        } else if let pathStrings = pasteboard.readObjects(forClasses: [NSString.self], options: [.urlReadingFileURLsOnly: true]) as? [NSString] {
            paths = pathStrings
        }
        
        if let paths, let currentPath = self.path {
            do {
                if isCutOperation {
                    self
                        .fileOperationsQueue
                        .enqeueCutOperations(
                            try paths.map {
                                try FileManager.default.fileInfo(from: URL(filePath: $0 as String))
                            },
                            to: currentPath)
                } else {
                    self
                        .fileOperationsQueue
                        .enqeueCopyOperations(
                            try paths.map {
                                try FileManager.default.fileInfo(from: URL(filePath: $0 as String))
                            },
                            to: currentPath)
                }
            } catch let error {
                // TODO error handling
            }
        }
    }
    
    private func copyFiles(memssage: Causality.NoMessage) {
        self.filesToPasteboard(isCut: false)
    }
    
    private func cutFiles(memssage: Causality.NoMessage) {
        self.filesToPasteboard(isCut: true)
    }
    
    private func filesToPasteboard(isCut: Bool) {
        guard
            self.tableView.hasFocus
        else {
            return
        }
        
        guard
            self.tableView.selectedRowIndexes.count > 0
        else {
            NSBeep()
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        var pasteboardTypes: [NSPasteboard.PasteboardType] = [NSPasteboard.PasteboardType("public.file-url")]
        if isCut {
            pasteboardTypes.append(NSPasteboard.PasteboardType("com.apple.pasteboard.promisedMoveOperation"))
        }
        
        pasteboard.declareTypes(pasteboardTypes, owner: self)
        pasteboard.writeObjects(self.tableView.selectedRowIndexes.map {
            self.tableViewDataSource.directoryContents[$0].url as NSURL
        })
    }
    
    private func showFileInfos(message: Causality.NoMessage) {
        guard
            self.tableView.selectedRowIndexes.count > 0
        else {
            NSBeep()
            return
        }
        
        var relativeWindow = self.view.window
        self.tableView.selectedRowIndexes.forEach {
            let fileInfo = self.tableViewDataSource.directoryContents[$0]
            
            relativeWindow = InfoViewWindowController
                .create(fileInfo: fileInfo, relativeTo: relativeWindow)
                .window
        }
    }
    
    private func navigateToParent(message: Causality.NoMessage) {
        if self.path!.path != "/",
            let parentPath = self.path?.deletingLastPathComponent() {
            
            DispatchQueue.main.async {
                Commands.changePath(eventBus: self.eventBus!, parentPath.path)
            }
        }
    }
    
    private func showApplicationBar(message: Causality.NoMessage) {
        guard
            self.tableView.selectedRowIndexes.count > 0
        else {
            NSBeep()
            return
        }
        
        let urls = self.tableView.selectedRowIndexes
            .map { self.tableViewDataSource.directoryContents[$0].url }
        
        self.applicationBar.present(for: urls)
    }
    
    private func createNewFilesystemEntry(message: CreateNewFilesystemEntryMessage) {
        guard
            let newFileentryPath = self.askForFileentryName(directory: message.directory)
        else {
            return
        }
        
        do {
            if message.directory {
                try FileManager.default.createDirectory(at: URL(filePath: newFileentryPath), withIntermediateDirectories: true)
            } else {
                FileManager.default.createFile(atPath: newFileentryPath, contents: Data())
            }
        } catch {
            Commands.showErrorAlert(window: self.view.window!,
                                    title: "Error while creating new \(message.directory ? "directory" : "file")",
                                    error: error)
        }
    }
    
    func askForFileentryName(directory: Bool) -> String? {
        // Create the alert
        let alert = NSAlert()
        alert.messageText = "Create New \(directory ? "Directory" : "File")"
        alert.informativeText = "Please enter the \(directory ? "directory" : "file") name:"
        alert.alertStyle = .informational
        
        // Create a text field and add it to the alert
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = textField
        
        // Add buttons to the alert
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        // Show the alert and capture the response
        var finished = false
        while !finished {
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let filename = textField.stringValue
                let newFileentryPath = self.path!.appendingPathComponent(filename).path
                
                if !FileManager.default.fileExists(atPath: newFileentryPath) {
                    finished = true
                    return newFileentryPath
                }
            } else {
                finished = true
                return nil
            }
        }
    }
    
    
    // MARK: - Private Methods
    
    private func performAction(for fileInfo: FileInfo) {
        if fileInfo.isDirectory && !(fileInfo.isApplication || fileInfo.isPackage) {
            Commands.changePath(eventBus: self.eventBus!, fileInfo.path)
            return
        }
        
        if fileInfo.isAliasFile, let resolvedFileInfo = fileInfo.resolvedAlias {
            performAction(for: resolvedFileInfo)
            return
        }
        
        let url = fileInfo.path.removingPercentEncoding!.fileUrl
        NSWorkspace.shared.open(url)
    }
    
    
    // MARK: - Private UI Related Methods
    
    private func setupProgressIndicator() {
        // Create the progress indicator for asyncronous copies of promised files.
        self.progressIndicator = NSProgressIndicator(frame: NSRect())
        self.progressIndicator.controlSize = .regular
        self.progressIndicator.sizeToFit()
        self.progressIndicator.style = .spinning
        self.progressIndicator.isHidden = true
        self.progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.progressIndicator)
        // Center it to this view controller.
        NSLayoutConstraint.activate([
            self.progressIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            self.progressIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        self.tableViewDataSource.progressIndicator = self.progressIndicator(isVisible:)
    }
    
    private func progressIndicator(isVisible: Bool) {
        if isVisible {
            // Show the progress indicator
            self.progressIndicator.isHidden = false
            self.progressIndicator.startAnimation(self)
        } else {
            // Stop the progress indicator as we are done
            self.progressIndicator.isHidden = true
            self.progressIndicator.stopAnimation(self)
        }
    }
    
    private func storeColumnWidths() {
        var columnWidths: [String : Any] = [:]
        
        for column in self.tableView.tableColumns {
            columnWidths[column.identifier.rawValue] = column.width
        }
        
        UserDefaults.standard.set(columnWidths, forKey: "directoryViewColumnWidth")
    }
    
    private func restoreColumnWidths() {
        if let columnWidths = UserDefaults.standard.dictionary(forKey: "directoryViewColumnWidth") {
            columnWidths.forEach { (id, width) in
                if let column = self.tableView.tableColumns.first(where: { $0.identifier.rawValue == id }) {
                    DispatchQueue.main.async {
                        column.width = width as! CGFloat
                    }
                }
            }
        }
    }
    
    private func setupHeaderMenu() {
        let savedColumns : [String : Any]? = UserDefaults.standard.dictionary(forKey: "directoryViewVisibleColumns")
        let menu = NSMenu()
        
        for col in self.tableView.tableColumns {
            let mi = NSMenuItem(title: col.headerCell.stringValue, action: #selector(toggleColumn(_:)), keyEquivalent: "")
            mi.target = self
            
            if let savedColumns {
                let isVisible = savedColumns[col.identifier.rawValue] as? Bool ?? true
                col.isHidden = !isVisible
            }
            
            mi.state = (col.isHidden ? .off : .on)
            mi.representedObject = col
            
            menu.addItem(mi)
        }
        
        self.tableView.headerView?.menu = menu
    }
    
    @objc private func toggleColumn(_ menu: NSMenuItem) {
        let col = menu.representedObject as! NSTableColumn
        let shouldHide = !col.isHidden
        
        col.isHidden = shouldHide
        
        menu.state = (col.isHidden ? .off : .on)
        
        var cols = [String : Any]()
        for column in self.tableView.tableColumns {
            cols[column.identifier.rawValue] = !column.isHidden
        }
        
        UserDefaults.standard.set(cols, forKey: "directoryViewVisibleColumns")
        
        if shouldHide {
            self.tableView.sizeLastColumnToFit()
        } else {
            self.tableView.sizeToFit()
        }
    }
    
    private class func populateName(_ fileInfo: FileInfo, _ view: NSTableCellView) {
        view.textField?.stringValue = fileInfo.name
        view.imageView?.image = fileInfo.icon
    }
    
    private class func populateCreationDate(_ fileInfo: FileInfo, _ view: NSTableCellView) {
        view.textField?.stringValue = fileInfo.creationDate ?? "?"
    }
    
    private class func populateModificationDate(_ fileInfo: FileInfo, _ view: NSTableCellView) {
        view.textField?.stringValue = fileInfo.modificationDate ?? "?"
    }
    
    private class func populateAccessDate(_ fileInfo: FileInfo, _ view: NSTableCellView) {
        view.textField?.stringValue = fileInfo.accessDate ?? "?"
    }
    
    private class func populateFileSize(_ fileInfo: FileInfo, _ view: NSTableCellView) {
        view.textField?.stringValue = fileInfo.fileSize
    }
    
    private class func populateOwner(_ fileInfo: FileInfo, _ view: NSTableCellView) {
        view.textField?.stringValue = fileInfo.ownerAccountName
    }
    
    private class func populateGroup(_ fileInfo: FileInfo, _ view: NSTableCellView) {
        view.textField?.stringValue = fileInfo.groupOwnerAccountName
    }
    
    private class func populatePermissions(_ fileInfo: FileInfo, _ view: NSTableCellView) {
        view.textField?.stringValue = fileInfo.readableAccessRights
    }
}
