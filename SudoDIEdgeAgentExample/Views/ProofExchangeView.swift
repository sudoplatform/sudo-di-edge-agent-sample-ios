//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import SudoDIEdgeAgent

struct ProofExchangeView: View {
    // SwiftUI doesn't make it easy to dismiss/pop views so one way is to use the `@Environment(.\dismiss).
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: ProofExchangeViewModel

    var body: some View {
        NavigationStack {
            Spacer()
            VStack {
                BoldedLineItem(name: "ID: ", value: viewModel.proof.proofExchangeId)
                BoldedLineItem(name: "From Connection: ", value: viewModel.proof.connectionId)
                Divider()
                List {
                    if !viewModel.attributes.isEmpty {
                        Section {
                            Text("Requested Attributes")
                        }
                            .frame(maxWidth: .infinity)
                        ForEach(viewModel.attributes) { attribute in
                            HStack {
                                Text(attribute.groupAttributes.sorted().joined(separator: ", "))
                                Spacer()
                                Button {
                                    viewModel.attributeSelected(attribute, for: attribute.groupAttributes)
                                } label: {
                                    viewModel.attributeCredentials[attribute.groupIdentifier] == ""
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

                    if !viewModel.predicates.isEmpty {
                        Section {
                            Text("Requested Predicates")
                        }
                            .frame(maxWidth: .infinity)
                        ForEach(viewModel.predicates) { predicate in
                            HStack {
                                Text(predicate.predicateIdentifier)
                                Text(viewModel.formatPredicate(predicate))
                                Spacer()
                                Button {
                                    viewModel.predicateSelected(predicate)
                                } label: {
                                    viewModel.attributeCredentials[predicate.predicateIdentifier] == ""
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
            .sheet(item: $viewModel.presentation) { presentation in
                CredentialForItemView(presentation: presentation, selectedCred: viewModel.setCredential)
            }
        }
    }
}

struct ProofExchangeView_Previews: PreviewProvider {
    static var previews: some View {
        ProofExchangeView(viewModel: .init(proof: .init(
            proofExchangeId: "proofExchangeId",
            connectionId: "connectionId",
            initiator: .internal,
            state: .presented,
            errorMessage: nil, tags: [
                .init(name: "~created_timestamp", value: "1698891059")
            ])
        ))
    }
}
