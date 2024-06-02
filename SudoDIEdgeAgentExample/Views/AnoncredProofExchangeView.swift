//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import SudoDIEdgeAgent

struct AnoncredProofExchangeView: View {
    // SwiftUI doesn't make it easy to dismiss/pop views so one way is to use the `@Environment(.\dismiss).
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: AnoncredProofExchangeViewModel

    var body: some View {
        NavigationStack {
            Spacer()
            VStack {
                BoldedLineItem(name: "ID", value: viewModel.proof.proofExchangeId)
                BoldedLineItem(name: "From Connection", value: viewModel.proof.connectionId)
                Divider()
                List {
                    if !viewModel.anoncredProofRequest.requestedAttributes.isEmpty {
                        Section {
                            Text("Requested Attributes")
                        }
                            .frame(maxWidth: .infinity)
                        ForEach(Array(viewModel.anoncredProofRequest.requestedAttributes), id: \.key) { referent, info in
                            HStack {
                                Text(info.groupAttributes.sorted().joined(separator: ", "))
                                Spacer()
                                Button {
                                    viewModel.startSelectingCredentialForAttributeGroup(referent)
                                } label: {
                                    viewModel.selectedCredentialsForAttributeGroups[referent] == ""
                                    ? Text("Select")
                                    : Text("Reselect")
                                }
                                .padding()
                                .frame(width: 110)
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                            }
                        }
                    }

                    if !viewModel.anoncredProofRequest.requestedPredicates.isEmpty {
                        Section {
                            Text("Requested Predicates")
                        }
                            .frame(maxWidth: .infinity)
                        ForEach(Array(viewModel.anoncredProofRequest.requestedPredicates), id: \.key) { referent, info in
                            HStack {
                                Text(referent)
                                Text(viewModel.formatPredicate(info))
                                Spacer()
                                Button {
                                    viewModel.startSelectingCredentialForPredicate(referent)
                                } label: {
                                    viewModel.selectedCredentialsForPredicates[referent] == ""
                                    ? Text("Select")
                                    : Text("Reselect")
                                }
                                .padding()
                                .frame(maxWidth: 90)
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                            }
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
                .padding()
                .frame(width: 200)
                .background(viewModel.presentEnabled ? .blue : .gray)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .disabled(!viewModel.presentEnabled)
            }
            .padding()
            .navigationTitle("Info")
            .task { viewModel.retrieveRequests() }
            .alert("Success", isPresented: $viewModel.dismissProof) {
                Button("Ok") { dismiss() }
            } message: {
                Text("The proof was successfully presented.")
            }
            .sheet(item: $viewModel.selectingCredentialsForItem) { item in
                SelectCredentialForAnoncredItemView(
                    item: item,
                    onSelectCredential: viewModel.selectCredentialForReferent
                )
            }
        }
    }
}

struct ProofExchangeView_Previews: PreviewProvider {
    static var previews: some View {
        AnoncredProofExchangeView(viewModel: .init(proof: .init(
            proofExchangeId: "proofExchangeId",
            connectionId: "connectionId",
            initiator: .internal,
            state: .presented,
            formatData: .indy(proofRequest: AnoncredProofRequestInfo(
                name: "Proof Req",
                version: "1.0",
                requestedAttributes: [:],
                requestedPredicates: [:],
                nonRevoked: nil
            )),
            errorMessage: nil, tags: [
                .init(name: "~created_timestamp", value: "1698891059")
            ])
        ))
    }
}
