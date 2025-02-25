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
            if viewModel.isLoading || viewModel.suitableDids == nil {
                ProgressView()
            } else {

                switch viewModel.exchange {
                case .aries(let exchange): AriesCredentialExchangeView(
                    exchange: exchange,
                    suitableDidsForExchange: viewModel.suitableDids!.asAries()!,
                    acceptCredential: { did in
                        viewModel.acceptAries(holderDid: did)
                    },
                    onDismissRequest: onDismissRequest
                )
                case .openId4Vc(let exchange): OpenId4VcCredentialExchangeView(
                    exchange: exchange,
                    suitableDidsForExchange: viewModel.suitableDids!.asOpenId4Vc()!,
                    authorizeExchange: { txCode in
                        viewModel.authorizeExchange(txCode: txCode)
                    },
                    acceptCredential: { configId, did in
                        viewModel.acceptOpenId4Vc(
                            credentialConfigurationId: configId,
                            holderDid: did
                        )
                    },
                    storeCredential: {
                        viewModel.storeCredential()
                    },
                    onDismissRequest: onDismissRequest
                )
                }
            }
        }
        .task { viewModel.loadSuitableDids() }
        .alert("Error", isPresented: $viewModel.showAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

private struct AriesCredentialExchangeView: View {
    var exchange: UICredentialExchange.Aries
    var suitableDidsForExchange: SuitableDidsForExchange.Aries
    var acceptCredential: (String?) -> Void
    var onDismissRequest: () -> Void
    
    /// state for the list of DIDs which are actively being selected from. Non-nil when a selection is
    /// in progress (e.g. for an aries ldp exchange)
    @State var selectDidList: DidsForRestriction?
    
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
                Button("Accept") {
                    switch suitableDidsForExchange {
                    // must select a DID
                    case .ldProof(let dids):
                        selectDidList = dids
                    // no DID needed
                    case .notApplicable:
                        acceptCredential(nil)
                    }
                }
                .standardButtonTheme()
            default:
                Button(action: onDismissRequest) {
                    Text("Done")
                }
                .standardButtonTheme()
            }
        }
        .sheet(item: $selectDidList) { suitableDids in
            SelectDidModal(didList: suitableDids, onSelect: { did in
                acceptCredential(did)
                selectDidList = nil
            })
        }
    }
}

private struct OpenId4VcCredentialExchangeView: View {
    var exchange: UICredentialExchange.OpenId4Vc
    var suitableDidsForExchange: SuitableDidsForExchange.OpenId4Vc
    /// authorize an exchange with a TX Code
    var authorizeExchange: (_ txCode: String?) -> Void
    /// accept a credential for the given configuration ID and the DID to bind.
    var acceptCredential: (_ config: String, _ did: String) -> Void
    var storeCredential: () -> Void
    var onDismissRequest: () -> Void
    
    @State var txCodeInput: String = ""

    /// state for the list of DIDs which are actively being selected from. Non-nil when a selection is
    /// in progress (e.g. for a specific configuration)
    @State var selectDidListForConfigId: DidsForRestriction?
    
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
                    .standardButtonTheme()
                default:
                    Button(action: onDismissRequest) {
                        Text("Done")
                    }
                    .standardButtonTheme()
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
                                    let didsForConfig = suitableDidsForExchange.didsByConfigurationId[id]
                                    selectDidListForConfigId = didsForConfig
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
                    .standardButtonTheme()
                }
            }
            .navigationTitle("Offered Credentials")
            .sheet(item: $selectDidListForConfigId) { suitableDids in
                SelectDidModal(didList: suitableDids, onSelect: { did in
                    acceptCredential(suitableDids.id, did)
                    selectDidListForConfigId = nil
                })
            }
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

/// Content of modal in which a DID should be selected. On selection, the `onSelect`
/// callback is invoked.
struct SelectDidModal: View {
    var didList: DidsForRestriction
    var onSelect: (_ did: String) -> Void
    
    @State private var selection: String?

    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Select a DID to bind:")
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            if didList.dids.isEmpty {
                Text("No suitable DIDs found")
                Text("Please create a DID satsifying the following: \(didList.restriction)")
                Spacer()
            } else {
                List(didList.dids, selection: $selection) {
                    let did = $0
                    VStack(alignment: .leading) {
                        Text(did.did).lineLimit(1)
                        Text("Alias: \(did.alias ?? "None")")
                    }
                }
                .onChange(of: selection) { newSelection in
                    guard let did = newSelection else { return }
                    onSelect(did)
                }
            }
        }
    }
}

struct AriesAnoncredsCredentialExchangeView_Previews: PreviewProvider {
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
            suitableDidsForExchange: .notApplicable,
            acceptCredential: { _ in },
            onDismissRequest: {}
        )
        
    }
}

struct AriesLdpCredentialExchangeView_Previews: PreviewProvider {
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
                    formatData: .ariesLdProof(
                        currentProposedCredential: PreviewDataHelper.dummyW3cCredential,
                        currentProposedProofType: .ed25519Signature2018
                    )
                ),
                preview: PreviewDataHelper.dummyUICredentialAnoncred
            ),
            suitableDidsForExchange: .ldProof(dids: .init(
                dids: [
                    .init(
                        did: "did:key:abc",
                        methodData: .didKey(keyType: .p256),
                        tags: [RecordTag(name: "alias", value: "Work DID")]
                    ),
                    .init(
                        did: "did:key:xyz",
                        methodData: .didKey(keyType: .ed25519),
                        tags: [RecordTag(name: "alias", value: "School DID")]
                    ),
                    .init(
                        did: "did:jwk:abc",
                        methodData: .didJwk(keyType: .ed25519),
                        tags: []
                    )
                ],
                restriction: .init()
            )),
            acceptCredential: { _ in },
            onDismissRequest: {}
        )
        
    }
}

struct OpenId4VcUnauthorizedCredentialExchangeView_Previews: PreviewProvider {
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
                        state: .unauthorized,
                        credentialIssuerUrl: "https://issuer.foo",
                        credentialIssuerDisplay: nil,
                        requiredAuthorization: .preAuthorized(
                            txCodeRequired: .init(
                                lengthHint: nil,
                                description: nil
                            )
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
                suitableDidsForExchange: .init(
                    didsByConfigurationId: [:]
                ),
                authorizeExchange: { _ in },
                acceptCredential: { _, _ in },
                storeCredential: {},
                onDismissRequest: {}
            )
        }
    }
}

struct OpenId4VcAuthorizedCredentialExchangeView_Previews: PreviewProvider {
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
                suitableDidsForExchange: .init(
                    didsByConfigurationId: [
                        "UniversityDegreeSdJwt": .init(
                            dids: [
                                .init(
                                    did: "did:key:xyz",
                                    methodData: .didKey(keyType: .ed25519),
                                    tags: [RecordTag(name: "alias", value: "School DID")]
                                ),
                                .init(
                                    did: "did:jwk:abc",
                                    methodData: .didJwk(keyType: .ed25519),
                                    tags: []
                                )
                            ],
                            restriction: .init()
                        )
                    ]
                ),
                authorizeExchange: { _ in },
                acceptCredential: { _, _ in },
                storeCredential: {},
                onDismissRequest: {}
            )
        }
    }
}
