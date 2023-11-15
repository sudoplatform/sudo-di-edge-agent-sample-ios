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
            VStack(alignment: .leading) {
                BoldedLineItem(name: "ID", value: credential.credentialExchangeId)
                BoldedLineItem(name: "From Connection", value: credential.connectionId)
                BoldedLineItem(name: "Cred Def ID", value: credential.credentialMetadata.credentialDefinitionId)
                BoldedLineItem(name: "Cred Def Name", value: credential.credentialMetadata.credentialDefinitionInfo?.name ?? "")
                BoldedLineItem(name: "Schema ID", value: credential.credentialMetadata.schemaId)

                Divider()

                Text("Attributes")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom)

                ForEach(credential.credentialAttributes, id: \.self) { attribute in
                    BoldedLineItem(name: attribute.name, value: attribute.value)
                }
                Spacer()
            }
            .navigationTitle("Info")
            .padding()
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
                credentialMetadata: .init(
                    credentialDefinitionId: "credentialDefinitionId",
                    credentialDefinitionInfo: .init(name: "credentialDefinitionName"),
                    schemaId: "schemaId",
                    schemaInfo: .init(name: "schemaInfo", version: "1")),
                credentialAttributes: [
                    .init(name: "attribute1", value: "value1", mimeType: "text/plain"),
                    .init(name: "attribute2", value: "value2", mimeType: "text/plain"),
                ],
                tags: [
                    .init(name: "~created_timestamp", value: "1698891059")
                ]
            )
        )
    }
}
