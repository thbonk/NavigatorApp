//
//  CreateNewFilesystemEntryCommand.swift
//  Navigator
//
//  Created by Thomas Bonk on 29.10.24.
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

struct CreateNewFilesystemEntryMessage: Causality.Message {
    
    public let directory: Bool
    
}

extension Commands {
    
    typealias CreateNewFilesystemEntrySubscription = Causality.EventSubscription<Causality.Event<CreateNewFilesystemEntryMessage>, CreateNewFilesystemEntryMessage>
    
    static let CreateNewFilesystemEntry = EventRegistry.shared.register(messageType: CreateNewFilesystemEntryMessage.self, label: "create-new-filesystem-entry")
    
    static func createNewFilesystemEntry(eventBus: Causality.Bus, _ directory: Bool) {
        eventBus.publish(event: Commands.CreateNewFilesystemEntry, message: CreateNewFilesystemEntryMessage(directory: directory))
    }
    
}
