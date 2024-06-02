//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import SudoDIEdgeAgent
import SudoDIRelay

class HomeViewModel: ObservableObject {

    enum AgentState: String {
        case running
        case stopped
    }

    /// Track the state of the agent
    @Published var serverState: AgentState = .stopped

    init() {}

    func prepare() {
        let isRunning = Clients.agent.isRunning()
        if isRunning {
            serverState = .running
        }
    }
    
    /// Simplified method for turning on and off the server state from running.
    func changeAgentState() {
        Task { @MainActor in
            NSLog("Changing agent state: \(serverState.rawValue)...")
            switch serverState {
            case .running:
                Clients.agent.stop()
                serverState = .stopped
            case .stopped:
                do {
                    // The agent needs to be provided a messaging source in order to run
                    try Clients.agent.run(messageSource: Clients.mutliMessageSource)
                    serverState = .running
                } catch {
                    if let error = error as? SudoDIEdgeAgentError.AgentRunError {
                        switch error {
                        case .agentAlreadyRunningError:
                            NSLog("Agent is already running, ignoring request...")
                        default:
                            break
                        }
                    }
                    NSLog("Error occurred trying to run the agent \(error)")
                }
            }
        }
    }
}
