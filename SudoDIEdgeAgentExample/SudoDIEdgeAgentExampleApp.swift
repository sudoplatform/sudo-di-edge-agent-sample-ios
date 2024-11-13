//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import SwiftUI

@main
struct SudoDIEdgeAgentExampleApp: App {

    init() {
        do {
            try Clients.configure()
        } catch {
            fatalError("Failed to initialize Sudo clients: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RegisterView(viewModel: RegisterViewModel()).onOpenURL { url in
                Task { @MainActor in
                    // simply try any URL as a URL for the agent to receive.
                    // ideally URLs should be pre-filtered and understood by the application.
                    try await Clients.agent.receiveUrl(url: url.absoluteString)
                }
            }
        }
    }
}
