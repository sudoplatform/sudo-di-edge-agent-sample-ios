//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct CredentialExchangeListView: View {
    @StateObject var viewModel: CredentialExchangeListViewModel = .init()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.exchanges.isEmpty {
                    Spacer()
                    Text("No Pending Credentials")
                        .font(.largeTitle)
                    Text("If credentials aren't appearing, ensure that the agent is running.")
                        .padding(.leading, 35)
                        .padding(.trailing, 35)
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.exchanges.sorted { $0.createdAt ?? .now > $1.createdAt ?? .now }) { exchange in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(exchange.credentialExchangeId)
                                    Text(exchange.credentialMetadata.credentialDefinitionInfo?.name ?? "")
                                    Text(viewModel.getState(exchange.state))
                                }
                                Spacer()

                                Button("Info") {
                                    viewModel.showInfo(exchange)
                                }
                                .frame(maxWidth: 55)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                                .buttonStyle(.borderless)
                                .disabled(viewModel.isLoading)
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
            .navigationTitle("Credential Exchange")
            .task { viewModel.subscribe() }
            .onDisappear(perform: viewModel.unsubscribe)
            .sheet(item: $viewModel.presentedExchange, onDismiss: viewModel.dismissInfo) { exchange in
                VStack {
                    CredentialExchangeView(viewModel: .init(credential: exchange))
                    if exchange.state == .offer {
                        Button(action: viewModel.accept) {
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Accept")
                            }
                        }
                        .padding()
                        .frame(width: 200)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .disabled(viewModel.isLoading)
                        .frame(maxWidth: .infinity)
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
}

struct CredentialExchangeListView_Previews: PreviewProvider {
    static var previews: some View {
        CredentialExchangeListView()
    }
}
