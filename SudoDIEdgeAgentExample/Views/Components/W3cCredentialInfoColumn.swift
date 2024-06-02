//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftUI
import SudoDIEdgeAgent

struct W3cCredentialInfoColumn: View {
    var id: String
    var fromConnection: String
    var w3cCredential: W3cCredential
    var proofType: JsonLdProofType?

    var body: some View {
        let sub = w3cCredential.credentialSubject.first
        let credSubjectId = sub?.id ?? "None"
        let credSubjectAttributes = sub?.properties ?? [:]
        let credType = w3cCredential.types.first { $0 != "VerifiableCredential" } ?? "VerifiableCredential"
        
        VStack(alignment: .leading) {
            BoldedLineItem(name: "ID", value: id)
            BoldedLineItem(name: "From Connection", value: fromConnection)
            BoldedLineItem(name: "Format", value: "W3C")
            BoldedLineItem(name: "Issuer", value: w3cCredential.issuer.id)
            BoldedLineItem(name: "Issuance Date", value: w3cCredential.issuanceDate)
            BoldedLineItem(name: "Type", value: credType)
            if let proof = proofType {
                BoldedLineItem(name: "Issuer Proof Type", value: "\(proof)")
            }

            Divider()

            Text("Credential Subject")
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom)
            
            BoldedLineItem(name: "Subject ID", value: credSubjectId)

            ForEach(Array(credSubjectAttributes), id: \.key) { key, value in
                BoldedLineItem(name: key, value: "\(value)")
            }
            Spacer()
        }
        .navigationTitle("Info")
        .padding()
    }
}
