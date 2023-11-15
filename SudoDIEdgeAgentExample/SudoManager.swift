//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoProfiles

/// A manager to help manage operations that relate to a `Sudo`.
/// For the purposes of the example app, the `SudoManager` will only track one `Sudo`
/// To learn more about `Sudo` see: https://docs.sudoplatform.com/guides/sudos
class SudoManager {
    
    /// the sudo that is tied to `SudoDIRelay`
    private var globalSudo: Sudo?

    /// `SudoProfilesClient` is responsible for interactions with a `Sudo`
    private let profilesClient: SudoProfilesClient

    init(profilesClient: SudoProfilesClient) {
        self.profilesClient = profilesClient
    }

    /// Creates a sudo with an `id` of `"sudo"`
    func createSudo() async throws {
        let sudo = Sudo(id: "sudo")
        globalSudo = try await profilesClient.createSudo(sudo: sudo)
    }

    /// Gets the global sudo or the first sudo in the list
    func getSudo() async throws -> Sudo? {
        if let sudo = globalSudo {
            return sudo
        }

        let sudos = try await profilesClient.listSudos(option: .remoteOnly)
        if let sudo = sudos.first {
            globalSudo = sudo
            return sudo
        }
        
        return nil
    }

    /// Gets the ownership proof for the relay postbox
    func getPostboxProof() async throws -> String {
        guard let sudo = globalSudo else {
            throw SudoManagerError.missingSudo
        }

        // A token is returned that shows a given sudo can create a relay postbox
        let proof = try await profilesClient.getOwnershipProof(sudo: sudo, audience: "sudoplatform.relay.postbox")

        return proof
    }

    /// Resets the profiles client and unassigns the global sudo
    func reset() throws {
        globalSudo = nil
        try self.profilesClient.reset()
    }
}

extension SudoManager {
    enum SudoManagerError: Error {
        case missingSudo
    }
}
