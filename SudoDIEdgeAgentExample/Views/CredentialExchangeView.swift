//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import SudoDIEdgeAgent

struct CredentialExchangeView: View {
    @StateObject var viewModel: CredentialExchangeViewModel
    var onDismissRequest: () -> Void

    var body: some View {
        NavigationView {
            if viewModel.isLoading {
                ProgressView()
            } else {
                switch viewModel.exchange {
                case .aries(let exchange): AriesCredentialExchangeView(
                    exchange: exchange,
                    acceptCredential: {
                        viewModel.acceptAries()
                    },
                    onDismissRequest: onDismissRequest
                )
                case .openId4Vc(let exchange): OpenId4VcCredentialExchangeView(
                    exchange: exchange,
                    authorizeExchange: { txCode in
                        viewModel.authorizeExchange(txCode: txCode)
                    },
                    acceptCredentialConfig: { configId in
                        viewModel.acceptOpenId4Vc(credentialConfigurationId: configId)
                    },
                    storeCredential: {
                        viewModel.storeCredential()
                    },
                    onDismissRequest: onDismissRequest
                )
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

private struct AriesCredentialExchangeView: View {
    var exchange: CredentialExchange.Aries
    var acceptCredential: () -> Void
    var onDismissRequest: () -> Void
    
    var body: some View {
        VStack {
            switch exchange.formatData {
            case .indy(let credentialMetadata, let credentialAttributes):
                AnoncredCredentialInfoColumn(
                    id: exchange.credentialExchangeId,
                    fromSource: .didCommConnection(connectionId: exchange.connectionId),
                    metadata: credentialMetadata,
                    attributes: credentialAttributes
                )
            case .ariesLdProof(let currentProposedCredential, let currentProposedProofType):
                W3cCredentialInfoColumn(
                    id: exchange.credentialExchangeId,
                    fromSource: .didCommConnection(connectionId: exchange.connectionId),
                    w3cCredential: currentProposedCredential,
                    proofType: currentProposedProofType
                )
            }
            switch exchange.state {
            case .offer:
                Button(action: acceptCredential) {
                    Text("Accept")
                }
                .padding()
                .frame(width: 200)
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            default:
                Button(action: onDismissRequest) {
                    Text("Done")
                }
                .padding()
                .frame(width: 200)
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
        }
    }
}

private struct OpenId4VcCredentialExchangeView: View {
    var exchange: CredentialExchange.OpenId4Vc
    var authorizeExchange: (String?) -> Void
    // config ID
    var acceptCredentialConfig: (String) -> Void
    var storeCredential: () -> Void
    var onDismissRequest: () -> Void
    
    @State var txCodeInput: String = ""
    
    var body: some View {
        let issuedCredential = exchange.issuedCredentialPreviews.first
        
        switch issuedCredential {
        // exchange in final state, just needs storage
        case .some(let cred):
            VStack {
                switch cred {
                case .anoncredV1(let credMetadata, let credAttributes):
                    AnoncredCredentialInfoColumn(
                        id: exchange.credentialExchangeId,
                        fromSource: .openId4VcIssuer(
                            issuerUrl: exchange.credentialIssuerUrl
                        ),
                        metadata: credMetadata,
                        attributes: credAttributes
                    )
                case .w3c(let cred):
                    W3cCredentialInfoColumn(
                        id: exchange.credentialExchangeId,
                        fromSource: .openId4VcIssuer(
                            issuerUrl: exchange.credentialIssuerUrl
                        ),
                        w3cCredential: cred
                    )
                case .sdJwtVc(let cred):
                    SdJwtCredentialInfoColumn(
                        id: exchange.credentialExchangeId,
                        fromSource: .openId4VcIssuer(
                            issuerUrl: exchange.credentialIssuerUrl
                        ),
                        sdJwtVc: cred
                    )
                }
                switch exchange.state {
                case .issued:
                    Button(action: storeCredential) {
                        Text("Store")
                    }
                    .padding()
                    .frame(width: 200)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                default:
                    Button(action: onDismissRequest) {
                        Text("Done")
                    }
                    .padding()
                    .frame(width: 200)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
        // exchange not in issued/done state, ready to accept or authorize
        case nil:
            let readyToAccept = exchange.state == .authorized
            VStack {
                // offered configurations
                List {
                    ForEach(
                        Array(exchange.offeredCredentialConfigurations),
                        id: \.key
                    ) { id, config in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(id)
                                switch config {
                                case .sdJwtVc(let vc):
                                    Text("SD-JWT: \(vc.vct)")
                                }
                            }
                            Spacer()

                            if readyToAccept {
                                Button("Accept") {
                                    acceptCredentialConfig(id)
                                }
                                .frame(maxWidth: 55)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                Divider()
                if exchange.state == .unauthorized {
                    switch exchange.requiredAuthorization {
                    case .preAuthorized(let txCodeRequired):
                        if txCodeRequired != nil {
                            TextField(
                                "Enter PIN from issuer",
                                text: $txCodeInput
                            ).textFieldStyle(.roundedBorder)
                                .frame(minHeight: 50)
                        }
                    }
                    
                    Button("Authorize") {
                        if !txCodeInput.isEmpty {
                            authorizeExchange(txCodeInput)
                        } else {
                            authorizeExchange(nil)
                        }
                    }
                    .padding()
                    .frame(width: 200)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }.navigationTitle("Offered Credentials")
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

struct AriesCredentialExchangeView_Previews: PreviewProvider {
    static var previews: some View {
        AriesCredentialExchangeView(
            exchange: .init(
                credentialExchangeId: "credentialExchangeId",
                credentialIds: ["credentialId"],
                errorMessage: nil,
                tags: [
                    .init(name: "~created_timestamp", value: "1698891059")
                ],
                state: .offer,
                connectionId: "connectionId",
                initiator: .internal,
                formatData: .indy(
                    credentialMetadata: .init(
                        credentialDefinitionId: "credentialDefinitionId",
                        credentialDefinitionInfo: .init(name: "credentialDefinitionName"),
                        schemaId: "schemaId",
                        schemaInfo: .init(name: "schemaInfo", version: "1")),
                    credentialAttributes: [
                        .init(name: "attribute1", value: "value1", mimeType: "text/plain"),
                        .init(name: "attribute2", value: "value2", mimeType: "text/plain")
                    ]
                )
            ),
            acceptCredential: {},
            onDismissRequest: {}
        )
        
    }
}

struct OpenId4VcCredentialExchangeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OpenId4VcCredentialExchangeView(
                exchange: .init(
                    credentialExchangeId: "credentialExchangeId",
                    credentialIds: ["credentialId"],
                    errorMessage: nil,
                    tags: [
                        .init(name: "~created_timestamp", value: "1698891059")
                    ],
                    state: .authorized,
                    credentialIssuerUrl: "https://issuer.foo",
                    credentialIssuerDisplay: nil,
                    requiredAuthorization: .preAuthorized(
                        txCodeRequired: nil
                    ),
                    offeredCredentialConfigurations: [
                        "UniversityDegreeSdJwt": .sdJwtVc(.init(
                            display: nil,
                            allowedBindingMethods: .init(
                                allowedDidMethods: [],
                                allowedKeyTypes: []
                            ),
                            vct: "UniversityDegree",
                            claims: [:]
                        ))],
                    issuedCredentialPreviews: []
                ),
                authorizeExchange: { _ in },
                acceptCredentialConfig: { _ in },
                storeCredential: {},
                onDismissRequest: {}
            )
        }
    }
}
