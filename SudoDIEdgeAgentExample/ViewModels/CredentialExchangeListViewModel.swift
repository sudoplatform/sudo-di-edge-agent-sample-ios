//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIEdgeAgent

/// The `CredentialExchange` is where connections can receive credentials and accept them.
/// This class contains interactions with the `agent.credentials.exchange` module in the Edge SDK.
class CredentialExchangeListViewModel: ObservableObject {

    /// Shows when the list is loading
    @Published var isLoading: Bool = false

    /// Shows when there is an error
    @Published var showAlert: Bool = false

    /// The message to show in the alert
    @Published var alertMessage: String = ""

    /// The list of credential exchanges from the agent
    @Published var exchanges: [CredentialExchange] = []

    /// The `CredentialExchange` that is presented in the sheet
    @Published var presentedExchange: CredentialExchange?

    /// subscriberId is used to be able to unsubscribe from agent events after navigating away from the view
    private var subscriberId: String?

    // Empty initializer
    init() {}

    /// Subscribe to the agent events
    func subscribe() {
        // The custom subscriber will callback the view model whenever it receives any events
        let subscriber = CredentialSubscriber(viewModel: self)
        subscriberId = Clients.agent.subscribeToAgentEvents(subscriber: subscriber)
        refresh()
    }

    /// Unsubscribe from agent events
    func unsubscribe() {
        Clients.agent.unsubscribeToAgentEvents(subscriptionId: subscriberId ?? "")
    }

    /// Lists all of the credential exchanges
    func refresh() {
        Task { @MainActor in
            isLoading = true
            do {
                let result = try await Clients.agent.credentials.exchange.listAll(options: nil)
                exchanges = result
            } catch {
                NSLog("Error getting credential exchanges \(error.localizedDescription)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    /// Accepts a given `CredentialExchange` offer
    func accept() {
        Task { @MainActor in
            isLoading = true
            do {
                // An offer requires a configuration to adjust how to store the credential
                // which in this cause is left to the defaults.
                let configuration = AcceptCredentialOfferConfiguration(autoStoreCredential: true)

                guard let credential = presentedExchange else {
                    NSLog("Missing credential")
                    // This case really won't happen, but if by some unknown power it does,
                    // this will set credential to nil and the sheet will disappear
                    presentedExchange = nil
                    return
                }
                // This is going to ignore the result as the subscriber will
                // monitor and update changes to the credential
                _ = try await Clients.agent.credentials.exchange.acceptOffer(
                    credentialExchangeId: credential.credentialExchangeId,
                    configuration: configuration
                )
            } catch {
                NSLog("Error accepting credential exchange \(error.localizedDescription)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            presentedExchange = nil
            isLoading = false
        }
    }

    /// Method for swiping to delete a credential exchange
    func delete(at offsets: IndexSet) {
        let idsToDelete = offsets.map { exchanges[$0].credentialExchangeId }
        _ = idsToDelete.compactMap({ id in
            Task { @MainActor [weak self] in
                do {
                    try await Clients.agent.credentials.exchange.deleteById(credentialExchangeId: id)
                    self?.refresh()
                } catch {
                    self?.showAlert = true
                    self?.alertMessage = error.localizedDescription
                    NSLog("Failed to delete credential exchange: \(error.localizedDescription)")
                }
            }
        })
    }

    /// Shows the info of a given credential exchange in a sheet
    func showInfo(_ credential: CredentialExchange) {
        presentedExchange = credential
    }

    /// Dismisses the credential exchange sheet
    func dismissInfo() {
        presentedExchange = nil 
    }

    /// Helper function to return the string representation of the state
    func getState(_ state: CredentialExchangeState) -> String {
        switch state {
        case .proposal:
            return "Proposal"
        case .offer:
            return "Offer"
        case .request:
            return "Request"
        case .issued:
            return "Issued"
        case .acked:
            return "Acked"
        case .abandoned:
            return "Abandoned"
        }
    }
}

/// Subscriber class to receive `CredentialExchange` events from the agent and respond accordingly
class CredentialSubscriber: AgentEventSubscriber {
    private var viewModel: CredentialExchangeListViewModel

    init(viewModel: CredentialExchangeListViewModel) {
        self.viewModel = viewModel
    }

    func connectionExchangeStateChanged(connectionExchange: ConnectionExchange) {
        // no-op
    }

    // This view will only monitor the credential exchange and refresh if any changes occur
    func credentialExchangeStateChanged(credentialExchange: CredentialExchange) {
        NSLog("Credential exchange state changed for \(credentialExchange.credentialExchangeId)")
        Task { @MainActor in
            viewModel.refresh()
        }
    }

    func proofExchangeStateChanged(proofExchange: ProofExchange) {
        // no-op
    }

    func messageProcessed(messageId: String) {
        // no-op
    }
}

/// Conforms to Identifiable to provide some Swift magic for the `ForEach`
extension CredentialExchange: Identifiable {
    public var id: String { self.credentialExchangeId }
}

/// Convenience to get the `created_timestamp`
extension CredentialExchange {
    /// The date value retrieved from the `~created_timestamp` in the tags property
    var createdAt: Date? {
        return self.tags
            .first { $0.name == "~created_timestamp" }
            .flatMap { Double($0.value) }
            .flatMap { Date(timeIntervalSince1970: $0) }
    }
}
