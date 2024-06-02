//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
// 

import SwiftUI
import SudoDIEdgeAgent

struct ConnectionChatView: View {
    @StateObject var viewModel: ConnectionChatViewModel
    
    @State var chatInput: String = ""
    
    func sendMessage() {
        viewModel.sendMessage(content: chatInput)
        chatInput = ""
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.messageList, id: \.id) { message in
                            HStack {
                                if case .outbound = message {
                                    Spacer()
                                    Text(message.content)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .frame(maxWidth: 250, alignment: .trailing)
                                } else {
                                    Text(message.content)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(Color(UIColor.label))
                                        .cornerRadius(10)
                                        .frame(maxWidth: 250, alignment: .leading)
                                    Spacer()
                                }
                            }
                            .scaleEffect(x: 1, y: -1, anchor: .center)
                        }
                    }
                    .padding()
                    if viewModel.isMoreToLoad {
                        HStack {
                            if !viewModel.isLoadingMore {
                                Button(
                                    action: { viewModel.loadOlder()},
                                    label: { Text("Load more") }
                                )
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(.capsule)
                                
                            } else {
                                ProgressView()
                            }
                        }
                        .scaleEffect(x: 1, y: -1, anchor: .center)
                    }
                }
                .padding(.bottom)
                .scaleEffect(x: 1, y: -1, anchor: .center)
                HStack {
                    TextField("Enter message...", text: $chatInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 50)
                    
                    Button(action: sendMessage) {
                        Text("Send")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle(
                viewModel.connection.theirLabel ?? viewModel.connection.connectionId
            )
        }
        .task {
            viewModel.initialize()
        }
        .onDisappear(perform: { viewModel.teardown() })
        .alert(
            "Error Occurred",
            isPresented: .constant(viewModel.alertMessage != nil)
        ) {
            Button("OK") {
                viewModel.clearAlert()
            }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }
}

struct ConnectionChatView_Preview: PreviewProvider {
    static var previews: some View {
        ConnectionChatView(
            viewModel: .init(
                connection: .init(
                    connectionId: "1",
                    connectionExchangeId: "1",
                    theirLabel: "Bob",
                    tags: []
                ),
                nextToken: "a",
                messageList: [
                    .inbound(.init(
                        id: "1",
                        connectionId: "",
                        content: "foo",
                        receivedTime: Date.now,
                        reportedSentTime: Date.now
                    )),
                    .outbound(.init(
                        id: "3",
                        connectionId: "",
                        content: "basdfasdfasdfasdfar",
                        sentTime: Date.now
                    ))
                ]
            )
        )
    }
}
