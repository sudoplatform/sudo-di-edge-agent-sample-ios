//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import SudoDIEdgeAgent

struct DifProofExchangeView: View {
    // SwiftUI doesn't make it easy to dismiss/pop views so one way is to use the `@Environment(.\dismiss).
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: DifProofExchangeViewModel

    var body: some View {
        NavigationStack {
            Spacer()
            VStack {
                BoldedLineItem(name: "ID", value: viewModel.proof.proofExchangeId)
                switch viewModel.proof {
                case .aries(let aries): BoldedLineItem(
                    name: "From Connection",
                    value: aries.connectionId
                )
                case .openId4Vc(let oid4vc): BoldedLineItem(
                    name: "From Verifier",
                    value: oid4vc.verifierId
                )
                }
                Divider()
                List {
                    Section {
                        Text("Requested Input Descriptors")
                    }
                        .frame(maxWidth: .infinity)
                    ForEach(Array(viewModel.difProofRequest.inputDescriptors), id: \.id) { inputDescriptor in
                        let descId = inputDescriptor.id
                        HStack {
                            Text(inputDescriptor.name ?? descId)
                            Spacer()
                            Button {
                                viewModel.startSelectingCredentialForInputDescriptor(descriptorId: descId)
                            } label: {
                                viewModel.selectedCredentialIdsForDescriptors[descId] == nil
                                ? Text("Select")
                                : Text("Reselect")
                            }
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                    }
                }

                Button(action: viewModel.present) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Present")
                    }
                }
                .standardButtonTheme()
                .disabled(viewModel.isLoading)
            }
            .padding()
            .navigationTitle("Info")
            .task { viewModel.initialize() }
            .alert("Success", isPresented: $viewModel.dismissProof) {
                Button("Ok") { dismiss() }
            } message: {
                Text("The proof was successfully presented.")
            }
            .sheet(item: $viewModel.selectingCredentialForDescriptor) { descriptor in
                SelectCredentialForDifItemView(
                    inputDescriptor: descriptor,
                    suitableCredentials: viewModel.credentialsForRequestedDescriptors[descriptor.id] ?? [],
                    onSelectCredential: { viewModel.selectCredentialForInputDescriptor($0, descriptor.id) }
                )
            }
        }
    }
}
