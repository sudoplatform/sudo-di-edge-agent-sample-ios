//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoDIEdgeAgent
import SwiftUI

/// View for selecting a credential to meet an attribute group or predicate request.
/// Since this is simply returning a credential id and not interacting with the agent, there is no accompanying view model with this view.
struct SelectCredentialForDifItemView: View {
    /// The presentation credential information
    var inputDescriptor: InputDescriptor
    var suitableCredentials: [Credential]

    /// Returns the selected identifier and credential id
    var onSelectCredential: (_ credId: String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Requested Descriptor:")
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)

                BoldedLineItem(name: "Name", value: inputDescriptor.name ?? "None")
                BoldedLineItem(name: "Purpose", value: inputDescriptor.purpose ?? "None")

                let fields = inputDescriptor.constraints?.fields ?? []
                ForEach(Array(zip(fields.indices, fields)), id: \.0) { index, field in
                    Spacer()
                    BoldedLineItem(name: "Constraint #\(index)", value: "")
                    BoldedLineItem(name: "Constraint Purpose", value: field.purpose ?? "None")
                    BoldedLineItem(name: "Attribute Path", value: "\(field.path)")
                    if let format = field.filter?.format {
                        BoldedLineItem(name: "required format", value: format)
                    }
                    if let pattern = field.filter?.pattern {
                        BoldedLineItem(name: "required pattern", value: pattern)
                    }
                    if let minimum = field.filter?.minimum {
                        BoldedLineItem(name: "required minimum value", value: minimum.asString)
                    }
                    if let exclusiveMinimum = field.filter?.exclusiveMinimum {
                        BoldedLineItem(name: "required exclusiveMinimum value", value: exclusiveMinimum.asString)
                    }
                    if let maximum = field.filter?.maximum {
                        BoldedLineItem(name: "required maximum value", value: maximum.asString)
                    }
                    if let exclusiveMaximum = field.filter?.exclusiveMaximum {
                        BoldedLineItem(name: "required exclusiveMaximum value", value: exclusiveMaximum.asString)
                    }
                    if let minLength = field.filter?.minLength {
                        BoldedLineItem(name: "required minLength", value: "\(minLength)")
                    }
                    if let maxLength = field.filter?.maxLength {
                        BoldedLineItem(name: "required maxLength", value: "\(maxLength)")
                    }
                    if let constValue = field.filter?.const {
                        BoldedLineItem(name: "required const value", value: constValue.asString)
                    }
                    if let enumValue = field.filter?.enum {
                        BoldedLineItem(name: "required enum value", value: enumValue.map { $0.asString }.joined(separator: ", "))
                    }
                    if let notValue = field.filter?.not {
                        BoldedLineItem(name: "required not filter", value: "\(notValue)")
                    }
                }

                Text("Select a Credential:")
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)
                if suitableCredentials.isEmpty {
                    Text("No suitable credentials found")
                }
                ForEach(suitableCredentials, id: \.credentialId) { cred in
                    SelectableCredentialCard(cred: cred, onSelectCredential: onSelectCredential)
                }
            }
            .padding()
        }
    }
}

private struct SelectableCredentialCard: View {
    let cred: Credential
    let onSelectCredential: (_ credId: String) -> Void

    var body: some View {
        let w3c = cred.forceGetW3cDetail()
        ZStack {
            RoundedRectangle(cornerRadius: 10.0)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(radius: 5)

            VStack(alignment: .leading) {
                BoldedLineItem(name: "ID", value: cred.credentialId)
                BoldedLineItem(name: "Issuer", value: w3c.issuer.id)
                BoldedLineItem(name: "Date", value: w3c.issuanceDate)
                let type = w3c.types.first { $0 != "VerifiableCredential" } ?? "VerifiableCredential"
                BoldedLineItem(name: "Type", value: type)

                ForEach(
                    Array(zip(w3c.credentialSubject.indices, w3c.credentialSubject)),
                    id: \.0
                ) { index, sub in
                    Spacer()
                    BoldedLineItem(name: "Subject #\(index)", value: "")
                    BoldedLineItem(name: "ID", value: sub.id ?? "None")
                    ForEach(Array(sub.properties), id: \.key) { k, v in
                        BoldedLineItem(name: k, value: "\(v)")
                    }
                }

                Button("Select") {
                    onSelectCredential(cred.credentialId)
                }
                .padding()
                .frame(maxWidth: 90)
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
}

extension Credential {
    func forceGetW3cDetail() -> W3cCredential {
        switch formatData {
        case let .w3c(cred):
            return cred
        case .anoncredV1:
            fatalError("Wrong format")
        }
    }
}

struct CredentialForDifItemView_Previews: PreviewProvider {
    static let cred = Credential(
        credentialId: "1",
        credentialExchangeId: "1",
        connectionId: "conn1",
        formatData: .w3c(
            credential: .init(
                contexts: [],
                id: nil,
                types: ["VerifiableCredential", "Sample"],
                credentialSubject: [
                    .init(
                        id: "did:example:123",
                        properties: [
                            "givenName": .string("John"),
                            "familyName": .string("Smith")
                        ]
                    ),
                    .init(
                        id: "did:example:321",
                        properties: [
                            "givenName": .string("Peter"),
                            "familyName": .string("Griffin")
                        ]
                    )
                ],
                issuer: .init(id: "did:example:issuer123", properties: [:]),
                issuanceDate: "2024-02-12T15:30:45.123Z",
                expirationDate: nil,
                proof: [],
                properties: [:]
            )
        ),
        tags: []
    )

    static var previews: some View {
        SelectCredentialForDifItemView(
            inputDescriptor: .init(
                id: "1",
                schema: .schemas(schemas: []),
                group: [],
                name: "Proof of Residency",
                purpose: nil,
                constraints: .init(
                    limitDisclosure: nil,
                    statuses: nil,
                    subjectIsIssuer: nil,
                    isHolder: [],
                    sameSubject: [],
                    fields: [
                        .init(
                            path: ["$.credentialSubject.givenName"],
                            id: nil,
                            purpose: "Given name is Bob",
                            filter: .init(
                                fieldType: nil,
                                format: nil,
                                pattern: nil,
                                minimum: nil,
                                exclusiveMinimum: nil,
                                maximum: nil,
                                exclusiveMaximum: nil,
                                minLength: nil,
                                maxLength: nil,
                                const: .stringValue("Bob"),
                                enum: nil
                            ),
                            predicate: nil
                        )
                    ]
                )
            ),
            suitableCredentials: [cred, cred],
            onSelectCredential: { print("Selected", $0) }
        )
    }
}
