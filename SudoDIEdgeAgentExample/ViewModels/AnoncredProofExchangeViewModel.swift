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
class AnoncredProofExchangeViewModel: ObservableObject {

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
    
    var anoncredProofRequest: AnoncredProofRequestInfo {
        guard case .indy(let req) = proof.formatData else {
            fatalError("Unknown format")
        }
        return req
    }

    /// Suitable credentialIds for the requested attribute groups (by referent)
    @Published var credentialIdsForAttributeGroups: [String: [String]] = [:]

    /// Suitable credentialIds for the requested predicates (by referent)
    @Published var credentialIdsForPredicates: [String: [String]] = [:]
    
    /// Suitable attribute referents which can be self attested
    @Published var selfAttestableAttributeReferents: [String] = []

    /// The presentation data to be selected for meeting the requirements of a attribute or predicate.
    /// Non-nil indicates that there is currently a selection being made for a credential for a given item,
    /// (as described by the data of `PresentationItem`)
    @Published var selectingCredentialsForItem: CredentialsForAnoncredPresentationItem?

    /// Requested attribute group referents mapped to the credential ID that has been selected for
    /// presenting the referent.
    @Published var selectedCredentialsForAttributeGroups: [String: String] = [:]

    /// Requested predicate referents mapped to the credential ID that has been selected for presenting
    /// that referent.
    @Published var selectedCredentialsForPredicates: [String: String] = [:]
    
    /// Requested attribute referents mapped to the self attested value that has been specified for presenting
    /// the referent.
    @Published var selfAttestedAttributeReferents: [String: String] = [:]
    
    /// Helper function to access a binding for a specific self-attested attribute
    func selfAttestedAttributeBinding(for key: String) -> Binding<String> {
        return Binding<String>(
            get: {
                self.selfAttestedAttributeReferents[key] ?? ""
            },
            set: {
                self.selfAttestedAttributeReferents[key] = $0
                self.checkIfPresentationEnabled() // refresh if presentation is allow
            }
        )
    }

    init(proof: ProofExchange) {
        self.proof = proof
    }

    /// Retrieves all requested attributes and predicates for a proof and sets up respective dictionaries.
    func retrieveRequests() {
        Task { @MainActor in
            isLoading = true
            NSLog("Retrieving attribute and predicate requests...")
            do {
                guard case .indy(
                    let credentialsForRequestedAttributes,
                    let credentialsForRequestedPredicates,
                    let selfAttestableAttributes
                ) = try await Clients.agent.proofs.exchange.retrieveCredentialsForProofRequest(
                    proofExchangeId: proof.proofExchangeId
                ) else {
                    fatalError("Wrong type")
                }
                credentialIdsForAttributeGroups = credentialsForRequestedAttributes
                credentialIdsForPredicates = credentialsForRequestedPredicates
                selfAttestableAttributeReferents = selfAttestableAttributes
                for referent in credentialsForRequestedAttributes.keys {
                    // Set to empty string to keep place in dictionary or if it is set to nil will remove the entry
                    selectedCredentialsForAttributeGroups[referent] = ""
                }

                for referent in credentialsForRequestedPredicates.keys {
                    // Set to empty string to keep place in dictionary or if it is set to nil will remove the entry
                    selectedCredentialsForPredicates[referent] = ""
                }
                
                for referent in selfAttestableAttributes {
                    // Set to empty string to keep place in dictionary or if it is set to nil will remove the entry
                    selfAttestedAttributeReferents[referent] = ""
                }
            } catch {
                NSLog("Error retrieving credentials for proof request \(error.localizedDescription)")
            }
            isLoading = false
        }
    }

    /// Begins the data state for selecting a credential for an attribute group identified by `referent`.
    func startSelectingCredentialForAttributeGroup(_ referent: String) {
        Task { @MainActor in
            NSLog("Selecting credentials for attribute: \(referent)")
            let credIds = credentialIdsForAttributeGroups[referent]!
            let credentials = await retrieveFullCredentials(credIds)
            let attributes = anoncredProofRequest.requestedAttributes[referent]!.groupAttributes
            
            selectingCredentialsForItem = CredentialsForAnoncredPresentationItem(
                referent: referent,
                suitableCredentials: credentials,
                presentingAttributes: attributes
            )
        }
    }
    
    /// Begins the data state for selecting a credential for a predicate identified by `referent`.
    func startSelectingCredentialForPredicate(_ referent: String) {
        Task { @MainActor in
            NSLog("Selecting credentials for predicate: \(referent)")
            let credIds = credentialIdsForPredicates[referent]!
            let credentials = await retrieveFullCredentials(credIds)
            let predInfo = anoncredProofRequest.requestedPredicates[referent]!
            
            selectingCredentialsForItem = CredentialsForAnoncredPresentationItem(
                referent: referent,
                suitableCredentials: credentials,
                predicateAttributeName: predInfo.attributeName
            )
        }
    }

    /// Retrieves the full `Credential` for each of the input `ids`
    private func retrieveFullCredentials(_ ids: [String]) async -> [Credential] {
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

    /// Sets the credential ID to be used to presenting a referent.
    func selectCredentialForReferent(_ credId: String, _ referent: String, _ isPredicate: Bool) {
        NSLog("Setting credential \(credId) for \(isPredicate ? "predicate" : "attribute group") \(referent)...")
        if isPredicate {
            selectedCredentialsForPredicates[referent] = credId
        } else {
            selectedCredentialsForAttributeGroups[referent] = credId
        }
        checkIfPresentationEnabled()
        selectingCredentialsForItem = nil
    }
    
    /// Formats a retrieved predicate into a readable string
    func formatPredicate(_ predicate: AnoncredProofRequestPredicateInfo) -> String {
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

    /// After credentials have been selected for each attribute & predicate referent, calling `present` will construct
    /// the `PresentationCredentials` with the selected credentials and send a proof to the verifier.
    func present() {
        Task { @MainActor in
            isLoading = true
            NSLog("Presenting credentials for proof...")
            let presentationCreds = PresentationCredentials.indy(
                credentialsForRequestedAttributes: selectedCredentialsForAttributeGroups.mapValues { 
                    AnoncredPresentationAttributeGroup(credentialId: $0, revealed: true)
                },
                credentialsForRequestedPredicates: selectedCredentialsForPredicates.mapValues {
                    AnoncredPresentationPredicate(credentialId: $0)
                },
                selfAttestedAttributes: selfAttestedAttributeReferents
            )

            do {
                _ = try await Clients.agent.proofs.exchange.presentProof(
                    proofExchangeId: proof.proofExchangeId,
                    presentationCredentials: presentationCreds
                )
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
    private func checkIfPresentationEnabled() {
        let attributesCompleted = selectedCredentialsForAttributeGroups.filter { $0.value == "" }.isEmpty
        let predicatesCompleted = selectedCredentialsForPredicates.filter { $0.value == "" }.isEmpty
        let selfAttestedCompleted = selfAttestedAttributeReferents.filter { $0.value == "" }.isEmpty
        presentEnabled = attributesCompleted && predicatesCompleted && selfAttestedCompleted
    }
}

/// Object that contains the needed UI information to select credential for a presentation proof
struct CredentialsForAnoncredPresentationItem {
    var referent: String
    var suitableCredentials: [Credential]
    var presentingAttributes: [String] = []
    var predicateAttributeName: String = ""
}

extension CredentialsForAnoncredPresentationItem: Identifiable {
    var id: String {
        referent
    }
}
