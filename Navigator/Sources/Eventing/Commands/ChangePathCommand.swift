//
//  ChangePathCommand.swift
//  Navigator
//
//  Created by Thomas Bonk on 29.09.24.
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

struct ChangePathMessage {
    
    // MARK: - Properties
    
    public let path: String
    
}

extension Commands {
    
    typealias ChangePathSubscription = Causality.EventSubscription<Causality.Event<ChangePathMessage>, ChangePathMessage>
    
    //static let ChangePath = Causality.Event<ChangePathMessage>(label: "change-path")
    static let ChangePath = EventRegistry.shared.register(messageType: ChangePathMessage.self, label: "change-path")
    
    static func changePath(eventBus: Causality.Bus, _ path: String) {
        eventBus.publish(event: Commands.ChangePath, message: ChangePathMessage(path: path))
    }
}
