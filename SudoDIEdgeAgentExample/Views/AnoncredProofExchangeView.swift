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
    
    @State private var text: String = ""

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
                    if !viewModel.credentialIdsForAttributeGroups.isEmpty {
                        Section {
                            Text("Requested Attributes")
                        }
                            .frame(maxWidth: .infinity)
                        ForEach(Array(viewModel.credentialIdsForAttributeGroups), id: \.key) { referent, _ in
                            let info = viewModel.anoncredProofRequest.requestedAttributes[referent]!
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

                    if !viewModel.credentialIdsForPredicates.isEmpty {
                        Section {
                            Text("Requested Predicates")
                        }
                            .frame(maxWidth: .infinity)
                        ForEach(Array(viewModel.credentialIdsForPredicates), id: \.key) { referent, _ in
                            let info = viewModel.anoncredProofRequest.requestedPredicates[referent]!
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
                    
                    if !viewModel.selfAttestableAttributeReferents.isEmpty {
                        Section {
                            Text("Self Attestable Attributes")
                        }
                            .frame(maxWidth: .infinity)
                        ForEach(viewModel.selfAttestableAttributeReferents, id: \.self) { referent in
                            let info = viewModel.anoncredProofRequest.requestedAttributes[referent]!
                            let attributeName = info.groupAttributes.first!
                            VStack {
                                Text("\(attributeName):")
                                TextField("Enter a value...", text: viewModel.selfAttestedAttributeBinding(for: referent))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(minHeight: 50)
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
        AnoncredProofExchangeView(viewModel: .init(
            proof: .aries(.init(
                proofExchangeId: "proofExchangeId",
                tags: [
                    .init(name: "~created_timestamp", value: "1698891059")
                ],
                errorMessage: nil,
                state: .presented,
                connectionId: "connectionId",
                initiator: .internal,
                formatData: .anoncred(proofRequest: AnoncredProofRequestInfo(
                    name: "Proof Req",
                    version: "1.0",
                    requestedAttributes: [:],
                    requestedPredicates: [:],
                    nonRevoked: nil
                ))
            )),
            proofRequest: .init(
                name: "Proof Req",
                version: "1.0",
                requestedAttributes: [:],
                requestedPredicates: [:],
                nonRevoked: nil
            )
        ))
    }
}
