//
//  InfoViewWindowController.swift
//  Navigator
//
//  Created by Thomas Bonk on 25.10.24.
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

class InfoViewWindowController: NSWindowController {
    
    // MARK: - Initialization
    
    public class func create(fileInfo: FileInfo) {
        let controller = InfoViewWindowController(window: createWindow(title: fileInfo.name))
        let infoViewController = InfoViewController()
        
        infoViewController.fileInfo = fileInfo
        controller.contentViewController = infoViewController
        
        controller.showWindow(self)
    }
    
    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Private Static Methods
    
    private class func createWindow(title: String) -> NSWindow {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.closable, .resizable, .titled, .unifiedTitleAndToolbar],
            backing: .buffered, defer: false)
        
        window.title = title
        window.isReleasedWhenClosed = true
        
        return window
    }
}
