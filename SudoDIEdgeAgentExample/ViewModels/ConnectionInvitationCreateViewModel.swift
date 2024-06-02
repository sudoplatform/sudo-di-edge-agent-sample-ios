//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIEdgeAgent

/// This class contains interactions with the `agent.connections.exchange` module in the Edge Agent SDK.
class ConnectionInvitationCreateViewModel: ObservableObject {
    
    /// Shows loading state and disables buttons as necessary
    @Published var isLoading: Bool
    
    private var routing: Routing?
    
    @Published var createdConnectionExchangeId: String?
    
    @Published var createdInvitationUrl: String?
    
    /// Incoming request for the created invitation
    @Published var incomingRequest: ConnectionExchange?

    /// Trigger for showing an alert
    @Published var showAlert: Bool

    /// Alert message to display error messages
    @Published var alertMessage: String

    /// Shown when an invitation has been successfully accepted.
    @Published var showSuccessAlert: Bool

    /// subscriberId is used to be able to unsubscribe from agent events after navigating away from the view
    private var subscriberId: String?
    
    public init(
        isLoading: Bool = false,
        routing: Routing? = nil,
        createdConnectionExchangeId: String? = nil,
        createdInvitationUrl: String? = nil,
        incomingRequest: ConnectionExchange? = nil,
        showAlert: Bool = false,
        alertMessage: String = "",
        showSuccessAlert: Bool = false,
        subscriberId: String? = nil
    ) {
        self.isLoading = isLoading
        self.routing = routing
        self.createdConnectionExchangeId = createdConnectionExchangeId
        self.createdInvitationUrl = createdInvitationUrl
        self.incomingRequest = incomingRequest
        self.showAlert = showAlert
        self.alertMessage = alertMessage
        self.showSuccessAlert = showSuccessAlert
        self.subscriberId = subscriberId
    }

    func initialize() {
        subscriberId = Clients.agent.subscribeToAgentEvents(
            subscriber: ConnectionRequestSubscriber(viewModel: self)
        )
        Task { @MainActor in
            do {
                let id = UUID().uuidString
                let postbox = try await Clients.relayManager.createPostbox(
                    connectionId: id
                )
                let newRouting = Routing(
                    serviceEndpoint: postbox.serviceEndpoint,
                    routingVerkeys: []
                )
                let createdInvite = try await Clients.agent.connections.exchange.createInvitation(
                    configuration: .legacyPairwise(
                        routing: newRouting
                    )
                )
                createdInvitationUrl = createdInvite.invitationUrl
                createdConnectionExchangeId = createdInvite.exchange.connectionExchangeId
                routing = newRouting
            } catch {
                NSLog("Error creating invitation: \(error.localizedDescription)")
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }

    func teardown() {
        Clients.agent.unsubscribeToAgentEvents(subscriptionId: subscriberId ?? "")
    }

    /// Method for accepting a `ConnectionExchange`
    func accept() {
        Task { @MainActor in
            isLoading = true
            do {
                NSLog("Accepting connection...")
                
                _ = try await Clients.agent.connections.exchange.acceptConnection(
                    connectionExchangeId: createdConnectionExchangeId!,
                    routing: routing!,
                    configuration: nil
                )
                
                incomingRequest = nil
                showSuccessAlert = true
            } catch {
                NSLog("Error accepting connection: \(error.localizedDescription)")
                alertMessage = error.localizedDescription
                showAlert = true
            }
            isLoading = false
        }
        
    }

    /// Method for declining a connection.
    func decline() {
        Task { @MainActor in
            NSLog("Declining connection...")
            do {
                try await Clients.agent.connections.exchange.deleteById(
                    connectionExchangeId: createdConnectionExchangeId!
                )
                incomingRequest = nil
                showSuccessAlert = true
            } catch {
                showAlert = true
                alertMessage = error.localizedDescription
                NSLog("Failed to delete connection: \(error.localizedDescription)")
            }
            incomingRequest = nil
        }
    }
}

/// Subscriber class to receive `ConnectionExchange` events from the agent and respond accordingly
class ConnectionRequestSubscriber: AgentEventSubscriber {
    private var viewModel: ConnectionInvitationCreateViewModel

    init(viewModel: ConnectionInvitationCreateViewModel) {
        self.viewModel = viewModel
    }

    /// Method for interacting with te `ConnectionExchange` changes.
    /// This view model only cares about what happens here so we can ignore the other functions
    func connectionExchangeStateChanged(connectionExchange: ConnectionExchange) {
        Task { @MainActor in
            NSLog("Connection exchange state change for \(connectionExchange.connectionExchangeId): \(connectionExchange.state)")
            NSLog("Listening for connection exchange state change for \(viewModel.createdConnectionExchangeId ?? "")")
            
            if connectionExchange.connectionExchangeId != viewModel.createdConnectionExchangeId {
                return
            }
            if connectionExchange.state != .request {
                return
            }
            viewModel.incomingRequest = connectionExchange
        }

    }

    func credentialExchangeStateChanged(credentialExchange: CredentialExchange) {
        // no-op
    }

    func proofExchangeStateChanged(proofExchange: ProofExchange) {
        // no-op
    }
    
    func inboundBasicMessage(basicMessage: BasicMessage.Inbound) {
        // no-op
    }

    func messageProcessed(messageId: String) {
        // no-op
    }
}
