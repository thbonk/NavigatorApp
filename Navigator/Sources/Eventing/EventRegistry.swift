//
//  EventRegistry.swift
//  Navigator
//
//  Created by Thomas Bonk on 04.10.24.
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

class EventRegistry {
    
    struct ActionEvent: Hashable {
        
        // MARK: - Public Properties
        
        let label: String
        let event: Causality.Event<Causality.NoMessage>
        let description: String
        
        
        // MARK: - Hashable
        
        static func == (lhs: EventRegistry.ActionEvent, rhs: EventRegistry.ActionEvent) -> Bool {
            lhs.description == rhs.description
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(description)
        }
    }
    
    // MARK: - Public Static Properties
    
    public static var shared: EventRegistry = {
        EventRegistry()
    }()
    
    
    // MARK: - Public Properties
    
    public var actionEvents: [ActionEvent] {
        return self.events
            .keys
            .filter { self.events[$0]?.description != nil }
            .map {
                var description: String!
                
                if let shortcut = ApplicationSettings.shared.shortcuts[$0],
                   !shortcut.key.description.isEmpty {
                    description = "\(self.events[$0]!.description!) (\(shortcut.key.description))"
                } else {
                    description = self.events[$0]!.description!
                }
                
                return ActionEvent(
                    label: $0,
                    event: self.events[$0]!.event,
                    description: description)
            }
            .sorted(by: { $0.description < $1.description })
    }
    
    
    // MARK: - Private Properties
    
    private var events: [String : (event: Causality.Event<Causality.NoMessage>, description: String?)] = [:]
    
    
    // MARK: - Initialization
    
    private init() {
        
    }
    
    
    // MARK: - Public Static Methods
    
    class func initialize() {
        Commands.initialize()
        Events.initialize()
    }
    
    
    // MARK: - Public Methods
    
    func register<Message: Causality.Message>(messageType: Message.Type, label: String) -> Causality.Event<Message> {
        return Causality.Event<Message>(label: label)
    }
    
    func register(label: String, description: String? = nil) -> Causality.Event<Causality.NoMessage> {
        let event = register(messageType: Causality.NoMessage.self, label: label)
        
        self.events[label] = (event: event, description: description)
        return event
    }
    
    func publish(eventBus: Causality.Bus, event: String) {
        if let evnt = self.events[event] {
            eventBus.publish(event: evnt.event)
        }
    }

}
