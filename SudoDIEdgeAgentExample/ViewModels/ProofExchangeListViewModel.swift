//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIEdgeAgent

/// The `ProofExchange` is where a user can interact with credential proofs.
/// This class contains interactions with the `agent.proofs.exchange` module in the Edge SDK.
class ProofExchangeListViewModel: ObservableObject {

    /// Shows when the list is loading
    @Published var isLoading: Bool = false

    /// Shows when there is an error
    @Published var showAlert: Bool = false

    /// The message to show in the alert
    @Published var alertMessage: String = ""

    /// The list of proof exchanges from the agent
    @Published var exchanges: [ProofExchange] = []

    /// subscriberId is used to be able to unsubscribe from agent events after navigating away from the view
    private var subscriberId: String?

    init() {}

    /// Subscribe to the agent events
    func subscribe() {
        // The custom subscriber will callback the view model whenever it receives any events
        let subscriber = ProofSubscriber(viewModel: self)
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
                let result = try await Clients.agent.proofs.exchange.listAll(options: nil)
                exchanges = result
            } catch {
                NSLog("Error getting credential exchanges \(error.localizedDescription)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    /// Method for swiping to delete a proof exchange
    func delete(at offsets: IndexSet) {
        let idsToDelete = offsets.map { exchanges[$0].proofExchangeId }
        _ = idsToDelete.compactMap({ id in
            Task { @MainActor [weak self] in
                do {
                    try await Clients.agent.proofs.exchange.deleteById(proofExchangeId: id)
                    self?.refresh()
                } catch {
                    self?.showAlert = true
                    self?.alertMessage = error.localizedDescription
                    NSLog("Failed to delete proof exchange: \(error.localizedDescription)")
                }
            }
        })
    }

    func getState(_ state: ProofExchangeState) -> String {
        switch state {
        case .proposal:
            return "Proposal"
        case .request:
            return "Request"
        case .presented:
            return "Presented"
        case .acked:
            return "Acked"
        }
    }
}

/// Subscriber class to receive `ProofExchange` events from the agent and respond accordingly
class ProofSubscriber: AgentEventSubscriber {
    private var viewModel: ProofExchangeListViewModel

    init(viewModel: ProofExchangeListViewModel) {
        self.viewModel = viewModel
    }

    func connectionExchangeStateChanged(connectionExchange: ConnectionExchange) {
        // no-op
    }


    func credentialExchangeStateChanged(credentialExchange: CredentialExchange) {
        // no-op
    }

    // This view will only monitor the credential exchange and refresh if any changes occur
    func proofExchangeStateChanged(proofExchange: ProofExchange) {
        NSLog("Proof exchange state changed for \(proofExchange.proofExchangeId)")
        Task { @MainActor in
            viewModel.refresh()
        }
    }
    
    func inboundBasicMessage(basicMessage: BasicMessage.Inbound) {
        // no-op
    }

    func messageProcessed(messageId: String) {
        // no-op
    }
}

/// Conforms to Identifiable to provide some Swift magic for the `ForEach`
extension ProofExchange: Identifiable {
    public var id: String { self.proofExchangeId }
}
