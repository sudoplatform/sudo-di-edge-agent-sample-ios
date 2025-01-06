//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
// 

import Foundation
import SwiftUI
import SudoDIEdgeAgent

struct AnoncredCredentialInfoColumn: View {
    var credential: UICredential.Anoncred

    var body: some View {
        VStack(alignment: .leading) {
            BoldedLineItem(name: "ID", value: credential.id)
            switch credential.source {
            case .didCommConnection(let connectionId):
                BoldedLineItem(name: "From Connection", value: connectionId)
            case .openId4VcIssuer(let issuerUrl):
                BoldedLineItem(name: "From OID Issuer", value: issuerUrl)
            }
            BoldedLineItem(name: "Format", value: "Anoncreds")
            BoldedLineItem(
                name: "Cred Def ID",
                value: credential.metadata.credentialDefinition.id
            )
            BoldedLineItem(
                name: "Cred Def Issuer",
                value: credential.metadata.credentialDefinition.issuerId
            )
            BoldedLineItem(name: "Schema ID", value: credential.metadata.schema.id)
            BoldedLineItem(name: "Schema Name", value: credential.metadata.schema.name)

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
