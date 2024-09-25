//
//  InfoView.swift
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
import SwiftUI

struct InfoSideBar: View {
    
    // MARK: - Public Properties

    var body: some View {
        If(self.selectedFiles.count == 1) {
            InfoView(fileInfo: self.selectedFiles.first!)
        } else: {
            Text("No or many files selected.")
        }
        .padding()
        .onAppear(perform: self.subscribeEvents)
        .onDisappear(perform: self.unsubscribeEvents)
    }
    
    
    // MARK: - Private Properties
    
    @State
    private var selectedFiles: [FileInfo] = []
    
    @EnvironmentObject
    private var eventBus: Causality.Bus
    
    @State
    private var selectedFilesStateSubscription: Causality.StateSubscription<Causality.State<SelectedFileInfos>, SelectedFileInfos>?
    
    
    // MARK: - Private Methods
    
    private func update(state: SelectedFileInfos) {
        self.selectedFiles.removeAll()
        self.selectedFiles.append(contentsOf: state.fileInfos)
    }
    
    private func subscribeEvents() {
        selectedFilesStateSubscription = eventBus.subscribe(States.SelectedFileInfosState, handler: self.update(state:))
    }
    
    private func unsubscribeEvents() {
        selectedFilesStateSubscription?.unsubscribe()
    }
}

#Preview {
    InfoSideBar()
}
