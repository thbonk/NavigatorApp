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
        var dividerPositions = [CGFloat]()
        
        for index in 0..<(self.arrangedSubviews.count - 1) {
            if self.isVertical {
                dividerPositions.append(self.arrangedSubviews[index].frame.width)
            } else {
                dividerPositions.append(self.arrangedSubviews[index].frame.height)
            }
        }
        
        if let json = try? NSSplitView.jsonEncoder.encode(dividerPositions) {
            coder.encode(json, forKey: "dividerPositions")
        }
    }
    
    func decodeState(with coder: NSCoder) {
        if let dividerPositionsData = coder.decodeObject(forKey: "dividerPositions") as? Data,
           let dividerPositions = try? NSSplitView.jsonDecoder.decode([CGFloat].self, from: dividerPositionsData),
           dividerPositions.count < self.arrangedSubviews.count {
               
               DispatchQueue.main.async {
                    for (index, position) in dividerPositions.enumerated() {
                        self.setPosition(position, ofDividerAt: index)
                    }
                    self.layout()
               }
        }
    }
    
    
}
