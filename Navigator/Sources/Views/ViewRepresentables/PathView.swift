//
//  PathView.swift
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

import SwiftUI

public struct PathView: NSViewRepresentable {
    
    // MARK: - Public Properties
    
    @Binding
    public var path: String
    
    
    // MARK: - NSViewRepresentable
    
    public func makeNSView(context: Context) -> NSPathControl {
        let pathControl = NSPathControl()
        
        pathControl.url = URL(fileURLWithPath: path)
        pathControl.delegate = context.coordinator
        pathControl.isEditable = true
        pathControl.target = context.coordinator
        pathControl.action = #selector(context.coordinator.itemSelected(pathControl:))
        pathControl.doubleAction = #selector(context.coordinator.itemSelected(pathControl:))
        
        return pathControl
    }
    
    public func updateNSView(_ pathControl: NSPathControl, context: Context) {
        pathControl.url = URL(fileURLWithPath: path)
    }
    
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    
    // MARK: - Coordinator
    
    @objc public class Coordinator: NSObject, NSPathControlDelegate {
        
        // MARK: - Private Properties
        
        private var parent: PathView
        
        
        // MARK: - Initialization
        
        init(parent: PathView) {
            self.parent = parent
            super.init()
        }
        
        
        // MARK: - Public Methods
        
        @objc public func itemSelected(pathControl: NSPathControl) {
            if let clickedPathItem = pathControl.clickedPathItem, let url = clickedPathItem.url {
                self.parent.path = url.path().removingPercentEncoding ?? url.path()
            }
        }
    }
}
