//
//  InfoView.swift
//  Navigator
//
//  Created by Thomas Bonk on 08.10.24.
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

import Causality
import SwiftUI

struct InfoView: View {
    
    // MARK: - Public Properties
    
    var body: some View {
        ConditionalView(condition: fileInfo != nil) {
            VStack {
                Text(fileInfo?.name ?? "???")
                    .font(.subheadline)
                
                ScrollView {
                    preview()
                    info()
                    attributes()
                }
            }
        } alternative: {
            ScrollView([.horizontal, .vertical]) {
                Text("No file selected")
            }
        }
        .padding()
        .onAppear(perform: self.subscribeEvents)
        .onDisappear(perform: self.unsubscribeEvents)
    }
    
    var eventBus: Causality.Bus
    
    
    // MARK: - Private Properties
    
    @AppStorage("infoview-dg-preview-expanded")
    private var previewExapnded: Bool = true
    @AppStorage("infoview-dg-info-expanded")
    private var infoExapnded: Bool = true
    @AppStorage("infoview-dg-attributes-expanded")
    private var attributesExapnded: Bool = true
    
    @State
    private var fileInfo: FileInfo?
    
    @State
    private var selectedFilesChangedSubscription: Events.SelectedFilesChangedSubscription?
    
    // MARK: - Disclosure Groups
    
    @ViewBuilder private func preview() -> some View {
        DisclosureGroup("Preview", isExpanded: $previewExapnded) {
            if let fileInfo {
                Image(nsImage: fileInfo.icon!).resizable().scaledToFit().frame(maxWidth: 256)
            } else {
                Image(systemName: "document.fill").resizable().scaledToFit().frame(maxWidth: 256)
            }
            
        }
    }
    
    @ViewBuilder private func info() -> some View {
        DisclosureGroup("Info", isExpanded: $infoExapnded) {
            Grid(alignment: .leading) {
                GridRow {
                    Text("Name:").bold()
                    Text(fileInfo?.name ?? "")
                }
                GridRow {
                    Text("Path:").bold()
                    Text(fileInfo?.path ?? "")
                }
                GridRow {
                    Text("Size:").bold()
                    Text(fileInfo?.fileSize ?? "")
                }
                
                GridRow {
                    Text("Created at:").bold()
                    Text(fileInfo?.creationDate ?? "")
                }.padding(.top, 16)
                GridRow {
                    Text("Modified at:").bold()
                    Text(fileInfo?.modificationDate ?? "")
                }
                GridRow {
                    Text("Accessed at:").bold()
                    Text(fileInfo?.accessDate ?? "")
                }
            }
        }
    }
    
    @ViewBuilder private func attributes() -> some View {
        DisclosureGroup("Attributes", isExpanded: $attributesExapnded) {
            Grid(alignment: .leading) {
                GridRow {
                    Text("Owner:").bold()
                    Text("\(fileInfo!.ownerAccountName) (\(fileInfo!.ownerAccountID))")
                }
                GridRow {
                    Text("Group:").bold()
                    Text("\(fileInfo!.groupOwnerAccountName) (\(fileInfo!.groupOwnerAccountID))")
                }
                GridRow {
                    Text("Permissions:").bold()
                    Text("\(fileInfo!.readableAccessRights) (\(fileInfo!.accessRights))")
                }
            }
        }
    }
    
    
    // MARK: - Event Handlers
    
    private func selectedFilesChanged(message: SelectedFilesChangedMessage) {
        self.fileInfo = message.file
    }
    
    
    // MARK: - Private Methods
    
    private func subscribeEvents() {
        if self.selectedFilesChangedSubscription == nil {
            self.selectedFilesChangedSubscription = self.eventBus.subscribe(Events.SelectedFilesChanged, handler: self.selectedFilesChanged)
        }
    }
    
    private func unsubscribeEvents() {
        self.selectedFilesChangedSubscription?.unsubscribe()
    }
    
}

class HostingInfoView: NSHostingView<InfoView> {
    
    // MARK: - Initialization
    
    @MainActor @preconcurrency init(eventBus: Causality.Bus) {
        super.init(rootView: InfoView(eventBus: eventBus))
    }
    
    @MainActor @preconcurrency required init(rootView: InfoView) {
        super.init(rootView: rootView)
    }

    @MainActor @preconcurrency required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("The initializer init?(coder aDecoder: NSCoder) is not supported")
    }
}
