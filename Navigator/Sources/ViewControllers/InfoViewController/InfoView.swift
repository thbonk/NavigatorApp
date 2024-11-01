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
        VStack {
            ScrollView {
                preview()
                info()
                accessRights()
            }
        }
        .padding()
        .onAppear(perform: self.populateDependingProperties)
        .onChange(of: ownerId, self.changeOwner)
        .onChange(of: groupId, self.changeGroup)
        .onChange(of: permissions, self.changeAccessRights)
        .onChange(of: fileInfo, self.changeFileInfo)
    }
    
    @State
    var fileInfo: FileInfo
    
    
    // MARK: - Initialization
    
    public init(fileInfo: FileInfo) {
        self.fileInfo = fileInfo
    }
    
    // MARK: - Private Properties
    
    @AppStorage("infoview-dg-preview-expanded")
    private var previewExapnded: Bool = true
    @AppStorage("infoview-dg-info-expanded")
    private var infoExapnded: Bool = true
    @AppStorage("infoview-dg-access-rights-expanded")
    private var accessRightsExpanded: Bool = true
    
    @State
    private var ownerId: UInt32?
    @State
    private var groupId: UInt32?
    @State
    private var permissions: UInt16?
    
    
    // MARK: - Disclosure Groups
    
    @ViewBuilder private func preview() -> some View {
        DisclosureGroup("Preview", isExpanded: $previewExapnded) {
            if let icon = fileInfo.icon {
                Image(nsImage: icon).resizable().scaledToFit().frame(maxWidth: 256)
            } else {
                Image(systemName: "document.fill").resizable().scaledToFit().frame(maxWidth: 256)
            }
            
        }
    }
    
    @ViewBuilder private func info() -> some View {
        DisclosureGroup("Info", isExpanded: $infoExapnded) {
            LazyVGrid(columns: [.init(alignment: .topTrailing), .init(alignment: .topLeading)]) {
                Text("Name:").bold()
                Text(fileInfo.name)
                
                Text("Path:").bold()
                Text(fileInfo.path)
                
                Text("Size:").bold()
                Text(fileInfo.fileSize)
                
                Text("Created at:").bold()
                Text(fileInfo.creationDate ?? "")
                
                Text("Modified at:").bold()
                Text(fileInfo.modificationDate ?? "")
                
                Text("Accessed at:").bold()
                Text(fileInfo.accessDate ?? "")
                    
                Text("Owner:").bold()
                Text("\(fileInfo.ownerAccountName) (\(fileInfo.ownerAccountID))")
            
                Text("Group:").bold()
                Text("\(fileInfo.groupOwnerAccountName) (\(fileInfo.groupOwnerAccountID))")
            
                Text("Permissions:").bold()
                Text("\(fileInfo.readableAccessRights) (\(fileInfo.accessRights))")
            }
        }
    }
    
    @ViewBuilder private func accessRights() -> some View {
        DisclosureGroup("Access Rights", isExpanded: $accessRightsExpanded) {
            LazyVGrid(columns: [.init(alignment: .trailing), .init(alignment: .leading)]) {
                Text("Owner:").bold()
                Picker(selection: $ownerId) {
                    ForEach(UserInfo.shared.allUsers) { user in
                        Text("\(user.name) (\(user.id))")
                            .tag(user.id)
                    }
                } label: {
                    EmptyView()
                }

                Text("Group:").bold()
                Picker(selection: $groupId) {
                    ForEach(UserInfo.shared.allGroups) { group in
                        Text("\(group.name) (\(group.id))")
                            .tag(group.id)
                    }
                } label: {
                    EmptyView()
                }
                
                Text("Owner:").bold()
                BitManipulationView(titles: ["r", "w", "x"], bits: [8, 7, 6], value: $permissions)
                
                Text("Group:").bold()
                BitManipulationView(titles: ["r", "w", "x"], bits: [5, 4, 3], value: $permissions)
                
                Text("Others:").bold()
                BitManipulationView(titles: ["r", "w", "x"], bits: [2, 1, 0], value: $permissions)
            }
        }
    }
    
    
    // MARK: - Private Properties
    
    private func changeOwner(oldOwner: UInt32?, newOwner: UInt32?) {
        guard
            let oldOwner, let newOwner, oldOwner != newOwner
        else {
            return
        }
        
        do {
            try FileManager.default.setAttributes([.ownerAccountID: newOwner], ofItemAtPath: self.fileInfo.url.path)
        } catch {
            Commands.showErrorAlert(window: nil,
                                    title: "Can't change owner of file \(self.fileInfo.name)",
                                    error: error)
        }
        
        do {
            self.fileInfo = try FileManager.default.fileInfo(from: self.fileInfo.url)
        } catch {
            Commands.showErrorAlert(window: nil,
                                    title: "Error while getting file info for \(self.fileInfo.name)",
                                    error: error)
        }
    }
    
    private func changeGroup(oldGroup: UInt32?, newGroup: UInt32?) {
        guard
            let oldGroup, let newGroup, oldGroup != newGroup
        else {
            return
        }
        
        do {
            try FileManager.default.setAttributes([.groupOwnerAccountID: newGroup], ofItemAtPath: self.fileInfo.url.path)
        } catch {
            Commands.showErrorAlert(window: nil,
                                    title: "Can't change group of file \(self.fileInfo.name)",
                                    error: error)
        }
        
        do {
            self.fileInfo = try FileManager.default.fileInfo(from: self.fileInfo.url)
        } catch {
            Commands.showErrorAlert(window: nil,
                                    title: "Error while getting file info for \(self.fileInfo.name)",
                                    error: error)
        }
    }
    
    private func changeAccessRights(oldValue: UInt16?, newValue: UInt16?) {
        guard
            let oldValue, let newValue, oldValue != newValue
        else {
            return
        }
        
        do {
            try FileManager.default.changeAccessRights(of: self.fileInfo, to: newValue)
        } catch {
            Commands.showErrorAlert(window: nil,
                                    title: "Can't change access rights of file \(self.fileInfo.name)",
                                    error: error)
        }
        
        do {
            self.fileInfo = try FileManager.default.fileInfo(from: self.fileInfo.url)
        } catch {
            Commands.showErrorAlert(window: nil,
                                    title: "Error while getting file info for \(self.fileInfo.name)",
                                    error: error)
        }
    }
    
    private func changeFileInfo(old: FileInfo, new: FileInfo) {
        DispatchQueue.main.async {
            self.populateDependingProperties()
        }
    }
    
    private func populateDependingProperties() {
        self.ownerId = UserInfo.shared.allUsers.first(where: { user in
            user.id == self.fileInfo.ownerAccountID
        })?.id
        self.groupId = UserInfo.shared.allGroups.first(where: { group in
            group.id == self.fileInfo.groupOwnerAccountID
        })?.id
        self.permissions = self.fileInfo.accessRights
    }
    
}

