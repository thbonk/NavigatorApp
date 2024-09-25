//
//  InfoView.swift
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

struct InfoView: View {
    
    // MARK: - Public Properties
    
    var body: some View {
        VStack {
            Text(fileInfo.name)
                .font(.subheadline)
            
            ScrollView {
                preview()
                info()
            }
        }
    }
    
    let fileInfo: FileInfo
    
    
    // MARK: - Private Properties
    
    @AppStorage("infoview-dg-preview-expanded")
    private var previewExapnded: Bool = true
    @AppStorage("infoview-dg-info-expanded")
    private var infoExapnded: Bool = true
    
    
    // MARK: - Disclosure Groups
    
    @ViewBuilder private func preview() -> some View {
        DisclosureGroup("Preview", isExpanded: $previewExapnded) {
            fileInfo.icon.resizable().scaledToFit().frame(maxWidth: 256)
        }
    }
    
    @ViewBuilder private func info() -> some View {
        DisclosureGroup("Info", isExpanded: $infoExapnded) {
            Grid(alignment: .leading) {
                GridRow {
                    Text("Name:").bold()
                    Text(fileInfo.name)
                }
                GridRow {
                    Text("Path:").bold()
                    Text(fileInfo.path)
                }
                GridRow {
                    Text("Size:").bold()
                    Text(fileInfo.size)
                }
                
                GridRow {
                    Text("Created at:").bold()
                    Text(fileInfo.createdAt)
                }.padding(.top, 16)
                GridRow {
                    Text("Modified at:").bold()
                    Text(fileInfo.modifiedAt)
                }
            }
        }
    }
}

