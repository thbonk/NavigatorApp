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

import AlertToast
import Causality
import Foundation
import SwiftUI

struct ShowAlertMessage: Causality.Message {
    
    // MARK: - Properties
    
    let displayMode: AlertToast.DisplayMode
    let type: AlertToast.AlertType
    let title: LocalizedStringKey?
    let subTitle: LocalizedStringKey?
    let style: AlertToast.AlertStyle?
    
    
    // MARK: - Initialization
    
    init(
        displayMode: AlertToast.DisplayMode,
        type: AlertToast.AlertType,
        title: LocalizedStringKey? = nil,
        subTitle: LocalizedStringKey? = nil,
        style: AlertToast.AlertStyle? = nil) {
            
        self.displayMode = displayMode
        self.type = type
        self.title = title
        self.subTitle = subTitle
        self.style = style
    }
}

extension Events {
    static let ShowAlert = Causality.Event<ShowAlertMessage>(label: "Show an alert based on the passed message")
}
