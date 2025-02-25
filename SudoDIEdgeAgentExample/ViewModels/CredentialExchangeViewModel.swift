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
    
    /// DIDs owned by the agent which have been found as suitable for binding in the exchange
    @Published var suitableDids: SuitableDidsForExchange?
    
    /// Shows when the exchange is loading (i.e. because an action is in progress)
    @Published var isLoading: Bool = false

    /// Shows when there is an error
    @Published var showAlert: Bool = false

    /// The message to show in the alert
    @Published var alertMessage: String = ""

    init(exchange: UICredentialExchange) {
        self.exchange = exchange
    }
    
    /// Construct the ``SuitableDidsForExchange`` object for the `exchange`, then update the
    /// UI's state for this variable.
    ///
    /// The ``SuitableDidsForExchange`` are loaded by determining the restrictions of the incoming
    /// `exchange` and filtering for DIDs which satisfy that.
    func loadSuitableDids() {
        Task { @MainActor in
            isLoading = true
            do {
                switch exchange {
                case .aries(let aries):
                    switch aries.exchange.formatData {
                    case .anoncred:
                        suitableDids = .aries(.notApplicable)
                    case .ariesLdProof:
                        // technically no restrictions are made by aries ldp exchange, but we
                        // make restrictions anyway based on common aries demo configurations
                        let restrictions = ListDidsFilters(
                            allowedDidMethods: [.didKey],
                            allowedKeyTypes: [.ed25519, .p256]
                        )
                        let dids = try await Clients.agent.dids.listAll(
                            options: .init(filters: restrictions)
                        )
                        suitableDids = .aries(.ldProof(dids: .init(
                            dids: dids,
                            restriction: restrictions
                        )))
                    }
                case .openId4Vc(let openId4Vc):
                    let configMap = openId4Vc.exchange.offeredCredentialConfigurations
                    let mapping = try await configMap.asyncCompactMap { k, v in
                        let restrictions = ListDidsFilters(
                            allowedDidMethods: v.allowedBindingMethods.allowedDidMethods,
                            allowedKeyTypes: v.allowedBindingMethods.allowedKeyTypes
                        )
                        let dids = try await Clients.agent.dids.listAll(
                            options: .init(filters: restrictions)
                        )
                        return DidsForRestriction(id: k, dids: dids, restriction: restrictions)
                    }
                    suitableDids = .openId4Vc(.init(didsByConfigurationId: mapping))
                }
            } catch {
                NSLog("Error loading suitable DIDs \(error)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    /// Accepts a given aries-based `CredentialExchange` offer.
    /// The viewmodel `exchange` is updated on success.
    func acceptAries(holderDid: String?) {
        Task { @MainActor in
            isLoading = true
            do {
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
    func acceptOpenId4Vc(credentialConfigurationId: String, holderDid: String) {
        Task { @MainActor in
            isLoading = true
            do {
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

/// Application logic data structure for representing the list of DIDs which have been
/// determined as suitable for holder binding in the given exchange.
enum SuitableDidsForExchange {
    case aries(Aries)
    case openId4Vc(OpenId4Vc)
    
    enum Aries {
        /// Aries exchange is an LD Proof exchange, contains list of appropriate DIDs
        case ldProof(dids: DidsForRestriction)
        
        /// Aries exchange does not need a DID binding (e.g. anoncreds)
        case notApplicable
    }
    
    /// OpenID4VC exchange, contains the set of suitable DIDs for each configuration
    /// being offered.
    struct OpenId4Vc {
        let didsByConfigurationId: [String: DidsForRestriction]
    }
    
    func asAries() -> Aries? {
        switch self {
        case .aries(let aries):
            return aries
        case .openId4Vc:
            return nil
        }
    }
    
    func asOpenId4Vc() -> OpenId4Vc? {
        switch self {
        case .aries:
            return nil
        case .openId4Vc(let openId4Vc):
            return openId4Vc
        }
    }
}

/// Set of DIDs that are appropriate, and the restrictions which those DIDs were checked
/// against (i.e. the restricted DIDs method and key types)
struct DidsForRestriction: Identifiable {
    var id: String
    
    let dids: [DidInformation]
    let restriction: ListDidsFilters
    
    public init(id: String = UUID().uuidString, dids: [DidInformation], restriction: ListDidsFilters) {
        self.id = id
        self.dids = dids
        self.restriction = restriction
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
