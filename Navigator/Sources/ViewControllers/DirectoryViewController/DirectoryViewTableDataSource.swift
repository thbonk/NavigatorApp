//
//  DirectoryViewTableDataSource.swift
//  Navigator
//
//  Created by Thomas Bonk on 04.10.24.
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

@objc class DirectoryViewTableDataSource: NSObject, NSTableViewDataSource {
    
    // MARK: - Public Properties
    
    public var progressIndicator: ((_ isVisible: Bool) -> Void)?
    
    public var path: String? {
        didSet {
            self.reloadDirectoryContents()
        }
    }
    
    public private(set) var directoryContents: [FileInfo] = []
    
    
    // MARK: - Private Properties
    
    // Queue used for reading and writing file promises.
    private var filePromiseQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()
    
    
    // MARK: - NSTableViewDataSource
    
    @MainActor
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.directoryContents.count
    }
    
    @MainActor
    func tableView(_ tableView: NSTableView,
                   objectValueFor tableColumn: NSTableColumn?,
                   row: Int) -> Any? {
        
        if let columnIdentifier = tableColumn?.identifier,
            row < self.directoryContents.count {
            
            let fileInfo = self.directoryContents[row]
            let mirror = Mirror(reflecting: fileInfo)
            
            let value = mirror
                .children
                .filter {
                    $0.label == columnIdentifier.rawValue
                }.first?.value
            
            return value
        }
        
        return nil
    }
    
    
    // MARK: - NSTableViewDataSource Drag and Drop
    
    // A file in our table is being dragged for this given row,
    // provide the pasteboard writer for this item.
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        /** Return a custom NSFilePromiseProvider.
            Here we provide a custom provider, offering the row to the drag object, and it's URL.
        */
        var provider: FilePromiseProvider
        
        let fileInfo = self.directoryContents[row]
        
        provider = FilePromiseProvider(fileType: UTType.fileURL.identifier, delegate: self)

        // Send over the row number and photo's url dictionary.
        provider.userInfo = [FilePromiseProvider.UserInfoKeys.rowNumberKey: row,
                             FilePromiseProvider.UserInfoKeys.urlKey: fileInfo.url as Any]
        
        return provider
    }
    
    // This method is called when a drag is moved over the table view and before it has been dropped.
    func tableView(_ tableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        var dragOperation: NSDragOperation = []
        
        // We only support dropping items between rows (not on top of a row).
        guard
            dropOperation != .on
        else {
            return dragOperation
        }

        // Drag source came from another app.
        // Search through the array of NSPasteboardItems.
        let pasteboard = info.draggingPasteboard
        
        guard
            let items = pasteboard.pasteboardItems
        else {
            return dragOperation
        }
        
        for item in items {
            let type = NSPasteboard.PasteboardType.fileURL
            
            if item.availableType(from: [type]) != nil {
                // Drag source is coming from another app as a promised file URL
                if NSEvent.modifierFlags.contains(.option) {
                    dragOperation = [.copy]
                } else {
                    dragOperation = [.move]
                }
            }
        }
        
        // Has a drop operation been determined yet?
        if dragOperation == [] {
            // Look for possible URLs we can consume.
            let acceptedTypes = [UTType.fileURL.identifier]
            let options = [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true,
                           NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes: acceptedTypes]
                as [NSPasteboard.ReadingOptionKey: Any]
            let pasteboard = info.draggingPasteboard
            
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) {
                if !urls.isEmpty {
                    if NSEvent.modifierFlags.contains(.option) {
                        dragOperation = [.copy]
                    } else {
                        dragOperation = [.move]
                    }
                }
            }
        }

        return dragOperation
    }
    
    /** Given an NSDraggingInfo from an incoming drag, handle any and all promise drags.
        Note that promise drags can come from any app that offers it (i.e. Safari or Photos).
    */
    func handlePromisedDrops(draggingInfo: NSDraggingInfo, toRow: Int) -> Bool {
        var handled = false
        
        if let promises = draggingInfo.draggingPasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) {
            if !promises.isEmpty {
                // We have incoming drag item(s) that are file promises.
                for promise in promises {
                    if let promiseReceiver = promise as? NSFilePromiseReceiver {
                        // Show the progress indicator as we start receiving this promised file.
                        self.progressIndicator?(true)
                        
                        // Ask our file promise receiver to fulfull on their promise.
                        promiseReceiver.receivePromisedFiles(atDestination: self.path!.fileUrl,
                                                             options: [:],
                                                             operationQueue: filePromiseQueue) { (fileURL, error) in
                            /** Finished copying the promised file.
                                Back on the main thread, insert the newly created image file into the table view.
                            */
                            OperationQueue.main.addOperation {
                                do {
                                    if error != nil {
                                        throw error!
                                    } else if draggingInfo.draggingSourceOperationMask.contains(.copy) {
                                        try FileManager.default.copyItem(at: fileURL, to: self.path!.fileUrl.appendingPathComponent(fileURL.lastPathComponent))
                                    } else if draggingInfo.draggingSourceOperationMask.contains(.move) {
                                        try FileManager.default.moveItem(at: fileURL, to: self.path!.fileUrl.appendingPathComponent(fileURL.lastPathComponent))
                                    }
                                } catch {
                                    Commands.showErrorAlert(window: NSApp.keyWindow, title: "Error during Drag&Drop", error: error)
                                }

                                // Stop the progress indicator as we are done receiving this promised file.
                                self.progressIndicator?(false)
                            }
                        }
                    }
                }
                handled = true
            }
        }
        return handled
    }
    
    // The mouse was released over a table view that previously decided to allow a drop.
    func tableView(_ tableView: NSTableView,
                   acceptDrop info: NSDraggingInfo,
                   row: Int,
                   dropOperation: NSTableView.DropOperation) -> Bool {
        
        /** The drop source is from another app (Finder, Mail, Safari, etc.) and there may
            be more than one file.
            Drop each dragged file to their new place.
        */
        // If possible, first handle the incoming dragged photos as file promises.
        if !handlePromisedDrops(draggingInfo: info, toRow: row) {
            // Incoming drag was not propmised, so move in all the outside dragged items as URLs.
            self.progressIndicator?(true)
            
            info.enumerateDraggingItems(
                options: NSDraggingItemEnumerationOptions.concurrent,
                for: tableView,
                classes: [NSPasteboardItem.self],
                searchOptions: [:],
                using: { (draggingItem, idx, stop) in
                    if let pasteboardItem = draggingItem.item as? NSPasteboardItem {
                        // Are we being passed a file URL as the drag type?
                        if  let itemType = pasteboardItem.availableType(from: [.fileURL]),
                            let filePath = pasteboardItem.string(forType: itemType),
                            let url = URL(string: filePath) {
                                do {
                                    if info.draggingSourceOperationMask.contains(.copy) {
                                        try FileManager.default.copyItem(at: url, to: self.path!.fileUrl.appendingPathComponent(url.lastPathComponent))
                                    } else if info.draggingSourceOperationMask.contains(.move) {
                                        try FileManager.default.moveItem(at: url, to: self.path!.fileUrl.appendingPathComponent(url.lastPathComponent))
                                    }
                                } catch {
                                    Commands.showErrorAlert(window: NSApp.keyWindow, title: "Error during Drag&Drop", error: error)
                                }
                            }
                    }
                })
            
            self.progressIndicator?(false)
        }
        
        self.reloadDirectoryContents()
        tableView.reloadData()

        return true
    }
    
    
    // MARK: - Public Methods
    
    public func reloadDirectoryContents() {
        var contents: [FileInfo] = []
        
        if let path {
            do {
                let cntnts = try FileManager.default.contentsOfDirectory(
                    atPath: path,
                    withHiddenFiles: UserDefaults.standard.bool(forKey: "shouldShowHiddenFiles"))
                contents.append(contentsOf: cntnts)
            } catch {
                Commands.showErrorAlert(window: NSApp.keyWindow, title: "Error while retrieving directory contents", error: error)
            }
        }
        
        self.directoryContents = contents
    }
}

