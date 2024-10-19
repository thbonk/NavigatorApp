//
//  SelectedFilesChangedEvent.swift
//  Navigator
//
//  Created by Thomas Bonk on 09.10.24.
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
import Foundation

struct SelectedFilesChangedMessage {
    
    // MARK: - Properties
    
    public let file: FileInfo?
    public let files: [FileInfo]?
    
}

extension Events {
    
    typealias SelectedFilesChangedSubscription = Causality.EventSubscription<Causality.Event<SelectedFilesChangedMessage>, SelectedFilesChangedMessage>
    
    static let SelectedFilesChanged = EventRegistry.shared.register(messageType: SelectedFilesChangedMessage.self, label: "selected-files-changed")
    
    static func selectedFileChanged(eventBus: Causality.Bus, _ selectedFile: FileInfo) {
        eventBus.publish(event: Events.SelectedFilesChanged, message: SelectedFilesChangedMessage(file: selectedFile, files: nil))
    }
    
    static func selectedFilesChanged(eventBus: Causality.Bus, _ selectedFiles: [FileInfo]) {
        eventBus.publish(event: Events.SelectedFilesChanged, message: SelectedFilesChangedMessage(file: nil, files: selectedFiles))
    }
}
