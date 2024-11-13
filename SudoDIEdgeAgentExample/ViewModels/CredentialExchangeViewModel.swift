//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIEdgeAgent
import SwiftUI

class CredentialExchangeViewModel: ObservableObject {

    /// The shown credential for the view
    @Published var exchange: CredentialExchange
    
    /// Shows when the exchange is loading (i.e. because an action is in progress)
    @Published var isLoading: Bool = false

    /// Shows when there is an error
    @Published var showAlert: Bool = false

    /// The message to show in the alert
    @Published var alertMessage: String = ""

    init(exchange: CredentialExchange) {
        self.exchange = exchange
    }
    
    /// Accepts a given aries-based `CredentialExchange` offer.
    /// The viewmodel `exchange` is updated on success.
    func acceptAries() {
        Task { @MainActor in
            isLoading = true
            do {
                let holderDid = try await idempotentCreateHolderDidKey(
                    agent: Clients.agent,
                    keyType: .ed25519
                )

                let configuration = AcceptCredentialOfferConfiguration.aries(.init(
                    autoStoreCredential: true,
                    formatSpecificConfiguration: .ariesLdProofVc(
                        overrideCredentialSubjectId: holderDid
                    )
                ))

                let updatedExchange = try await Clients.agent.credentials.exchange.acceptOffer(
                    credentialExchangeId: exchange.credentialExchangeId,
                    configuration: configuration
                )
                exchange = updatedExchange
            } catch {
                NSLog("Error accepting credential exchange \(error)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    /// Authorize an openid4vc-based `CredentialExchange` using the provided tx-code (if any).
    /// The viewmodel `exchange` is updated on success.
    func authorizeExchange(txCode: String?) {
        Task { @MainActor in
            isLoading = true
            do {
                let updatedExchange = try await Clients.agent.credentials.exchange.openId4Vc.authorizeExchange(
                    credentialExchangeId: exchange.credentialExchangeId,
                    configuration: .withPreAuthorization(txCode: txCode)
                )
                exchange = .openId4Vc(updatedExchange)
            } catch {
                NSLog("Error authorizing credential exchange \(error)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    /// Accepts a given openid4vc-based `CredentialExchange` offer.
    /// The viewmodel `exchange` is updated on success.
    func acceptOpenId4Vc(credentialConfigurationId: String) {
        Task { @MainActor in
            isLoading = true
            do {
                var appropriateKeyTypes: [DidKeyType] = []
                switch exchange {
                case .openId4Vc(let oid4vc):
                    let config = oid4vc.offeredCredentialConfigurations[credentialConfigurationId]
                    switch config {
                    case .sdJwtVc(let sdJwtConfig):
                        appropriateKeyTypes = sdJwtConfig.allowedBindingMethods.allowedKeyTypes
                    case nil: break
                    }
                default: break
                }
                guard let keyType = appropriateKeyTypes.first else {
                    throw "no appropriate did:key key type found accepting offer"
                }
                let holderDid = try await idempotentCreateHolderDidKey(
                    agent: Clients.agent,
                    keyType: keyType
                )
                
                let updatedExchange = try await Clients.agent.credentials.exchange.acceptOffer(
                    credentialExchangeId: exchange.credentialExchangeId,
                    configuration: .openId4Vc(.init(
                        credentialConfigurationId: credentialConfigurationId,
                        holderBinding: .withDid(did: holderDid)
                    ))
                )
                exchange = updatedExchange
            } catch {
                NSLog("Error accepting credential exchange \(error)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    /// Store the `Credential` associated with a `CredentialExchange` (if auto-store is not on).
    func storeCredential() {
        Task { @MainActor in
            isLoading = true
            do {
                _ = try await Clients.agent.credentials.exchange.storeCredential(
                    credentialExchangeId: exchange.credentialExchangeId,
                    configuration: nil
                )
                // manually force openid4vc exchange into `done` state to trigger UI update
                // in openid4vc flow
                if case .openId4Vc(let ex) = exchange {
                    exchange = .openId4Vc(.init(
                        credentialExchangeId: ex.credentialExchangeId,
                        credentialIds: ex.credentialIds,
                        errorMessage: ex.errorMessage,
                        tags: ex.tags,
                        state: .done,
                        credentialIssuerUrl: ex.credentialIssuerUrl, 
                        credentialIssuerDisplay: ex.credentialIssuerDisplay,
                        requiredAuthorization: ex.requiredAuthorization,
                        offeredCredentialConfigurations: ex.offeredCredentialConfigurations,
                        issuedCredentialPreviews: ex.issuedCredentialPreviews
                    ))
                }
            } catch {
                NSLog("Error storing credential exchange \(error)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

/// Creates an DID:KEY if one does not already exist.
///
/// Returns the new or existing did:key DID
private func idempotentCreateHolderDidKey(
    agent: SudoDIEdgeAgent,
    keyType: DidKeyType
) async throws -> String {
    let dids = try await agent.dids.listAll(
        options: ListDidsOptions(filters: ListDidsFilters(method: .didKey))
    )
    let existingDid = dids.first { isDidKeyOfKeyType(did: $0, keyType: keyType) }
    
    if let did = existingDid?.did {
        return did
    }
    
    let newDid = try await agent.dids.createDid(
        options: .didKey(keyType: keyType)
    )
    return newDid.did
}

private func isDidKeyOfKeyType(did: DidInformation, keyType: DidKeyType) -> Bool {
    // FUTURE - this information will be contained in `DidInformation`
    switch keyType {
    case .ed25519:
        // https://w3c-ccg.github.io/did-method-key/#ed25519-x25519
        return did.did.starts(with: "did:key:z6Mk")
    case .p256:
        // https://w3c-ccg.github.io/did-method-key/#p-256
        return did.did.starts(with: "did:key:zDn")
    }
}

/// Conforms `AnoncredV1CredentialAttribute` to `Hashable` by combining all attributes together to
/// create a unique value. This is done here because the extension is outside of the Edge SDK where this is declared.
extension AnoncredV1CredentialAttribute: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(value)
        hasher.combine(mimeType)
    }
}
