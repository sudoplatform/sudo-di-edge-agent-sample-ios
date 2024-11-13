//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftUI
import SudoDIEdgeAgent

struct SdJwtCredentialInfoColumn: View {
    var id: String
    var fromSource: CredentialSource
    var sdJwtVc: SdJwtVerifiableCredential

    var body: some View {
        VStack(alignment: .leading) {
            BoldedLineItem(name: "ID", value: id)
            switch fromSource {
            case .didCommConnection(let connectionId):
                BoldedLineItem(name: "From Connection", value: connectionId)
            case .openId4VcIssuer(let issuerUrl):
                BoldedLineItem(name: "From OID Issuer", value: issuerUrl)
            }
            BoldedLineItem(name: "Format", value: "SD-JWT")
            BoldedLineItem(name: "Issuer", value: sdJwtVc.issuer)
            if let iat = sdJwtVc.issuedAt {
                BoldedLineItem(name: "Issuance Date", value: "\(iat)")
            }
            BoldedLineItem(name: "Type", value: sdJwtVc.verifiableCredentialType)

            Divider()

            Text("Claims")
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom)

            ForEach(Array(sdJwtVc.claims), id: \.key) { key, value in
                BoldedLineItem(name: key, value: "\(value)")
            }
            Spacer()
        }
        .navigationTitle("Info")
        .padding()
    }
}
