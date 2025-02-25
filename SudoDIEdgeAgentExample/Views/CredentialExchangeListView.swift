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
                        ForEach(viewModel.exchanges) { exchange in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(exchange.exchange.credentialExchangeId)
                                    Text(exchange.exchangeTypeName)
                                    if let name = exchange.credPreview?.previewName {
                                        Text(name)
                                    }
                                    if let fmt = exchange.credPreview?.previewFormat {
                                        Text(fmt)
                                    }
                                    Text(viewModel.getState(exchange.exchange.state))
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
                .standardButtonTheme()
                .disabled(viewModel.isLoading)
            }
            .navigationTitle("Credential Exchange")
            .task { viewModel.subscribe() }
            .onDisappear(perform: viewModel.unsubscribe)
            .sheet(
                item: $viewModel.presentedExchange,
                onDismiss: viewModel.dismissInfo
            ) { exchange in
                VStack {
                    CredentialExchangeView(
                        viewModel: .init(exchange: exchange),
                        onDismissRequest: viewModel.dismissInfo
                    )
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
