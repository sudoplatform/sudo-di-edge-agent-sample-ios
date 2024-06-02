//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import SudoDIEdgeAgent

// Since this view doesn't interact with the agent, there is no accompanying view model.
struct CredentialView: View {
    var credential: Credential

    var body: some View {
        NavigationView {
            switch credential.formatData {
            case .anoncredV1(let credentialMetadata, let credentialAttributes):
                AnoncredCredentialInfoColumn(
                    id: credential.credentialId,
                    fromConnection: credential.connectionId,
                    metadata: credentialMetadata,
                    attributes: credentialAttributes
                )
            case .w3c(let w3cCred):
                W3cCredentialInfoColumn(
                    id: credential.credentialId,
                    fromConnection: credential.connectionId,
                    w3cCredential: w3cCred,
                    proofType: w3cCred.proof?.first?.proofType
                )
            }
        }
    }
}

struct CredentialView_Previews: PreviewProvider {
    static var previews: some View {
        CredentialView(
            credential: .init(
                credentialId: "credentialId", 
                credentialExchangeId: "credentialExchangeId",
                connectionId: "connectionId",
                formatData: .anoncredV1(
                    credentialMetadata: .init(
                        credentialDefinitionId: "credentialDefinitionId",
                        credentialDefinitionInfo: .init(name: "credentialDefinitionName"),
                        schemaId: "schemaId",
                        schemaInfo: .init(name: "schemaInfo", version: "1")),
                    credentialAttributes: [
                        .init(name: "attribute1", value: "value1", mimeType: "text/plain"),
                        .init(name: "attribute2", value: "value2", mimeType: "text/plain")
                    ]
                ),
                tags: [
                    .init(name: "~created_timestamp", value: "1698891059")
                ]
            )
        )
    }
}
