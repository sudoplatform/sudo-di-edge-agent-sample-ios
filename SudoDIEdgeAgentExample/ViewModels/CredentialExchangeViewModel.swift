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
    @Published var exchange: UICredentialExchange
    
    /// Shows when the exchange is loading (i.e. because an action is in progress)
    @Published var isLoading: Bool = false

    /// Shows when there is an error
    @Published var showAlert: Bool = false

    /// The message to show in the alert
    @Published var alertMessage: String = ""

    init(exchange: UICredentialExchange) {
        self.exchange = exchange
    }
    
    /// Accepts a given aries-based `CredentialExchange` offer.
    /// The viewmodel `exchange` is updated on success.
    func acceptAries() {
        Task { @MainActor in
            isLoading = true
            do {
                let holderDid = try await idempotentCreateAppropriateHolderDid(
                    agent: Clients.agent,
                    allowedMethods: [.didKey],
                    allowedKeyTypes: [.ed25519]
                )

                let configuration = AcceptCredentialOfferConfiguration.aries(.init(
                    autoStoreCredential: true,
                    formatSpecificConfiguration: .ariesLdProofVc(
                        overrideCredentialSubjectId: holderDid
                    )
                ))

                let updatedExchange = try await Clients.agent.credentials.exchange.acceptOffer(
                    credentialExchangeId: exchange.exchange.credentialExchangeId,
                    configuration: configuration
                )
                exchange = try await UICredentialExchange.fromCredentialExchange(
                    agent: Clients.agent,
                    exchange: updatedExchange
                )
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
                    credentialExchangeId: exchange.exchange.credentialExchangeId,
                    configuration: .withPreAuthorization(txCode: txCode)
                )
                exchange = try await UICredentialExchange.fromCredentialExchange(
                    agent: Clients.agent,
                    exchange: .openId4Vc(updatedExchange)
                )
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
                let allowedBindingMethods: OpenId4VcAllowedHolderBindingMethods
                switch exchange {
                case .openId4Vc(let oid4vc):
                    let config = oid4vc.exchange.offeredCredentialConfigurations[credentialConfigurationId]
                    switch config {
                    case .sdJwtVc(let sdJwtConfig):
                        allowedBindingMethods = sdJwtConfig.allowedBindingMethods
                    case nil:
                        throw "Could not find openid4vc credential configuration"
                    }
                default: throw "Bad state: expected oid4vc exchange"
                }
                
                let holderDid = try await idempotentCreateAppropriateHolderDid(
                    agent: Clients.agent,
                    allowedMethods: allowedBindingMethods.allowedDidMethods,
                    allowedKeyTypes: allowedBindingMethods.allowedKeyTypes
                )
                
                let updatedExchange = try await Clients.agent.credentials.exchange.acceptOffer(
                    credentialExchangeId: exchange.exchange.credentialExchangeId,
                    configuration: .openId4Vc(.init(
                        credentialConfigurationId: credentialConfigurationId,
                        holderBinding: .withDid(did: holderDid)
                    ))
                )
                exchange = try await UICredentialExchange.fromCredentialExchange(
                    agent: Clients.agent,
                    exchange: updatedExchange
                )
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
                    credentialExchangeId: exchange.exchange.credentialExchangeId,
                    configuration: nil
                )
                // manually force openid4vc exchange into `done` state to trigger UI update
                // in openid4vc flow
                if case .openId4Vc(let ex) = exchange.exchange {
                    let updatedExchange = CredentialExchange.openId4Vc(.init(
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
                    exchange = try await UICredentialExchange.fromCredentialExchange(
                        agent: Clients.agent,
                        exchange: updatedExchange
                    )
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

/// Get an existing holder DID owned by the ``SudoDIEdgeAgent`` which meets the required
/// [allowedMethods] & [allowedKeyTypes] criteria, or create a new one.
private func idempotentCreateAppropriateHolderDid(
    agent: SudoDIEdgeAgent,
    allowedMethods: [DidMethod],
    allowedKeyTypes: [DidKeyType]
) async throws -> String {
    let dids = try await agent.dids.listAll(options: .init(
        filters: .init(
            allowedDidMethods: allowedMethods,
            allowedKeyTypes: allowedKeyTypes
        )
    ))
    
    // return if exists
    if let did = dids.first {
        return did.did
    }
    
    let newDid = try await createAppropriateHolderDid(
        agent: agent,
        allowedMethods: allowedMethods,
        allowedKeyTypes: allowedKeyTypes
    )
    return newDid.did
}

private func createAppropriateHolderDid(
    agent: SudoDIEdgeAgent,
    allowedMethods: [DidMethod],
    allowedKeyTypes: [DidKeyType]
) async throws -> DidInformation {
    guard let method = allowedMethods.first else {
        throw "no suitable DID Method"
    }
    guard let keyType = allowedKeyTypes.first else {
        throw "no suitable key type"
    }
    
    let options: CreateDidOptions
    switch method {
    case .didKey: options = .didKey(keyType: keyType)
    case .didJwk: options = .didJwk(keyType: keyType)
    }
    
    return try await agent.dids.createDid(options: options)
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
