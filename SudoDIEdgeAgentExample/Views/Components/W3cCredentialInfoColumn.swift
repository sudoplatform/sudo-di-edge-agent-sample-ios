//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftUI
import SudoDIEdgeAgent

struct W3cCredentialInfoColumn: View {
    var credential: UICredential.W3C

    var body: some View {
        let credType = credential.w3cVc.types.first { $0 != "VerifiableCredential" } ?? "VerifiableCredential"
        
        VStack(alignment: .leading) {
            BoldedLineItem(name: "ID", value: credential.id)
            switch credential.source {
            case .didCommConnection(let connectionId):
                BoldedLineItem(name: "From Connection", value: connectionId)
            case .openId4VcIssuer(let issuerUrl):
                BoldedLineItem(name: "From OID Issuer", value: issuerUrl)
            }
            BoldedLineItem(name: "Format", value: "W3C")
            BoldedLineItem(name: "Issuer", value: credential.w3cVc.issuer.id)
            BoldedLineItem(name: "Issuance Date", value: credential.w3cVc.issuanceDate)
            BoldedLineItem(name: "Type", value: credType)
            if let proof = credential.proofType {
                BoldedLineItem(name: "Issuer Proof Type", value: "\(proof)")
            }

            Divider()

            ForEach(
                Array(zip(credential.w3cVc.credentialSubject.indices, credential.w3cVc.credentialSubject)),
                id: \.0
            ) { index, sub in
                let credSubjectId = sub.id ?? "None"
                let credSubjectAttributes = sub.properties

                Text("Credential Subject #\(index)")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom)
                BoldedLineItem(name: "Subject ID", value: credSubjectId)
                
                ForEach(Array(credSubjectAttributes), id: \.key) { key, value in
                    BoldedLineItem(name: key, value: "\(value)")
                }
                Spacer()
            }
        }
        .navigationTitle("Info")
        .padding()
    }
}
