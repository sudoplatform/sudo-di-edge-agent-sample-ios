//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIEdgeAgent

/// The `ConnectionExchange` is where the user can interact with incoming connections.
/// This class contains interactions with the `agent.connections.exchange` module in the Edge SDK.
class ConnectionExchangeViewModel: ObservableObject {

    // If using a simulator, this will be resolved so you may take an actual invitation url and replace this one.
    // This URL will resolve an invitation, however, it will fail to be accepted.
    static let simulatedQRCode = "http://example.com/ssi?c_i=eyJAdHlwZSI6ImRpZDpzb3Y6QnpDYnNOWWhNcmpIaXFaRFRVQVNIZztzcGVjL2Nvbm5lY3Rpb25zLzEuMC9pbnZpdGF0aW9uIiwiQGlkIjoiMTIzNDU2Nzg5MDA5ODc2NTQzMjEiLCJsYWJlbCI6IkFsaWNlIiwicmVjaXBpZW50S2V5cyI6WyI4SEg1Z1lFZU5jM3o3UFlYbWQ1NGQ0eDZxQWZDTnJxUXFFQjNuUzdaZnU3SyJdLCJzZXJ2aWNlRW5kcG9pbnQiOiJodHRwczovL2V4YW1wbGUuY29tL2VuZHBvaW50Iiwicm91dGluZ0tleXMiOlsiOEhINWdZRWVOYzN6N1BZWG1kNTRkNHg2cUFmQ05ycVFxRUIzblM3WmZ1N0siXX0="

    /// Trigger to present the QR scanner
    @Published var isPresentingScanner = false

    /// A list of any pending `ConnectionExchange`
    @Published var exchanges: [ConnectionExchange] = []

    /// A received `ConnectionExchange`
    @Published var incomingExchange: ConnectionExchange?

    /// Trigger for showing an alert
    @Published var showAlert = false

    /// Alert message to display error messages
    @Published var alertMessage = ""

    /// Shown when an invitation has been successfully accepted.
    @Published var showSuccessAlert = false

    /// Shows loading state and disables buttons as necessary
    @Published var isLoading = false

    /// subscriberId is used to be able to unsubscribe from agent events after navigating away from the view
    private var subscriberId: String?

    init() {}

    /// Subscribe to the agent events
    func subscribe() {
        subscriberId = Clients.agent.subscribeToAgentEvents(subscriber: ConnectionSubscriber(viewModel: self))
        refresh()
    }

    /// Unsubscribe from agent events
    func unsubscribe() {
        Clients.agent.unsubscribeToAgentEvents(subscriptionId: subscriberId ?? "")
    }

    /// Method for listing all `ConnectionExchange` that are in a pending state
    func refresh() {
        Task { @MainActor in
            isLoading = true
            do {
                let connections = try await Clients.agent.connections.exchange.listAll(options: nil)
                exchanges = connections
            } catch {
                NSLog("Failed to list all connection exchanges \(error.localizedDescription)")
            }
            isLoading = false
        }
    }

    /// Method for accepting a `ConnectionExchange`
    func accept(_ exchangeId: String) {
        Task { @MainActor in
            isLoading = true
            do {
                NSLog("Accepting invitation...")
                incomingExchange = nil
                /// Need to first create a `Postbox` to receive messages for a given `ConnectionExchange`
                let postbox = try await Clients.relayManager.createPostbox(connectionId: exchangeId)
                /// Get the routing for the relay service to communicate
                let relayRouting = SudoDIRelayMessageSource.routingFromPostbox(postbox: postbox)
                let configuration = ConnectionConfiguration()
                _ = try await Clients.agent.connections.exchange.acceptConnection(
                    connectionExchangeId: exchangeId,
                    routing: relayRouting,
                    configuration: configuration
                )
                refresh()
                showSuccessAlert = true

            } catch {
                NSLog("Error accepting invitation: \(error.localizedDescription)")
                alertMessage = error.localizedDescription
                showAlert = true
            }
            isLoading = false
        }
        
    }

    /// Method for swiping to delete a connection exchange
    func delete(at offsets: IndexSet) {
        let idsToDelete = offsets.map { exchanges[$0].connectionExchangeId }
        _ = idsToDelete.compactMap({ id in
            Task { @MainActor [weak self] in
                do {
                    try await self?.deleteFromExchange(id)
                    self?.refresh()
                } catch {
                    self?.showAlert = true
                    self?.alertMessage = error.localizedDescription
                    NSLog("Failed to delete connection: \(error.localizedDescription)")
                }
            }
        })
    }

    /// Method for declining a connection.
    func decline(_ exchangeId: String) {
        Task { @MainActor in
            NSLog("Declining invitation...")
            do {
                try await deleteFromExchange(exchangeId)
                refresh()
            } catch {
                showAlert = true
                alertMessage = error.localizedDescription
                NSLog("Failed to delete connection: \(error.localizedDescription)")
            }
            incomingExchange = nil
        }
    }

    /// Method for deleting a `ConnectionExchange`
    private func deleteFromExchange(_ exchangeId: String) async throws {
        try await Clients.agent.connections.exchange.deleteById(connectionExchangeId: exchangeId)
    }

    /// Helper function to get the String representation of the `ConnectionExchangeState`
    func getConnectionState(_ state: ConnectionExchangeState) -> String {
        switch state {
        case .invitation:
            return "Invitation"
        case .request:
            return "Request"
        case .complete:
            return "Complete"
        case .response:
            return "Response"
        case .abandoned:
            return "Abandoned"
        }
    }

    /// Takes a given url/QR code and queues it into the connection exchange queue to be processed
    func queueInvitation(_ scannedCode: String) {
        Task { @MainActor in
            isPresentingScanner = false
            isLoading = true
            do {
                try await Clients.messageSource.queueUrlMessage(url: scannedCode)

            } catch {
                NSLog("Error occured trying to get code: \(error)")
            }
            isLoading = false
        }
    }
}

/// Subscriber class to receive `ConnectionExchange` events from the agent and respond accordingly
class ConnectionSubscriber: AgentEventSubscriber {
    private var viewModel: ConnectionExchangeViewModel

    init(viewModel: ConnectionExchangeViewModel) {
        self.viewModel = viewModel
    }

    /// Method for interacting with te `ConnectionExchange` changes.
    /// This view model only cares about what happens here so we can ignore the other functions
    func connectionExchangeStateChanged(connectionExchange: ConnectionExchange) {
        Task { @MainActor in
            NSLog("Connection exchange state change for \(connectionExchange.connectionExchangeId): \(connectionExchange.state)")
            viewModel.refresh()
            // Only present the connection exchange if it is an invitation
            if connectionExchange.state == .invitation {
                viewModel.incomingExchange = connectionExchange
            }
        }

    }

    func credentialExchangeStateChanged(credentialExchange: CredentialExchange) {
        // no-op
    }

    func proofExchangeStateChanged(proofExchange: ProofExchange) {
        // no-op
    }

    func messageProcessed(messageId: String) {
        // no-op
    }
}

// Extend `ConnectionExchange` to `Identifiable` for convenience in the View
extension ConnectionExchange: Identifiable {
    public var id: String { self.connectionExchangeId }
}
