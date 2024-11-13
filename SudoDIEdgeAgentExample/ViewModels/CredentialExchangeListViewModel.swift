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
                exchanges = result.sorted { $0.startedAt ?? .now > $1.startedAt ?? .now }
            } catch {
                NSLog("Error getting credential exchanges \(error.localizedDescription)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
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
        case .aries(.proposal):
            return "Proposal"
        case .aries(.offer):
            return "Offer"
        case .aries(.request):
            return "Request"
        case .aries(.issued):
            return "Issued"
        case .openId4Vc(.issued):
            return "Issued"
        case .aries(.acked):
            return "Acked"
        case .aries(.abandoned):
            return "Abandoned"
        case .openId4Vc(.unauthorized):
            return "Unauthorized"
        case .openId4Vc(.authorized):
            return "Authorized"
        case .openId4Vc(.done):
            return "Done"
        case .openId4Vc(.abandoned):
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
    
    func inboundBasicMessage(basicMessage: BasicMessage.Inbound) {
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

/// Convenience to get the `started_timestamp`
extension CredentialExchange {
    /// The date value retrieved from the `~started_timestamp` in the tags property
    var startedAt: Date? {
        return self.tags
            .first { $0.name == "~started_timestamp" }
            .flatMap { Double($0.value) }
            .flatMap { Date(timeIntervalSince1970: $0) }
    }
}

extension CredentialExchange {
    var previewExchangeType: String {
        switch self {
        case .aries: "Aries"
        case .openId4Vc: "OID4VC"
        }
    }
    
    var previewCredName: String? {
        switch self {
        case .aries(let aries): aries.formatData.previewCredName
        case .openId4Vc: nil
        }
    }
    
    var previewCredFormat: String? {
        switch self {
        case .aries(let aries): aries.formatData.previewCredFormat
        case .openId4Vc: nil
        }
    }
}

extension AriesCredentialExchangeFormatData {
    var previewCredName: String {
        switch self {
        case .ariesLdProof(let w3cCred, _):
            return w3cCred.types.first { $0 != "VerifiableCredential" } ?? "VerifiableCredential"
        case .indy(let metadata, _):
            return metadata.credentialDefinitionInfo?.name ?? metadata.credentialDefinitionId
        }
    }
    
    var previewCredFormat: String {
        switch self {
            
        case .indy:
            return "Anoncred"
        case .ariesLdProof:
            return "W3C"
        }
    }
}