extension DirectoryViewTableDataSource: NSFilePromiseProviderDelegate {
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        // Return the fileInfo's URL file name.
        let fileInfo = fileInfoFromFilePromiserProvider(filePromiseProvider: filePromiseProvider)
        return fileInfo!.name
    }
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider,
                             writePromiseTo url: URL,
                             completionHandler: @escaping ((any Error)?) -> Void) {
        
        do {
            if let fileInfo = fileInfoFromFilePromiserProvider(filePromiseProvider: filePromiseProvider) {
                /** Copy the file to the location provided to us. We always do a copy, not a move.
                    It's important you call the completion handler.
                */
                try FileManager.default.copyItem(at: fileInfo.url, to: url)
            }
            completionHandler(nil)
        } catch let error {
            OperationQueue.main.addOperation {
                Commands.showErrorAlert(window: NSApp.keyWindow, title: "Error during Drag&Drop", error: error)
            }
            completionHandler(error)
        }
    }
    
    // Utility function to return a PhotoItem object from the NSFilePromiseProvider.
    private func fileInfoFromFilePromiserProvider(filePromiseProvider: NSFilePromiseProvider) -> FileInfo? {
        var result: FileInfo?
        
        if  let userInfo = filePromiseProvider.userInfo as? [String: Any],
            let row = userInfo[FilePromiseProvider.UserInfoKeys.rowNumberKey] as? Int {
            result = self.directoryContents[row]
        }
        return result
    }
    
}
