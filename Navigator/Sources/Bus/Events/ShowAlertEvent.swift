//
//  ShowAlertEvent.swift
//  Navigator
//
//  Created by Thomas Bonk on 10.09.24.
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
import Drops
import Foundation
import SwiftUI

struct ShowAlertMessage {
    
    // MARK: - Properties
    
    public let alert: AlertView.Alert
}

extension Events {
    static let ShowAlertEvent = Causality.Event<ShowAlertMessage>(label: "Show an alert based on the passed message")
    
    static func publishShowAlertEvent(eventBus: Causality.Bus, _ alert: AlertView.Alert) {
        eventBus.publish(event: Events.ShowAlertEvent, message: ShowAlertMessage(alert: alert))
    }
    
    static func publishShowErrorAlertEvent(eventBus: Causality.Bus, title: LocalizedStringKey, error: Error) {
        publishShowAlertEvent(
            eventBus: eventBus,
                .init(severity: .error, title: title, subtitle: LocalizedStringKey(error.localizedDescription)))
    }
}
