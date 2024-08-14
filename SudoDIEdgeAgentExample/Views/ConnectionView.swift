//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoDIEdgeAgent
import SwiftUI

struct ConnectionView: View {
    @StateObject var viewModel: ConnectionViewModel = .init()

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.connections.isEmpty {
                    Spacer()
                    Text("No Connections")
                        .font(.largeTitle)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.connections) { connection in
                            NavigationLink(
                                destination: {
                                    ConnectionChatView(
                                        viewModel: .init(
                                            connection: connection
                                        )
                                    )
                                },
                                label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(connection.theirLabel ?? "")
                                            Text(connection.id)
                                        }
                                        Spacer()
                                        Image(systemName: "message")
                                    }
                                }
                            )
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
            .navigationTitle("Connections")
            .task { viewModel.refresh() }
            .alert("Error Occurred", isPresented: $viewModel.showAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }
}

struct ConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionView(viewModel: .init(
            connections: [
                Connection(
                    connectionId: "1",
                    connectionExchangeId: "1",
                    theirLabel: "Foo",
                    tags: []
                ),
                Connection(
                    connectionId: "2",
                    connectionExchangeId: "1",
                    theirLabel: "Bar",
                    tags: []
                )
            ]
        ))
    }
}
