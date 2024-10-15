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

class DirectoryViewController: NSViewController, NSTableViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet private var tableView: DirectoryTableView!
    @IBOutlet private var tableViewDataSource: DirectoryViewTableDataSource!
    @IBOutlet private var pathControl: NSPathControl!
    
    private var progressIndicator: NSProgressIndicator!
    
    
    // MARK: - Private Properties
    
    @objc private dynamic var path: URL?
    
    private var fileOperationsQueue = FileOperationsQueue()
    
    private var reloadDirectoryContentsSubscription: Commands.ReloadDirectoryContentsSubscription?
    private var showOrHideHiddenFilesSubscription: Commands.ShowOrHideHiddenFilesSubscription?
    private var pathChangedSubscription: Events.PathChangedSubscription?
    private var moveSelectedFilesToBinSubscription: Commands.MoveSelectedFilesToBinSubscription?
    
    private var directoryOberverCancellable: Cancellable?
    
    private let cellViewPopulators: [String: (FileInfo, NSTableCellView) -> Void] = [
        "name": populateName,
        "creationDate": populateCreationDate,
        "modificationDate": populateModificationDate,
        "accessDate": populateAccessDate,
        "fileSize": populateFileSize
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
        
        self.reloadDirectoryContentsSubscription = self.eventBus!.subscribe(Commands.ReloadDirectoryContents, handler: self.reloadDirectoryContentsSubscription)
        self.showOrHideHiddenFilesSubscription = self.eventBus!.subscribe(Commands.ShowOrHideHiddenFiles, handler: self.showOrHideHiddenFiles)
        self.pathChangedSubscription = self.eventBus!.subscribe(Events.PathChanged, handler: self.pathChanged)
        self.moveSelectedFilesToBinSubscription = self.eventBus!.subscribe(Commands.MoveSelectedFilesToBin, handler: self.moveSelectedFilesToBin)
        self.restoreColumnWidths()
    }
    
    override func viewWillDisappear() {
        self.reloadDirectoryContentsSubscription?.unsubscribe()
        self.showOrHideHiddenFilesSubscription?.unsubscribe()
        self.pathChangedSubscription?.unsubscribe()
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
            let view = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
            
            self.cellViewPopulators[columnIdentifier.rawValue]?(fileInfo, view)
            
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
    
    
    // MARK: - Event Handlers
    
    private func reloadDirectoryContentsSubscription(message: Causality.NoMessage) {
        self.tableViewDataSource.reloadDirectoryContents()
        self.tableView.reloadData()
    }
    
    private func showOrHideHiddenFiles(command: Causality.NoMessage) {
        var shouldShowHiddenFiles = UserDefaults.standard.bool(forKey: "shouldShowHiddenFiles")
        shouldShowHiddenFiles.toggle()
        UserDefaults.standard.set(shouldShowHiddenFiles, forKey: "shouldShowHiddenFiles")
        self.tableViewDataSource.reloadDirectoryContents()
        self.tableView.reloadData()
    }
    
    private func pathChanged(message: PathChangedMessage) {
        self.directoryOberverCancellable?.cancel()
        
        self.path = message.path.fileUrl
        if let path {
            self.directoryOberverCancellable = FileManager.default.observeDirectory(path, handler: self.reloadDirectoryContents)
        }
        self.tableViewDataSource.path = message.path
        self.tableView.reloadData()
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
            NSBeep()
            return
        }
        
        guard
            self.tableView.selectedRowIndexes.count > 0
        else {
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
    
}
