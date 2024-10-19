//
//  NSFocusIndicatorView.swift
//  Navigator
//
//  Created by Thomas Bonk on 17.10.24.
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
import Combine

@objc class NSFocusIndicatorView: NSView {
    
    // MARK: - Private Properties
    
    private var focusIndicatorColor: NSColor = .clear // Default color
    private var windowObserver: NSKeyValueObservation?
    private var firstResponderObserver: NSKeyValueObservation?
    
    // MARK: - Initialization
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.wantsLayer = true
        
        self.windowObserver = self.observe(\.window, changeHandler: { _, _ in
            if let window = self.window {
                self.firstResponderObserver = window.observe(\.firstResponder,
                                                              changeHandler: self.firstResponderDidChange)
            }
        })
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.wantsLayer = true
    }
    
    
    // MARK: - Private Methods
    
    private func firstResponderDidChange(window: NSWindow, change: NSKeyValueObservedChange<NSResponder?>) {
        if let responder = window.firstResponder, let view = responder as? NSView, isSubview(view) {
            self.focusIndicatorColor = NSColor.highlightColor
        } else {
            self.focusIndicatorColor = .clear
        }
        
        self.setNeedsDisplay(self.bounds)
    }
    
    private func isSubview(_ view: NSView) -> Bool {
        if view == self {
            return true
        } else {
            return view.isDescendant(of: self)
        }
    }
    
    
    // MARK: - NSView
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw the left side color if a subview has focus
        if focusIndicatorColor != .clear {
            let highlightRect = NSRect(x: -1, y: -1, width: 2, height: bounds.height)
            focusIndicatorColor.setFill()
            highlightRect.fill()
        }
    }
    
}
