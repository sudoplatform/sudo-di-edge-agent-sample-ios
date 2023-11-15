//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import SudoDIEdgeAgent

/// View for selecting a credential to meet an group or predicate request.
/// Since this is simply returning a credential id and not interacting with the agent, there is no accompanying view model with this view.
struct CredentialForItemView: View {
    /// The presentation credential information 
    var presentation: PresentationItem

    /// Returns the selected identifier and credential id
    var selectedCred: (_ group: String, _ id: String, _ isPredicate: Bool) -> Void

    /// Gets the first attribute from the credential that meets the predicate
    func predicateAttribute(for credential: Credential) -> CredentialAttribute? {
        // The app developer may wish to validate the predicate against the credential first.
        // In this case, the name is sufficient.
        let attribute = credential.credentialAttributes.first { $0.name == presentation.predicate }
        return attribute
    }

    var body: some View {
        VStack {
            List {
                ForEach(presentation.credentials) { credential in
                    VStack(alignment: .leading) {
                        BoldedLineItem(name: "ID", value: credential.credentialExchangeId)

                        Text("Attributes:")
                            .font(.title3)

                        // Show the predicate.
                        if presentation.predicate != "", let attribute = predicateAttribute(for: credential) {
                            BoldedLineItem(name: attribute.name, value: attribute.value)
                        } else {
                            // show the attributes being requested
                            ForEach(credential.credentialAttributes
                                .filter { presentation.attributes.contains($0.name) }
                                .sorted { $0.name < $1.name }, id: \.self) { attribute in
                                BoldedLineItem(name: attribute.name, value: attribute.value)
                            }
                        }

                        Button("Select") {
                            selectedCred(presentation.id, credential.credentialId, presentation.predicate != "")
                        }
                            .padding()
                            .frame(maxWidth: 90)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .buttonStyle(.borderless)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

        }
    }
}

struct CredentialForItemView_Previews: PreviewProvider {
    static func previewCred(_ group: String, _ id: String, _ isPredicate: Bool) {
        print("Preview for \(isPredicate ? "predicate" : "attribute group") \(group) and \(id)")
    }

    static var previews: some View {
        CredentialForItemView(
            presentation: .init(
                id: "0",
                credentials: [
                    .init(
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
                    ),
                    .init(
                        credentialId: "credentialId2",
                        credentialExchangeId: "credentialExchangeId2",
                        connectionId: "connectionId",
                        credentialMetadata: .init(
                            credentialDefinitionId: "credentialDefinitionId",
                            credentialDefinitionInfo: .init(name: "credentialDefinitionName"),
                            schemaId: "schemaId",
                            schemaInfo: .init(name: "schemaInfo", version: "1")),
                        credentialAttributes: [
                            .init(name: "attribute1", value: "value1", mimeType: "text/plain"),
                            .init(name: "other", value: "value2", mimeType: "text/plain"),
                        ],
                        tags: [
                            .init(name: "~created_timestamp", value: "1698891059")
                        ]
                    )], 
                attributes: ["attribute1", "attribute2"]
            ),
            selectedCred: previewCred)
    }
}
