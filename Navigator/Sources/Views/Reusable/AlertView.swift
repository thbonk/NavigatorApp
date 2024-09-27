//
//  AlertView.swift
//  Navigator
//
//  Created by Thomas Bonk on 26.09.24.
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

import SwiftUI

struct AlertView: View {
    
    // MARK: - Public Enums and STructs
    
    public enum Severity {
        case success
        case info
        case warning
        case error
        case fatal
    }
    
    struct Alert {
        var severity: Severity
        var title: LocalizedStringKey
        var subtitle: LocalizedStringKey? = nil
        var closeOnTap: Bool = true
        var autoCloseAfter: Double = 5
    }
    
    
    // MARK: - Public Properties
    
    var body: some View {
        if let alert = self.alert {
            HStack {
                alertIcon(for: alert.severity)
                    .padding()
                
                VStack(alignment: .leading) {
                    Text(alert.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let subtitle = alert.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .onTapGesture(perform: self.dismissOnTap)
            .onAppear(perform: self.startAutoCloseTimer)
            .onDisappear {
                self.onDismiss?()
            }
        } else {
            Text("")
                .onAppear {
                    dismiss.callAsFunction()
                }
        }
    }
    
    
    // MARK: - Private Property
    
    private let alert: Alert?
    private let onDismiss: (() -> Void)?
    
    @Environment(\.dismiss)
    private var dismiss
    
    @State
    private var closeTimer: Timer?
    
    
    // MARK: - Initialization
    
    init(alert: Alert?, onDismiss: (() -> Void)? = nil) {
        self.alert = alert
        self.onDismiss = onDismiss
    }
    
    
    // MARK: - View Builders
    
    @ViewBuilder func alertIcon(for severity: Severity) -> some View {
        switch severity {
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundColor(.green)
        case .info:
            Image(systemName: "info.circle.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundColor(.blue)
        case .warning:
            Image(systemName: "exclamationmark.circle.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundColor(.yellow)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundColor(.red)
        case .fatal:
            Image(systemName: "exclamationmark.octagon.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundColor(.red)
        }
    }
    
    
    // MARK: - Private Methods
    
    private func dismissOnTap() {
        if self.alert!.closeOnTap {
            dismiss.callAsFunction()
        }
    }
    
    private func startAutoCloseTimer() {
        if self.alert!.autoCloseAfter > 0 {
            self.closeTimer = Timer.scheduledTimer(withTimeInterval: self.alert!.autoCloseAfter, repeats: false) { _ in
                dismiss.callAsFunction()
            }
        }
    }
}
