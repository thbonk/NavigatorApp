//
//  ShowFileInfosCommand.swift
//  Navigator
//
//  Created by Thomas Bonk on 24.10.24.
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
    
    typealias ShowFileInfosSubscription = Causality.EventSubscription<Causality.Event<Causality.NoMessage>, Causality.NoMessage>
    
    static let ShowFileInfos = EventRegistry.shared.register(label: "show-file-infos", description: "Show the files infos for the selected files")
    
    static func showFileInfos(eventBus: Causality.Bus) {
        eventBus.publish(event: Commands.ShowFileInfos)
    }
    
}
