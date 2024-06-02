//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import SudoDIEdgeAgent

struct CredentialExchangeView: View {
    @StateObject var viewModel: CredentialExchangeViewModel

    var body: some View {
        NavigationView {
            switch viewModel.credential.formatData {
            case .indy(let credentialMetadata, let credentialAttributes):
                AnoncredCredentialInfoColumn(
                    id: viewModel.credential.credentialExchangeId,
                    fromConnection: viewModel.credential.connectionId,
                    metadata: credentialMetadata,
                    attributes: credentialAttributes
                )
            case .ariesLdProof(let currentProposedCredential, let currentProposedProofType):
                W3cCredentialInfoColumn(
                    id: viewModel.credential.credentialExchangeId,
                    fromConnection: viewModel.credential.connectionId,
                    w3cCredential: currentProposedCredential,
                    proofType: currentProposedProofType
                )
            }
        }
    }
}

/// Helper view to format and display a line item with a bolded title
struct BoldedLineItem: View {
    var name: String
    var value: String

    var body: some View {
        HStack(alignment: .top) {
            Text("\(name): ")
                .fontWeight(.bold)
            Text(value)
        }
    }
}

struct CredentialExchangeView_Previews: PreviewProvider {
    static var previews: some View {
        CredentialExchangeView(viewModel: .init(
            credential: .init(
                credentialExchangeId: "credentialExchangeId",
                credentialId: "credentialId",
                connectionId: "connectionId",
                initiator: .internal,
                state: .offer,
                formatData: .indy(
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
                errorMessage: nil,
                tags: [
                    .init(name: "~created_timestamp", value: "1698891059")
                ])
        ))
    }
}
