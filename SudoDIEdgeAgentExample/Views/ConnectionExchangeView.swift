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
                                        viewModel.acceptNewConnection(connection.connectionExchangeId)
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
            let exchangeId = exchange.connectionExchangeId
            AcceptInvitationAlertView(
                exchange: exchange,
                onDecline: { viewModel.decline(exchangeId) },
                onAcceptReuseConnection: { viewModel.tryReuseConnection(exchangeId, with: $0) },
                onAcceptNewConnection: { viewModel.acceptNewConnection(exchangeId) }
            )
        }
    }
}

/// displays the details of an incoming `ConnectionExchange` (i.e. invitation).
///
/// Displays the option to reuse (if possible), accept or reject the connection.
struct AcceptInvitationAlertView: View {
    let exchange: ConnectionExchange
    let onDecline: () -> Void
    let onAcceptReuseConnection: (String) -> Void
    let onAcceptNewConnection: () -> Void
    
    /// ID of a `Connection` which may be reusable for this exchange (if any)
    @State private var existingConnectionId: String?

    func declineReuse() {
        existingConnectionId = nil
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("Incoming Invitation")
                .font(.largeTitle)
            if let existingConn = existingConnectionId {
                Text("Looks like you already have a connection with this peer: '\(existingConn)'")
                Text("Do you wish to try reuse it?")
                Spacer()
                HStack {
                    Button("Reuse") {
                        onAcceptReuseConnection(existingConn)
                    }
                    .padding()
                    .padding(.leading)
                    .padding(.trailing)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    Button("No") {
                        declineReuse()
                    }
                    .padding()
                    .padding(.leading)
                    .padding(.trailing)
                    .background(.red)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            } else {
                Text("From: \(exchange.theirLabel ?? "")")
                    .font(.title)
                Text("Create a new connection?")
                Spacer()
                HStack {
                    Button("Accept") {
                        onAcceptNewConnection()
                    }
                    .padding()
                    .padding(.leading)
                    .padding(.trailing)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    Button("Decline") {
                        onDecline()
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
        .onAppear {
            existingConnectionId = exchange.reusableConnectionIds.first
        }
    }
}

struct ConnectionExchangeView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionExchangeView()
    }
}
