//
//  DirectoryTableView.swift
//  Navigator
//
//  Created by Thomas Bonk on 05.10.24.
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

@objc class DirectoryTableView: NSTableView {
    
    // MARK: - Public Properties
    
    var hasFocus: Bool {
        return self.window?.firstResponder == self
    }
    
    public var actionTarget: NSObject?
    public var actionSelector: Selector?
    
    
    // MARK: - Overriden Methods
    
    override func keyDown(with event: NSEvent) {
        if event.specialKey == .enter || event.keyCode == 36 {
            if let sel = actionSelector {
                self.actionTarget?.perform(sel, with: self)
            }
        } else if let character = self.characterKeyPress(event) {
            self.selectFirstRowWith(first: character)
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func reloadData() {
        let selectedRows = self.selectedRowIndexes
        let ds = self.dataSource as! DirectoryViewTableDataSource
        let count = ds.directoryContents.count
        let selectedFileInfos: [FileInfo?] = selectedRows
            .map { $0 < count ? ds.directoryContents[$0] : nil }
            .filter { $0 != nil }
            
        super.reloadData()
            
        if selectedFileInfos.count > 0 {
            let indexes = selectedFileInfos
                .map { ds.directoryContents.firstIndex(of: $0!) }
                .filter { $0 != nil }
                .map { $0! }
            
            self.selectRowIndexes(IndexSet(indexes), byExtendingSelection: false)
        }
    }
    
    
    // MARK: - Private Methods
    
    private func selectFirstRowWith(first character: Character) {
        let ds = self.dataSource as! DirectoryViewTableDataSource
        
        if self.hasFocus,
           let fileInfo = ds.directoryContents
            .first(where: { $0.name.localizedUppercase.hasPrefix(String(character).localizedUppercase) }) {
            
            self.selectRowIndexes(IndexSet(integer: ds.directoryContents.firstIndex(of: fileInfo)!),
                                  byExtendingSelection: false)
        }
    }
    
    private func characterKeyPress(_ event: NSEvent) -> Character? {
        guard
            let characters = event.characters
        else {
            return nil
        }
        
        guard
            !characters.isEmpty
        else {
            return nil
        }
        
        guard
            event.modifierFlags.rawValue == 256
        else {
            return nil
        }
        
        return characters.first
    }
    
}
