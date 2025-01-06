//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
// 

import Foundation
import SudoDIEdgeAgent

/// Wrapper around the Edge Agent ``Credential`` with extra collected/resolve data
/// needed for UI displaying purposes (e.g. the resolved anoncreds metadata)
public enum UICredential: Identifiable {
    
    case anoncred(_ inner: Anoncred)
    case w3c(_ inner: W3C)
    case sdJwtVc(_ inner: SdJwtVc)
    
    
    /// helper function to resolve the full anoncreds metadata from ``AnoncredV1CredentialMetadata``.
    /// Including the schema & credential definition details.
    static func resolveFullAnoncredMetadata(
        agent: SudoDIEdgeAgent,
        metadata: AnoncredV1CredentialMetadata
    ) async throws -> FullAnoncredMetadata {
        let schema = try await agent.anoncreds.resolveSchema(
            id: metadata.schemaId
        )
        let credDef = try await agent.anoncreds.resolveCredentialDefinition(
            id: metadata.credentialDefinitionId
        )
        
        return .init(schema: schema, credentialDefinition: credDef)
    }
    
    /// special constructor of ``UICredential``, where the ``UICredential`` is assembled from
    /// the ``Credential``, using the ``SudoDIEdgeAgent`` to load any extra data if required.
    static func fromCredential(agent: SudoDIEdgeAgent, credential: Credential) async throws -> Self {
        return try await fromFormatData(
            agent: agent,
            formatData: credential.formatData,
            id: credential.credentialId,
            source: credential.credentialSource
        )
    }
    
    
    /// special constructor of ``UICredential``, where the ``UICredential`` is assembled from
    /// ``CredentialFormatData``, using the ``SudoDIEdgeAgent`` to load any extra data if required.
    static func fromFormatData(
        agent: SudoDIEdgeAgent,
        formatData: CredentialFormatData,
        id: String,
        source: CredentialSource
    ) async throws -> Self {
        switch formatData {
        case .anoncredV1(let credentialMetadata, let credentialAttributes):
            let metadata = try await resolveFullAnoncredMetadata(
                agent: agent,
                metadata: credentialMetadata
            )
            return .anoncred(.init(
                id: id,
                source: source,
                metadata: metadata,
                credentialAttributes: credentialAttributes
            ))
        case .w3c(let formatData):
            return .w3c(.init(
                id: id,
                source: source,
                w3cVc: formatData,
                proofType: formatData.proof?.first?.proofType
            ))
        case .sdJwtVc(let formatData):
            return .sdJwtVc(.init(
                id: id,
                source: source,
                sdJwtVc: formatData
            ))
        }
    }
    
    public var id: String {
        switch self {
        case .anoncred(let v): return v.id
        case .w3c(let v): return v.id
        case .sdJwtVc(let v): return v.id
        }
    }
    
    /// Get the UI displayable type/name for this credential
    var previewName: String {
        switch self {
        case .anoncred(let value):
            return value.metadata.schema.name
        case .w3c(let value):
            return value.w3cVc.types.first { $0 != "VerifiableCredential" } ?? "VerifiableCredential"
        case .sdJwtVc(let value):
            return value.sdJwtVc.verifiableCredentialType
        }
    }
    
    /// Get the UI displayable format of this credential
    var previewFormat: String {
        switch self {
        case .anoncred: return "Anoncred"
        case .w3c: return "W3C"
        case .sdJwtVc: return "SD-JWT VC"
        }
    }
    
    public struct Anoncred {
        public let id: String
        public let source: CredentialSource
        public let metadata: FullAnoncredMetadata
        public let credentialAttributes: [AnoncredV1CredentialAttribute]
    }
    
    public struct W3C {
        public let id: String
        public let source: CredentialSource
        public let w3cVc: W3cCredential
        public let proofType: JsonLdProofType?
    }
    
    public struct SdJwtVc {
        public let id: String
        public let source: CredentialSource
        public let sdJwtVc: SdJwtVerifiableCredential
    }
}

public struct FullAnoncredMetadata {
    public let schema: CredentialSchemaInfo
    public let credentialDefinition: CredentialDefinitionInfo
}
