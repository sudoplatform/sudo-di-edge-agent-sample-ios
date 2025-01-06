//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftUI
import SudoDIEdgeAgent

/// The `ProofExchange` is where a user can interact with a selected proof and provide a presentation.
/// This class contains interactions with the `agent.proofs.exchange` module in the Edge SDK.
class DifProofExchangeViewModel: ObservableObject {

    /// Shows when the list is loading
    @Published var isLoading: Bool = false

    /// After successfully presenting a proof an alert will show which can dismiss the proof
    @Published var dismissProof: Bool = false

    /// Shows when there is an error
    @Published var showAlert: Bool = false

    /// The message to show in the alert
    @Published var alertMessage: String = ""

    /// The `ProofExchange` in which the verifier is requesting
    @Published var proof: ProofExchange
    
    @Published var difProofRequest: PresentationDefinitionV2

    /// Suitable credentialIds for the requested input descriptors
    @Published var credentialsForRequestedDescriptors: [String: [UICredential]] = [:]

    @Published var selectingCredentialForDescriptor: InputDescriptorV2?
    
    @Published var selectedCredentialIdsForDescriptors: [String: String] = [:]

    init(proof: ProofExchange, proofRequest: PresentationDefinitionV1) {
        self.proof = proof
        self.difProofRequest = proofRequest.toV2()
    }
    
    init(proof: ProofExchange, proofRequest: PresentationDefinitionV2) {
        self.proof = proof
        self.difProofRequest = proofRequest
    }

    /// Retrieves all the suitable credentialIds for each requested DIF input descriptor, then map input descriptor IDs
    /// to their full set of suitable `Credential`s.
    func initialize() {
        Task { @MainActor in
            isLoading = true
            NSLog("Retrieving proof request details...")
            do {
                guard case .dif(
                    let credentialIdsForRequestedDescriptors
                ) = try await Clients.agent.proofs.exchange.retrieveCredentialsForProofRequest(
                    proofExchangeId: proof.proofExchangeId
                ) else {
                    fatalError("Wrong type")
                }
                
                let uniqueCredIds = Set(credentialIdsForRequestedDescriptors.flatMap { $0.value })
                let uniqueCreds = try await retrieveFullCredentials(Array(uniqueCredIds))
                    .asyncCompactMap {
                        try await UICredential.fromCredential(agent: Clients.agent, credential: $0)
                    }
                credentialsForRequestedDescriptors = credentialIdsForRequestedDescriptors.mapValues { credIds in
                    credIds.map { credId in
                        uniqueCreds.first { $0.id == credId }!
                    }
                }
            } catch {
                NSLog("Error retrieving credentials for proof request \(error.localizedDescription)")
            }
            isLoading = false
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
    
    /// Begin the UI data state for selecting a suitable credential for a chosen input descriptor
    func startSelectingCredentialForInputDescriptor(descriptorId: String) {
        selectingCredentialForDescriptor = difProofRequest.inputDescriptors.first {
            $0.id == descriptorId
        }
    }

    /// Sets the credential ID to be used to presenting a referent.
    func selectCredentialForInputDescriptor(_ credId: String, _ descriptorId: String) {
        NSLog("Setting credential \(credId) for \(descriptorId)...")
        selectedCredentialIdsForDescriptors[descriptorId] = credId
        selectingCredentialForDescriptor = nil
    }

    /// After credentials have been selected, calling `present` will construct the `PresentationCredentials` with
    /// the selected credentials and send a proof to the verifier.
    func present() {
        Task { @MainActor in
            isLoading = true
            NSLog("Presenting credentials for proof...")
            let presentationCreds = PresentationCredentials.dif(
                credentialsForDescriptors: selectedCredentialIdsForDescriptors
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
}

extension InputDescriptorV2: Identifiable {
}

extension StringOrNumber {
    var asString: String {
        switch self {
        case .stringValue(let x):
            x
        case .number(let x):
            "\(x)"
        }
    }
}

extension PresentationDefinitionV1 {
    func toV2() -> PresentationDefinitionV2 {
        .init(
            id: id ?? "N/A",
            inputDescriptors: inputDescriptors.map { $0.toV2() },
            name: name,
            purpose: purpose,
            submissionRequirements: submissionRequirements
        )
    }
}

extension InputDescriptorV1 {
    func toV2() -> InputDescriptorV2 {
        .init(
            id: id,
            name: name,
            purpose: purpose,
            constraints: constraints ?? .init(
                limitDisclosure: nil,
                statuses: nil,
                subjectIsIssuer: nil,
                isHolder: [],
                sameSubject: [],
                fields: []
            ),
            group: group
        )
    }
}
