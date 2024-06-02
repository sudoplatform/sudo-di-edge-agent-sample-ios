//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
// 

import Foundation
import SudoDIEdgeAgent

/// paging limit of messages to fetch at once. Kept low for sake of pagination demonstration
private let pageLimit: UInt = 10

class ConnectionChatViewModel: ObservableObject {
    
    /// The connection the view model's chat is with
    let connection: Connection

    /// State for whether the viewmode view model is actively loading more messages
    @Published var isLoadingMore: Bool
    
    /// UI state for whether there is more items to be loaded  by means of pagination
    var isMoreToLoad: Bool {
        nextToken != nil
    }
    
    /// Current pagination cursor if there is more messages to be loaded
    @Published private var nextToken: String?
    
    /// Current list of messages that have been loaded in chronological descending order
    @Published var messageList: [BasicMessage]
    
    /// An error alert message to display (if not null)
    @Published var alertMessage: String?
    
    /// subscriberId is used to be able to unsubscribe from agent events after navigating away from the view
    private var subscriberId: String?
    
    init(
        connection: Connection,
        isLoadingMore: Bool = false,
        nextToken: String? = nil,
        messageList: [BasicMessage] = [],
        alertMessage: String? = nil,
        subscriberId: String? = nil
    ) {
        self.connection = connection
        self.isLoadingMore = isLoadingMore
        self.nextToken = nextToken
        self.messageList = messageList
        self.alertMessage = alertMessage
        self.subscriberId = subscriberId
    }
    
    func clearAlert() {
        alertMessage = nil
    }
    
    /// On initialization of the compose, load an initial page of messages for the connection and set the initial list state.
    /// Also create a subscription to incoming basic messages.
    func initialize() {
        Task { @MainActor in
            do {
                subscribe()
                
                let page = try await Clients.agent.connections.messaging.listBasicMessages(
                    options: .init(
                        filters: .init(connectionId: connection.connectionId),
                        paging: .init(limit: pageLimit, nextToken: nil),
                        sorting: .chronological(direction: .descending)
                    )
                )
                nextToken = page.nextToken
                messageList = page.items
            } catch {
                NSLog("Failed to load initial messages \(error.localizedDescription)")
                alertMessage = error.localizedDescription
            }
        }
    }
    
    /// Subscribe to incoming basic messages, will add messages to the list if they are from the same connection as stored
    /// in this view model.
    private func subscribe() {
        subscriberId = Clients.agent.subscribeToAgentEvents(subscriber: BasicMessageSubscriber(viewModel: self))
    }
    
    /// On disposal of the view, clean up by unsubscribing from events
    func teardown() {
        if let id = subscriberId {
            Clients.agent.unsubscribeToAgentEvents(subscriptionId: id)
        }
    }
    
    /// Send a message to the connection, then add the sent outbound message to the UI message list
    func sendMessage(content: String) {
        Task { @MainActor in
            do {
                let sentMessage = try await Clients.agent.connections.messaging.sendBasicMessage(
                    connectionId: connection.connectionId,
                    content: content
                )
                messageList.insert(.outbound(sentMessage), at: 0)
            } catch {
                NSLog("Failed to send message \(error.localizedDescription)")
                alertMessage = error.localizedDescription
            }
        }
    }
    
    /// Loads the next page of older messages to fetch (if any). Adds the new page to the UI message list,
    /// and remembers the new nextToken (pagination cursor).
    func loadOlder() {
        Task { @MainActor in
            guard let token = nextToken else {
                return
            }
            
            isLoadingMore = true
            do {
                let page = try await Clients.agent.connections.messaging.listBasicMessages(
                    options: .init(
                        filters: .init(connectionId: connection.connectionId),
                        paging: .init(limit: pageLimit, nextToken: token),
                        sorting: .chronological(direction: .descending)
                    )
                )
                
                nextToken = page.nextToken
                messageList.append(contentsOf: page.items)
            } catch {
                NSLog("Failed to load older messages \(error.localizedDescription)")
                alertMessage = error.localizedDescription
            }
            isLoadingMore = false
        }
    }
}

/// Subscriber to incoming basic messages, will add messages to the viewModel's message list if they are
/// from the same connection as stored in this view model.
private class BasicMessageSubscriber: AgentEventSubscriber {
    let viewModel: ConnectionChatViewModel
    
    init(viewModel: ConnectionChatViewModel) {
        self.viewModel = viewModel
    }
    
    func connectionExchangeStateChanged(connectionExchange: ConnectionExchange) {
        // no-op
    }
    
    func credentialExchangeStateChanged(credentialExchange: CredentialExchange) {
        // no-op
    }
    
    func proofExchangeStateChanged(proofExchange: ProofExchange) {
        // no-op
    }
    
    func inboundBasicMessage(basicMessage: BasicMessage.Inbound) {
        Task { @MainActor in
            if basicMessage.connectionId != viewModel.connection.connectionId {
                return
            }
            viewModel.messageList.insert(.inbound(basicMessage), at: 0)
        }
    }
    
    func messageProcessed(messageId: String) {
        // no-op
    }
}
