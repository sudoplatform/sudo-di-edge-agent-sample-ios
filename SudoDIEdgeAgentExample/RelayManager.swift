//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIRelay

class RelayManager {

    /// The `SudoDIRelayClient` is responsible for being a messaging mechanism for the Edge Agent
    private let relayClient: SudoDIRelayClient
    /// The `SudoDIRelayClient` has certain proofs its needs from the `SudoProfilesClient`
    private let sudoManager: SudoManager

    init(relayClient: SudoDIRelayClient, sudoManager: SudoManager) {
        self.relayClient = relayClient
        self.sudoManager = sudoManager
    }

    /// Method for creating a `Postbox` from a `ConnectionExchange`
    func createPostbox(connectionId: String) async throws -> Postbox {
        do {
            // Ownership Proof token is needed to show that a sudo can create a postbox
            let proof = try await sudoManager.getPostboxProof()
            let postbox = try await relayClient.createPostbox(withConnectionId: connectionId,
                                                              ownershipProofToken: proof,
                                                              isEnabled: true)
            return postbox
        } catch {
            NSLog("Error creating postbox \(error.localizedDescription)")
            throw RelayManagerError.createPostbox
        }
    }
}

extension RelayManager {
    enum RelayManagerError: Error {
        case createPostbox
    }
}
