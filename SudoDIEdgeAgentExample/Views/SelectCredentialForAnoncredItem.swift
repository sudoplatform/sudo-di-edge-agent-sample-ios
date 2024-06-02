//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoDIEdgeAgent
import SwiftUI

/// View for selecting a credential to meet an attribute group or predicate request.
/// Since this is simply returning a credential id and not interacting with the agent, there is no accompanying view model with this view.
struct SelectCredentialForAnoncredItemView: View {
    /// The presentation credential information
    var item: CredentialsForAnoncredPresentationItem

    /// Returns the selected identifier and credential id
    var onSelectCredential: (_ credId: String, _ referent: String, _ isPredicate: Bool) -> Void

    var body: some View {
        VStack {
            List {
                ForEach(item.suitableCredentials, id: \.credentialId) { cred in

                    let credentialAttributes = cred.forceGetAnoncredAttributes()

                    VStack(alignment: .leading) {
                        BoldedLineItem(name: "ID", value: cred.credentialExchangeId)

                        Text("Attributes:")
                            .font(.title3)

                        // Show the predicate.
                        if item.predicateAttributeName != "" {
                            let attribute = credentialAttributes.first { $0.name == item.predicateAttributeName }!
                            BoldedLineItem(name: attribute.name, value: attribute.value)
                        } else {
                            // show the attributes being requested
                            ForEach(credentialAttributes
                                .filter { item.presentingAttributes.contains($0.name) }
                                .sorted { $0.name < $1.name }, id: \.self) { attribute in
                                BoldedLineItem(name: attribute.name, value: attribute.value)
                            }
                        }

                        Button("Select") {
                            onSelectCredential(cred.credentialId, item.referent, item.predicateAttributeName != "")
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

extension Credential {
    func forceGetAnoncredAttributes() -> [AnoncredV1CredentialAttribute] {
        switch formatData {
        case let .anoncredV1(_, attrs):
            return attrs
        case .w3c:
            fatalError("Wrong format")
        }
    }
}

struct CredentialForItemView_Previews: PreviewProvider {
    static func previewCred(_ group: String, _ id: String, _ isPredicate: Bool) {
        print("Preview for \(isPredicate ? "predicate" : "attribute group") \(group) and \(id)")
    }

    static var previews: some View {
        SelectCredentialForAnoncredItemView(
            item: .init(
                referent: "0",
                suitableCredentials: [
                    .init(
                        credentialId: "credentialId",
                        credentialExchangeId: "credentialExchangeId",
                        connectionId: "connectionId",
                        formatData: .anoncredV1(
                            credentialMetadata: .init(
                                credentialDefinitionId: "credentialDefinitionId",
                                credentialDefinitionInfo: .init(name: "credentialDefinitionName"),
                                schemaId: "schemaId",
                                schemaInfo: .init(name: "schemaInfo", version: "1")
                            ),
                            credentialAttributes: [
                                .init(name: "attribute1", value: "value1", mimeType: "text/plain"),
                                .init(name: "attribute2", value: "value2", mimeType: "text/plain")
                            ]
                        ),
                        tags: [
                            .init(name: "~created_timestamp", value: "1698891059")
                        ]
                    ),
                    .init(
                        credentialId: "credentialId2",
                        credentialExchangeId: "credentialExchangeId2",
                        connectionId: "connectionId",
                        formatData: .anoncredV1(
                            credentialMetadata: .init(
                                credentialDefinitionId: "credentialDefinitionId",
                                credentialDefinitionInfo: .init(name: "credentialDefinitionName"),
                                schemaId: "schemaId",
                                schemaInfo: .init(name: "schemaInfo", version: "1")
                            ),
                            credentialAttributes: [
                                .init(name: "attribute1", value: "value1", mimeType: "text/plain"),
                                .init(name: "other", value: "value2", mimeType: "text/plain")
                            ]
                        ),
                        tags: [
                            .init(name: "~created_timestamp", value: "1698891059")
                        ]
                    )
                ],
                presentingAttributes: ["attribute1", "attribute2"]
            ),
            onSelectCredential: previewCred
        )
    }
}
