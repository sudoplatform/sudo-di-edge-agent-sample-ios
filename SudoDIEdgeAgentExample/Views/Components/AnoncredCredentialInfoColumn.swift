//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
// 

import Foundation
import SwiftUI
import SudoDIEdgeAgent

struct AnoncredCredentialInfoColumn: View {
    var id: String
    var fromSource: CredentialSource
    var metadata: AnoncredV1CredentialMetadata
    var attributes: [AnoncredV1CredentialAttribute]

    var body: some View {
        VStack(alignment: .leading) {
            BoldedLineItem(name: "ID", value: id)
            switch fromSource {
            case .didCommConnection(let connectionId):
                BoldedLineItem(name: "From Connection", value: connectionId)
            case .openId4VcIssuer(let issuerUrl):
                BoldedLineItem(name: "From OID Issuer", value: issuerUrl)
            }
            BoldedLineItem(name: "Format", value: "Anoncreds")
            BoldedLineItem(name: "Cred Def ID", value: metadata.credentialDefinitionId)
            BoldedLineItem(name: "Cred Def Name", value: metadata.credentialDefinitionInfo?.name ?? "Unknown")
            BoldedLineItem(name: "Schema ID", value: metadata.schemaId)

            Divider()

            Text("Attributes")
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom)

            ForEach(attributes, id: \.self) { attribute in
                BoldedLineItem(name: attribute.name, value: attribute.value)
            }
            Spacer()
        }
        .navigationTitle("Info")
        .padding()
    }
}
