//
//  ContentView.swift
//  Navigator
//
//  Created by Thomas Bonk on 06.09.24.
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

struct ContentView: View {

    // MARK: - Public Properties
    
    var body: some View {
        NavigationSplitView {
            SidebarView().frame(minWidth: 200, idealWidth: 200, maxWidth: .infinity)
        } content: {
            DirectoryView(path: $path).frame(minWidth: 400, idealWidth: 400, maxWidth: .infinity)
        } detail: {
            InfoView().frame(minWidth: 200, idealWidth: 200, maxWidth: .infinity)
        }
        .onAppear(perform: self.subscribeEvents)
        .onDisappear(perform: self.unsubscribeEvents)
    }
    
    
    // MARK: - Private Properties
    
    @State
    public var path = FileManager.default.userHomeDirectoryPath
    
    @EnvironmentObject
    private var eventBus: Causality.Bus
    
    
    // MARK: Subscribe and unsubscribe events
    
    private func subscribeEvents() {
        // TODO
    }
    
    private func unsubscribeEvents() {
        // TODO
    }
}

#Preview {
    ContentView()
}
