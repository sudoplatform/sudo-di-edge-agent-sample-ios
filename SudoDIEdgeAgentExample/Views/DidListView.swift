//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoDIEdgeAgent
import SwiftUI

struct DidListView: View {
    @StateObject var viewModel: DidListViewModel = .init()
    
    @State private var createDidDialogState: CreateDidDialogState?
    @State var aliasInput = ""

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.dids.isEmpty {
                    Spacer()
                    Text("No DIDs")
                        .font(.largeTitle)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.dids) { did in
                            VStack(alignment: .leading) {
                                Text(did.did).lineLimit(1)
                                Text("Alias: \(did.alias ?? "None")")
                                Text("Key Type: \(did.keyType)")
                            }
                        }
                        .onDelete(perform: viewModel.delete)
                    }
                }

                Button(action: viewModel.refresh) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Refresh")
                    }
                }
                .standardButtonTheme()
                .disabled(viewModel.isLoading)

                Button(
                    action: { createDidDialogState = .selectMethod },
                    label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Create DID")
                        }
                    }
                )
                .standardButtonTheme()
                .disabled(viewModel.isLoading)
                .createDidFlowDialogs(
                    state: createDidDialogState,
                    updateState: { createDidDialogState = $0 },
                    onCancel: {
                        createDidDialogState = nil
                        aliasInput = ""
                    },
                    onSubmit: { options in viewModel.createDid(
                        options: options,
                        alias: aliasInput
                    ) },
                    aliasInput: $aliasInput
                )
            }
            .navigationTitle("DIDs")
            .task { viewModel.refresh() }
            .alert("Error Occurred", isPresented: $viewModel.showAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
}

extension View {
    func createDidFlowDialogs(
        state: CreateDidDialogState?,
        updateState: @escaping (CreateDidDialogState) -> Void,
        onCancel: @escaping () -> Void,
        onSubmit: @escaping (_ options: CreateDidOptions) -> Void,
        aliasInput: Binding<String>
    ) -> some View {
        
        return alert(
            "Select a DID Method",
            isPresented: Binding(
                get: { if case .selectMethod = state { true } else { false } },
                set: {_, _ in }
            )
        ) {
            Button("did:key") {
                updateState(.selectKeyType(method: .didKey))
            }
            Button("did:jwk") {
                updateState(.selectKeyType(method: .didJwk))
            }
            Button("Cancel", role: .cancel) {
                onCancel()
            }
        }
        .alert(
            "Select a Key Type",
            isPresented: Binding(
                get: { if case .selectKeyType = state { true } else { false } },
                set: {_, _ in }
            )
        ) {
            if case .selectKeyType(let method) = state {
                Button("P256") {
                    updateState(.selectEnclaveType(
                        method: method,
                        keyType: .p256
                    ))
                }
                Button("Ed25519") {
                    updateState(.selectEnclaveType(
                        method: method,
                        keyType: .ed25519
                    ))
                }
            }
            Button("Cancel", role: .cancel) {
                onCancel()
            }
        }
        .alert(
            "Select an Enclave Type",
            isPresented: Binding(
                get: { if case .selectEnclaveType = state { true } else { false } },
                set: {_, _ in }
            )
        ) {
            if case .selectEnclaveType(let method, let keyType) = state {
                Button("Software") {
                    updateState(.enterAlias(
                        method: method,
                        keyType: keyType,
                        enclaveType: .internal
                    ))
                }
                Button("iOS SecureEnclave") {
                    updateState(.enterAlias(
                        method: method,
                        keyType: keyType,
                        enclaveType: .external(.init(
                            providerClass: IOSHardwareCryptoProvider.self,
                            providerOptions: .init()
                        ))
                    ))
                }
            }
            Button("Cancel", role: .cancel) {
                onCancel()
            }
        }
        .alert(
            "Enter an alias for this DID",
            isPresented: Binding(
                get: { if case .enterAlias = state { true } else { false } },
                set: {_, _ in }
            )
        ) {
            if case .enterAlias(let method, let keyType, let enclaveType) = state {
                TextField("Enter an alias...", text: aliasInput)
                Button("Create") {
                    let opts: CreateDidOptions
                    switch method {
                    case .didKey: opts = .didKey(keyType: keyType, enclaveOptions: enclaveType)
                    case .didJwk: opts = .didJwk(keyType: keyType, enclaveOptions: enclaveType)
                    }
                    onSubmit(opts)
                }
            }
            Button("Cancel", role: .cancel) {
                onCancel()
            }
        }
    }
}

struct DidListView_Previews: PreviewProvider {
    static var previews: some View {
        DidListView(viewModel: .init(
            dids: [
                .init(
                    did: "did:key:bar",
                    methodData: .didKey(keyType: .p256),
                    tags: [.init(name: "alias", value: "School DID")]
                ),
                .init(
                    did: "did:key:foo",
                    methodData: .didKey(keyType: .ed25519),
                    tags: [.init(name: "alias", value: "Work DID")]
                ),
                .init(
                    did: "did:jwk:bar",
                    methodData: .didKey(keyType: .p256),
                    tags: []
                )
            ]
        ))
    }
}
