//
//  NSSplitView+viewRestoration.swift
//  Navigator
//
//  Created by Thomas Bonk on 13.10.24.
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

extension NSSplitView: NSViewStateRestoration {
    
    // MARK: - Static Fileprivate Properties
    
    fileprivate static let jsonEncoder: JSONEncoder = { JSONEncoder() }()
    fileprivate static let jsonDecoder: JSONDecoder = { JSONDecoder() }()
    
    
    // MARK: - Methods
    
    func encodeState(with coder: NSCoder) {
        let splitPaneWidths = self.arrangedSubviews.map({ $0.frame }).map({ NSStringFromRect($0) })
        
        if let json = try? NSSplitView.jsonEncoder.encode(splitPaneWidths) {
            coder.encode(json, forKey: "splitPaneWidths")
        }
    }
    
    func decodeState(with coder: NSCoder) {
        if let splitPaneWidthsData = coder.decodeObject(forKey: "splitPaneWidths") as? Data,
           let splitPaneWidths = try? NSSplitView.jsonDecoder.decode([String].self, from: splitPaneWidthsData),
           splitPaneWidths.count <= self.arrangedSubviews.count {
            
            for (index, frame) in splitPaneWidths.enumerated() {
                DispatchQueue.main.async {
                    //self.arrangedSubviews[index].frame = NSRectFromString(frame)
                    self.arrangedSubviews[index].setFrameSize(NSRectFromString(frame).size)
                    self.layout()
                }
            }
        }
    }
    
    
}
