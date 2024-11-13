//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import SudoDIEdgeAgent

struct ProofExchangeListView: View {
    @StateObject var viewModel: ProofExchangeListViewModel = .init()

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.exchanges.isEmpty {
                    Spacer()
                    Text("No Pending Proofs")
                        .font(.largeTitle)
                    Text("If proofs aren't appearing, ensure that the agent is running.")
                        .padding(.leading, 35)
                        .padding(.trailing, 35)
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.exchanges) { proof in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(proof.proofExchangeId)
                                    Text(viewModel.getState(proof.state))
                                }
                                Spacer()

                                PresentButtonView(isLoading: $viewModel.isLoading, proof: proof)
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
                .padding()
                .frame(width: 200)
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .disabled(viewModel.isLoading)
            }
            .navigationTitle("Proof Exchange")
            .task { viewModel.subscribe() }
            .onDisappear(perform: viewModel.unsubscribe)
        }
    }
}

struct PresentButtonView: View {
    @Binding var isLoading: Bool
    var proof: ProofExchange
    

    var body: some View {
        if proof.state == .aries(.request) || proof.state == .openId4Vc(.request) {
            NavigationLink("Present") {
                switch proof {
                case .aries(let aries):
                    switch aries.formatData {
                    case .indy(let proofRequest):
                        AnoncredProofExchangeView(viewModel: .init(
                            proof: proof,
                            proofRequest: proofRequest
                        ))
                    case .dif(let dif):
                        DifProofExchangeView(viewModel: .init(
                            proof: proof,
                            proofRequest: dif
                        ))
                    }
                case .openId4Vc(let oid4vc):
                    DifProofExchangeView(viewModel: .init(
                        proof: proof,
                        proofRequest: oid4vc.presentationRequest
                    ))
                }
            }.frame(maxWidth: 85)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .buttonStyle(.borderless)
                .disabled(isLoading)
        }
    }
}

struct ProofExchangeListView_Previews: PreviewProvider {
    static var previews: some View {
        ProofExchangeListView()
    }
}
