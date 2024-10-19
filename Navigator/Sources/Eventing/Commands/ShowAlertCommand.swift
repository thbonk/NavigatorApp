//
//  ShowAlertCommand.swift
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

import AppKit
import Causality
import Foundation

struct ShowAlertMessage: Causality.Message {
    
    // MARK: - Properties
    
    public let window: NSWindow?
    public let alert: NSAlert
}

extension Commands {
    
    typealias ShowAlertSubscription = Causality.EventSubscription<Causality.Event<ShowAlertMessage>, ShowAlertMessage>
    
    static let ShowAlert = Causality.Event<ShowAlertMessage>(label: "Show an alert based on the passed message")
    
    static func showAlert(window: NSWindow?, _ alert: NSAlert) {
        AppDelegate.globalEventBus.publish(event: Commands.ShowAlert, message: ShowAlertMessage(window: window, alert: alert))
    }
    
    static func showErrorAlert(window: NSWindow?, title: String, error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            
            showAlert(window: window,
                      NSAlert
                .create()
                .withMessageText(title)
                .withInformativeText(error.localizedDescription)
                .withAlertStyle(.critical))
        }
    }
}

extension NSAlert {
    
    public class func create() -> NSAlert {
        .init()
    }
    
    public func withMessageText(_ messageText: String) -> Self {
        self.messageText = messageText
        return self
    }
    
    public func withInformativeText(_ informationText: String) -> Self {
        self.informativeText = informationText
        return self
    }
    
    public func withAlertStyle(_ alertStyle: NSAlert.Style) -> Self {
        self.alertStyle = alertStyle
        return self
    }
}
