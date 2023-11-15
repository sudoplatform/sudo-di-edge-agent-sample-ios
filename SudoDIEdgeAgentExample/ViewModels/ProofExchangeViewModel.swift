//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftUI
import SudoDIEdgeAgent

/// The `ProofExchange` is where a user can interact with a selected proof and provide a presentation.
/// This class contains interactions with the `agent.proofs.exchange` module in the Edge SDK.
class ProofExchangeViewModel: ObservableObject {

    /// Shows when the list is loading
    @Published var isLoading: Bool = false

    /// Enables the present button when all requirements have been satisfied
    @Published var presentEnabled: Bool = false

    /// After successfully presenting a proof an alert will show which can dismiss the proof
    @Published var dismissProof: Bool = false

    /// Shows when there is an error
    @Published var showAlert: Bool = false

    /// The message to show in the alert
    @Published var alertMessage: String = ""

    /// The `ProofExchange` in which the verifier is requesting
    @Published var proof: ProofExchange

    /// The attributes the verifier is requesting
    @Published var attributes: [RetrievedAttributeGroupCredentials] = []

    /// The predicates the verifier is requesting
    @Published var predicates: [RetrievedPredicateCredentials] = []

    /// The presentation data to be selected for meeting the requirements of a attribute or predicate
    @Published var presentation: PresentationItem?

    /// The dictionary that matches credentials to requested attributes.
    @Published var attributeCredentials: [String: String] = [:]

    /// The dictionary that matches credentials to requested predicates.
    @Published var predicateCredentials: [String: String] = [:]

    init(proof: ProofExchange) {
        self.proof = proof
    }

    /// Retrieves all requested attributes and predicates for a proof and sets up respective dictionaries.
    func retrieveRequests() {
        Task { @MainActor in
            isLoading = true
            NSLog("Retrieving attribute and predicate requests...")
            do {
                let credentials = try await Clients.agent.proofs.exchange.retrieveCredentialsForProofRequest(proofExchangeId: proof.proofExchangeId)
                attributes = credentials.requestedAttributes
                predicates = credentials.requestedPredicates
                for attribute in attributes {
                    // Set to empty string to keep place in dictionary or if it is set to nil will remove the entry
                    attributeCredentials[attribute.groupIdentifier] = ""
                }

                for predicate in predicates {
                    // Set to empty string to keep place in dictionary or if it is set to nil will remove the entry
                    predicateCredentials[predicate.predicateIdentifier] = ""
                }
            } catch {
                NSLog("Error retrieving credentials for proof request \(error.localizedDescription)")
            }
            isLoading = false
        }
    }

    /// Takes a selected attribute group and sets the presentation to select a credential for it.
    func attributeSelected(_ attribute: RetrievedAttributeGroupCredentials, for attributes: [String]) {
        Task { @MainActor in
            NSLog("Selecting credentials for attribute: \(attribute.groupIdentifier)")
            let credentials = await retrieveCredentials(attribute.credentialIds)
            presentation = PresentationItem(id: attribute.groupIdentifier, credentials: credentials, attributes: attributes)
        }
    }
    
    /// Takes a selected predicate and sets the presentation to select a credential for it.
    func predicateSelected(_ predicate: RetrievedPredicateCredentials) {
        Task { @MainActor in
            let credentials = await retrieveCredentials(predicate.credentialIds)
            presentation = PresentationItem(id: predicate.predicateIdentifier, credentials: credentials, predicate: predicate.attributeName)
        }
    }

    /// Retrieves the requested credentials that can satisfy the attribute or predicate
    func retrieveCredentials(_ ids: [String]) async -> [Credential] {
            let credentials = await ids.asyncCompactMap { id in
                do {
                    return try await Clients.agent.credentials.getById(credentialId: id)
                } catch {
                    NSLog("Error occurred trying to retrieve credential with id: \(id)")
                }
                return nil
            }

        return credentials
    }

    /// Matches the selected credential to the given predicate or attribute.
    func setCredential(_ group: String, _ id: String, _ isPredicate: Bool) {
        NSLog("Setting credential \(id) for \(isPredicate ? "predicate" : "attribute group") \(group)...")
        if isPredicate {
            predicateCredentials[group] = id
        } else {
            attributeCredentials[group] = id
        }
        enablePresentation()
        presentation = nil
    }
    
    /// Formats a retrieved predicate into a readable string
    func formatPredicate(_ predicate: RetrievedPredicateCredentials) -> String {
        let operatorSymbol: String
        switch predicate.predicateType {
        case .greaterThanOrEqual:
            operatorSymbol = ">="
        case .greaterThan:
            operatorSymbol = ">"
        case .lessThanOrEqual:
            operatorSymbol = "<="
        case .lessThan:
            operatorSymbol = "<"
        }
        return "\(predicate.attributeName) \(operatorSymbol) \(predicate.predicateValue)"
    }

    /// Goes through the flow for creating and presenting a proof.
    func present() {
        Task { @MainActor in
            isLoading = true
            NSLog("Presenting credentials for proof...")
            // Format the attribute dictionary with a Presentation format
            var attributeGroups: [String: PresentationAttributeGroup] = [:]
            for attribute in attributeCredentials {
                attributeGroups[attribute.key] = PresentationAttributeGroup(credentialId: attribute.value, revealed: true)
            }

            // Format the predicate dictionary with a Presentation format
            var predicateGroups: [String: PresentationPredicate] = [:]
            for predicate in predicateCredentials {
                predicateGroups[predicate.key] = PresentationPredicate(credentialId: predicate.key)
            }

            // The credentials for presenting the proof
            let presentationCreds = PresentationCredentials(requestedAttributes: attributeGroups, requestedPredicates: predicateGroups)

            do {
                _ = try await Clients.agent.proofs.exchange.presentProof(proofExchangeId: proof.proofExchangeId, presentationCredentials: presentationCreds)
                NSLog("Presenting the proof was successful...")
                dismissProof = true
            } catch {
                NSLog("Error occurred trying to present the proof: \(error.localizedDescription)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }

    /// Helper function to check if all of the requirements for credentials have been met.
    func enablePresentation() {
        let attributesCompleted = attributeCredentials.filter { $0.value == "" }.isEmpty
        let predicatesCompleted = predicateCredentials.filter { $0.value == "" }.isEmpty
        presentEnabled = attributesCompleted && predicatesCompleted
    }
}

/// Conforms to Identifiable to provide some Swift magic for the `ForEach`
extension RetrievedAttributeGroupCredentials: Identifiable {
    public var id: String { self.groupIdentifier }
}

/// Conforms to Identifiable to provide some Swift magic for the `ForEach`
extension RetrievedPredicateCredentials: Identifiable {
    public var id: String { self.predicateIdentifier }
}

/// Object that contains the needed information to select credential for a presentation proof
struct PresentationItem: Identifiable {
    let id: String
    var credentials: [Credential]
    var attributes: [String] = []
    var predicate: String = ""
}
