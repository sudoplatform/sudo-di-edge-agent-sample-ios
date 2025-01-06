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
    var exchange: UICredentialExchange.Aries
    var acceptCredential: () -> Void
    var onDismissRequest: () -> Void
    
    var body: some View {
        VStack {
            switch exchange.preview {
            case .anoncred(let credential):
                AnoncredCredentialInfoColumn(credential: credential)
            case .w3c(let credential):
                W3cCredentialInfoColumn(credential: credential)
            case .sdJwtVc(let credential):
                SdJwtCredentialInfoColumn(credential: credential)
            }
            switch exchange.exchange.state {
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
    var exchange: UICredentialExchange.OpenId4Vc
    var authorizeExchange: (String?) -> Void
    // config ID
    var acceptCredentialConfig: (String) -> Void
    var storeCredential: () -> Void
    var onDismissRequest: () -> Void
    
    @State var txCodeInput: String = ""
    
    var body: some View {
        let issuedCredential = exchange.issuedPreviews.first
        
        switch issuedCredential {
        // exchange in final state, just needs storage
        case .some(let cred):
            VStack {
                switch cred {
                case .anoncred(let credential):
                    AnoncredCredentialInfoColumn(credential: credential)
                case .w3c(let credential):
                    W3cCredentialInfoColumn(credential: credential)
                case .sdJwtVc(let credential):
                    SdJwtCredentialInfoColumn(credential: credential)
                }
                    
                switch exchange.exchange.state {
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
            let readyToAccept = exchange.exchange.state == .authorized
            VStack {
                // offered configurations
                List {
                    ForEach(
                        Array(exchange.exchange.offeredCredentialConfigurations),
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
                if exchange.exchange.state == .unauthorized {
                    switch exchange.exchange.requiredAuthorization {
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
                    formatData: .anoncred(
                        credentialMetadata: .init(
                            credentialDefinitionId: "",
                            schemaId: ""
                        ),
                        credentialAttributes: []
                    )
                ),
                preview: PreviewDataHelper.dummyUICredentialAnoncred
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
                    issuedPreviews: []
                ),
                authorizeExchange: { _ in },
                acceptCredentialConfig: { _ in },
                storeCredential: {},
                onDismissRequest: {}
            )
        }
    }
}
