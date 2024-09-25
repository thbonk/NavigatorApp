//
//  SidebarView.swift
//  Navigator
//
//  Created by Thomas Bonk on 07.09.24.
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
import Combine
import SwiftUI

struct SidebarView: View {
    
    // MARK: - Public Properties
    
    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(self.favorites) { fav in
                    favoriteRow(fav)
                }
                .dropDestination(for: FileInfo.self, action: self.addFavorites(_:at:))
                .onMove(perform: self.moveFavorites(indices:newOffset:))
            } header: {
                Text("Favorites").font(.headline)
            }

            Section {
                ForEach(self.devices) { dev in
                    deviceRow(dev)
                }
            } header: {
                Text("Devices").font(.headline)
            }
        }
        .onChange(of: selection, self.didSelect)
        .onAppear(perform: self.loadVolumes)
        .onDisappear {
            volumesDirectoryObserver?.cancel()
        }
    }
    
    
    // MARK: - Private Properties
    
    @State
    private var selection: String?
    
    @AppStorage("SidebarView.favorites")
    private var favorites: [FileInfo] = [
        FileManager.default.userHomeDirectory
    ]
    
    @State
    private var devices: [VolumeInfo]
    
    @State
    private var volumesDirectoryObserver: Cancellable?
    
    @EnvironmentObject
    private var eventBus: Causality.Bus
    
    
    // MARK: - Initialization
    
    init() {
        devices = []
        volumesDirectoryObserver = FileManager
            .default
            .observeDirectory("/Volumes".fileUrl, callback: self.loadVolumes)
    }
    
    
    // MARK: - View Builders
    
    @ViewBuilder func favoriteRow(_ fav: FileInfo) -> some View {
        HStack {
            fav.icon.scaledToFit()
            Text(fav.name)
        }
    }
    
    @ViewBuilder func deviceRow(_ dev: VolumeInfo) -> some View {
        HStack {
            dev.icon.scaledToFit()
            Text(dev.name)
            if dev.isEjectable {
                Spacer()
                Button {
                    
                } label: {
                    Image(systemName: "eject.fill")
                }
                .buttonStyle(.borderless)
            }
        }
    }
    
    
    // MARK: - Private Methods
    
    private func loadVolumes() {
        Task {
            await loadVolumesAsync()
        }
    }
    
    private func loadVolumesAsync() async {
        if let volumes = try? FileManager.default.mountedVolumes() {
            devices.removeAll()
            
            devices.append(contentsOf: volumes)
        }
    }
    
    private func moveFavorites(indices: IndexSet, newOffset: Int) {
        favorites.move(fromOffsets: indices, toOffset: newOffset)
    }
    
    private func addFavorites(_ fileInfos: [FileInfo], at offset: Int) {
        self.favorites.insert(contentsOf: fileInfos, at: offset)
    }
    
    
    // MARK: - Action Handlers
    
    private func didSelect() {
        if let selection {
            eventBus.publish(event: Events.ShowFavoriteEvent,
                             message: ShowFavorite(path: selection))
        }
    }
}

#Preview {
    SidebarView()
}
