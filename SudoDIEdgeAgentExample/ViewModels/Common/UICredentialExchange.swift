//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
// 

import Foundation
import SudoDIEdgeAgent


/// Wrapper around the Edge Agent ``CredentialExchange`` with preview/s of the credential/s
/// in exchange expanded into ``UICredential``/s, for UI displaying purposes.
public enum UICredentialExchange: Identifiable {
    
    case aries(_ inner: Aries)
    case openId4Vc(_ inner: OpenId4Vc)

    /// special constructor of ``UICredentialExchange``, where it is constructed from
    /// a base ``CredentialExchange``, using the ``SudoDIEdgeAgent`` to load ``UICredential``
    /// preview/s of the credential/s being exchanged in the ``CredentialExchange``.
    static func fromCredentialExchange(
        agent: SudoDIEdgeAgent,
        exchange: CredentialExchange
    ) async throws -> Self {
        switch exchange {
        case .aries(let inner):
            let source = CredentialSource.didCommConnection(connectionId: inner.connectionId)
            let preview: UICredential
            switch inner.formatData {
            case .anoncred(let credentialMetadata, let credentialAttributes):
                let metadata = try await UICredential.resolveFullAnoncredMetadata(
                    agent: agent,
                    metadata: credentialMetadata
                )
                preview = .anoncred(.init(
                    id: exchange.credentialExchangeId,
                    source: source,
                    metadata: metadata,
                    credentialAttributes: credentialAttributes
                ))
            case .ariesLdProof(let currentProposedCredential, let currentProposedProofType):
                preview = .w3c(.init(
                    id: exchange.credentialExchangeId,
                    source: source,
                    w3cVc: currentProposedCredential,
                    proofType: currentProposedProofType
                ))
            }

            return .aries(.init(exchange: inner, preview: preview))
            
        case .openId4Vc(let inner):
            let source = CredentialSource.openId4VcIssuer(issuerUrl: inner.credentialIssuerUrl)
            let previews = try await inner.issuedCredentialPreviews.asyncCompactMap {
                try await UICredential.fromFormatData(
                    agent: agent,
                    formatData: $0,
                    id: exchange.credentialExchangeId,
                    source: source
                )
            }
            return .openId4Vc(.init(exchange: inner, issuedPreviews: previews))
        }
    }

    public var id: String {
        switch self {
        case .aries(let value):
            value.exchange.credentialExchangeId
        case .openId4Vc(let value):
            value.exchange.credentialExchangeId
        }
    }
    
    var exchange: CredentialExchange {
        switch self {
        case .aries(let value):
            CredentialExchange.aries(value.exchange)
        case .openId4Vc(let value):
            CredentialExchange.openId4Vc(value.exchange)
        }
    }
    
    var exchangeTypeName: String {
        switch self {
        case .aries: "Aries"
        case .openId4Vc: "OpenId4Vc"
        }
    }
    
    var credPreview: UICredential? {
        switch self {
        case .aries(let inner): inner.preview
        case .openId4Vc(let inner): inner.issuedPreviews.first
        }
    }
    
    public struct Aries {
        public let exchange: CredentialExchange.Aries
        public let preview: UICredential
    }
    
    public struct OpenId4Vc {
        public let exchange: CredentialExchange.OpenId4Vc
        public let issuedPreviews: [UICredential]
    }
}
