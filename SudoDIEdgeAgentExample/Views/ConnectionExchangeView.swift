//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import CodeScanner
import SudoDIEdgeAgent

struct ConnectionExchangeView: View {
    @StateObject var viewModel: ConnectionExchangeViewModel = .init()

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.exchanges.isEmpty {
                    Spacer()
                    Text("No Pending Connections")
                        .font(.largeTitle)
                    Text("If connections aren't appearing, ensure that the agent is running.")
                        .padding(.leading, 35)
                        .padding(.trailing, 35)
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.exchanges) { connection in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(connection.theirLabel ?? "")
                                    Text(connection.connectionExchangeId)
                                    Text(viewModel.getConnectionState(connection.state))
                                }
                                Spacer()

                                if connection.state == .invitation && connection.role == .invitee {
                                    Button("Accept") {
                                        viewModel.accept(connection.connectionExchangeId)
                                    }
                                    .padding()
                                    .background(.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                                    .buttonStyle(.borderless)
                                    .disabled(viewModel.isLoading)
                                }
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

                Button("Accept Invitation") {
                    viewModel.isPresentingScanner = true
                }
                    .padding()
                    .frame(width: 200)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .disabled(viewModel.isLoading)
                
                    NavigationLink("Create Invitation") {
                        ConnectionInvitationCreateView(
                            viewModel: .init()
                        )
                    }
                
                    .padding()
                    .frame(width: 200)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .disabled(viewModel.isLoading)
            }
            .navigationTitle("Connections Exchange")
        }
        .task {
            viewModel.subscribe()
        }
        .onDisappear(perform: viewModel.unsubscribe)
        .alert("Error Occurred", isPresented: $viewModel.showAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("Success!", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {}
        } message: {
            Text("The connection was successfully accepted")
        }
        .sheet(isPresented: $viewModel.isPresentingScanner) {
            VStack {
                Text("Scan QR Code")
                    .font(.largeTitle)
                CodeScannerView(codeTypes: [.qr], simulatedData: ConnectionExchangeViewModel.simulatedQRCode) { response in
                    if case let .success(result) = response {
                        viewModel.queueInvitation(result.string)
                    }
                }
                Button("Dismiss") {
                    viewModel.isPresentingScanner = false
                }
                    .padding()
                    .padding(.leading)
                    .padding(.trailing)
                    .frame(width: 200)
                    .background(.red)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding()
            .padding(.top, 50)
            .padding(.bottom, 50)
        }
        .sheet(item: $viewModel.incomingExchange) { exchange in
            VStack {
                Spacer()
                Text("Incoming Invitation")
                    .font(.largeTitle)
                Text("From: \(exchange.theirLabel ?? "")")
                    .font(.title)
                Spacer()
                HStack {
                    Button("Accept") {
                        viewModel.accept(exchange.connectionExchangeId)
                    }
                        .padding()
                        .padding(.leading)
                        .padding(.trailing)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    Button("Decline") {
                        viewModel.decline(exchange.connectionExchangeId)
                    }
                        .padding()
                        .padding(.leading)
                        .padding(.trailing)
                        .background(.red)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

struct ConnectionExchangeView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionExchangeView()
    }
}
