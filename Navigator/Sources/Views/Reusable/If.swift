//
//  If.swift
//  Navigator
//
//  Created by Thomas Bonk on 25.09.24.
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

struct If<Content: View, Alternative: View>: View {
    
    // MARK: - Public Properties
    
    var body: some View {
        if condition {
            content()
        } else {
            alternative?()
        }
    }
    
    
    // MARK: - Private Properties
    
    private var condition: Bool
    private var content: () -> Content
    private var alternative: (() -> Alternative)?
    
    
    // MARK: - Initialization
    
    public init(_ condition: Bool, @ViewBuilder _ content: @escaping () -> Content, @ViewBuilder else alternative: @escaping () -> Alternative) {
        self.condition = condition
        self.content = content
        self.alternative = alternative
    }
}
