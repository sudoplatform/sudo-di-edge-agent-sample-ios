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
            RegisterView(viewModel: RegisterViewModel())
        }
    }
}
