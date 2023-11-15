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
            VStack(alignment: .leading) {
                BoldedLineItem(name: "ID", value: viewModel.credential.credentialExchangeId)
                BoldedLineItem(name: "From Connection", value: viewModel.credential.connectionId)
                BoldedLineItem(name: "Cred Def ID", value: viewModel.credential.credentialMetadata.credentialDefinitionId)
                BoldedLineItem(name: "Cred Def Name", value: viewModel.credential.credentialMetadata.credentialDefinitionInfo?.name ?? "")
                BoldedLineItem(name: "Schema ID", value: viewModel.credential.credentialMetadata.schemaId)

                Divider()

                Text("Attributes")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom)

                ForEach(viewModel.credential.credentialAttributes, id: \.self) { attribute in
                    BoldedLineItem(name: attribute.name, value: attribute.value)
                }
                Spacer()
            }
            .navigationTitle("Info")
            .padding()
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
                credentialMetadata: .init(
                    credentialDefinitionId: "credentialDefinitionId",
                    credentialDefinitionInfo: .init(name: "credentialDefinitionName"),
                    schemaId: "schemaId",
                    schemaInfo: .init(name: "schemaInfo", version: "1")),
                credentialAttributes: [
                    .init(name: "attribute1", value: "value1", mimeType: "text/plain"),
                    .init(name: "attribute2", value: "value2", mimeType: "text/plain"),
                ],
                errorMessage: nil,
                tags: [
                    .init(name: "~created_timestamp", value: "1698891059")
                ])
        ))
    }
}
