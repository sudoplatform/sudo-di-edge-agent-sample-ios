//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct CredentialListView: View {
    @StateObject var viewModel: CredentialListViewModel = .init()

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.credentials.isEmpty {
                    Spacer()
                    Text("No Credentials")
                        .font(.largeTitle)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.credentials) { credential in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(credential.id)
                                    Text(credential.previewName)
                                    Text(credential.previewFormat)
                                }
                                Spacer()

                                Button("Info") {
                                    viewModel.showInfo(credential)
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
            .navigationTitle("Credentials")
            .task { viewModel.refresh() }
            .sheet(item: $viewModel.presentedCredential, onDismiss: viewModel.dismissInfo) { credential in
                VStack {
                    CredentialView(credential: credential)
                        .navigationTitle("Info")
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

struct CredentialListView_Previews: PreviewProvider {
    static var previews: some View {
        CredentialListView()
    }
}
