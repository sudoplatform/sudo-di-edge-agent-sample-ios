//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import struct SudoDIEdgeAgent.Message
import protocol SudoDIEdgeAgent.MessageSource
import struct SudoDIEdgeAgent.ReceivedMessageMetadata
import struct SudoDIEdgeAgent.Routing
import SudoDIRelay
import SudoLogging

/// Implementation of `MessageSource` which consumes a `SudoDIRelayClient` to fetch messages.
public class SudoDIRelayMessageSource: MessageSource {
    // MARK: - Properties

    private let relayClient: SudoDIRelayClient
    private let logger: Logger

    // MARK: - Lifecycle

    public init(relayClient: SudoDIRelayClient, logger: Logger) {
        self.relayClient = relayClient
        self.logger = logger
    }

    // MARK: - Convenience

    ///
    /// Utility function to translate a `SudoDIRelayClient`'s `Postbox` into a
    /// `Routing` such that the postbox's public information can be shared with
    /// peers when starting a connection (i.e. via `ConnectionExchangeModule.acceptConnection`).
    ///
    /// Common usage involves creating a `Postbox` per connection (via `SudoDIRelayClient.createPostbox`)
    /// before calling `ConnectionExchangeModule.acceptConnection`.
    public class func routingFromPostbox(postbox: Postbox) -> Routing {
        return Routing(serviceEndpoint: postbox.serviceEndpoint, routingVerkeys: [])
    }

    // MARK: - Conformance - MessageSource

    public func getMessage() async throws -> Message? {
        guard let relayMessage = try await tryGetMessage() else {
            return nil
        }
        let metadata = ReceivedMessageMetadata(
            receivedTime: relayMessage.createdAt
        )
        return Message(
            id: relayMessage.id,
            body: Data(relayMessage.message.utf8),
            metadata: metadata
        )
    }

    public func finalizeMessage(id: String) async throws {
        do {
            _ = try await relayClient.deleteMessage(withMessageId: id)
        } catch let e as SudoDIRelayError {
            logger.error("Unable to delete message \(id): \(e.localizedDescription)")
            throw e
        }
    }

    private func tryGetMessage() async throws -> SudoDIRelay.Message? {
        do {
            let messagesList = try await relayClient.listMessages(limit: nil, nextToken: nil)
            return messagesList.items.first
            // Note in theory it would be possible to cache multiple messages here, and return them
            // as requested. This implementation would be made more complex by having to manage
            // the interaction with finalizeMessage and is not deemed necessary for the most common
            // use case (where there are a very small number of messages in the postbox), and each call
            // to getMessage is matched by an almost immediate finalize.
            // Additionally, we could optimize this process by using subscriptions to incoming messages.
        } catch let e as SudoDIRelayError {
            logger.error("Unable to retrieve messages: \(e.localizedDescription)")
            throw e
        }
    }
}