struct BitManipulationView: View {
    
    // MARK: - Public Properties
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<titles.count) { index in
                Button(titles[index], action: { self.toggle(bit: self.bits[index]) })
                    //.frame(width: 32, height: 32)
                    .buttonStyle(BitManipulationButtonStyle(backgroundColor: self.color(for: bits[index])))
                    .padding([.leading, .trailing], 0)
            }
        }
    }
    
    let titles: [String]
    let bits: [Int]
    
    @Binding
    var value: UInt16?
    
    
    // MARK: Private Methods
    
    private func toggle(bit: Int) {
        guard let _ = value else { return }
        
        if (self.value! & (1 << bit)) != 0 {
            self.value! &= ~(1 << bit)
        } else {
            self.value! |= (1 << bit)
        }
    }
    
    private func color(for bit: Int) -> Color {
        guard let _ = value else { return .clear }
        
        if (self.value! & (1 << bit)) != 0 {
            return .accentColor
        }
        
        return .clear
    }
    
}

extension Color {
    /// Returns `true` if the color is "light"; `false` otherwise.
    func isLightColor() -> Bool {
        //NSColor(cgColor: self.cgColor!)
        guard
            let cgColor = self.cgColor
        else {
            return false
        }
        
        guard
            let color = NSColor(cgColor: cgColor)
        else {
            return false
        }
        
        var white: CGFloat = 0
        color.getWhite(&white, alpha: nil)
        
        // A threshold of 0.7 is a general standard for distinguishing light vs. dark colors
        return white > 0.7
    }
}

struct BitManipulationButtonStyle: ButtonStyle {
    var backgroundColor: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        let borderColor = colorScheme == .light ? Color.gray : Color.gray.opacity(0.8)
        
        return configuration.label
            .frame(width: 24, height: 24)
            .background(backgroundColor)
            .foregroundColor(.white)
            .clipShape(Rectangle())
            .overlay(
                Rectangle().stroke(borderColor, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

class HostingInfoView: NSHostingView<InfoView> {
    
    // MARK: - Initialization
    
    @MainActor @preconcurrency init(fileInfo: FileInfo) {
        super.init(rootView: InfoView(fileInfo: fileInfo))
    }
    
    @MainActor @preconcurrency required init(rootView: InfoView) {
        super.init(rootView: rootView)
    }

    @MainActor @preconcurrency required dynamic public init?(coder aDecoder: NSCoder) {
        fatalError("The initializer init?(coder aDecoder: NSCoder) is not supported")
    }
}
