//
//  ToggleSiebarCommand.swift
//  Navigator
//
//  Created by Thomas Bonk on 27.10.24.
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

extension Commands {
    
    typealias ToggleSidebarSubscription = Causality.EventSubscription<Causality.Event<Causality.NoMessage>, Causality.NoMessage>
    
    static let ToggleSidebar = EventRegistry.shared.register(label: "toggle-sidebar", description: "Show or hide the Sidebar")
    
    static func toggleSidebar(eventBus: Causality.Bus) {
        eventBus.publish(event: Commands.ToggleSidebar)
    }
    
}
