//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoDIEdgeAgent
import SudoDIRelay
import SudoEntitlements
import SudoKeyManager
import SudoLogging
import SudoProfiles
import SudoUser
import Foundation

class Clients {
    static private(set) var agent: SudoDIEdgeAgent!
    static private(set) var agentConfiguration: AgentConfiguration!
    static private(set) var authenticator: Authenticator!
    static private(set) var entitlementsClient: SudoEntitlementsClient!
    static private(set) var keyManager: SudoKeyManager!
    static private(set) var profilesClient: SudoProfilesClient!
    static private(set) var sudoManager: SudoManager!
    static private(set) var relayClient: SudoDIRelayClient!
    static private(set) var relayManager: RelayManager!
    static private(set) var userClient: SudoUserClient!
    static private(set) var logger: Logger!

    static private(set) var messageSource: UrlMessageSource!
    static private(set) var relaySource: SudoDIRelayMessageSource!
    static private(set) var mutliMessageSource: RoundRobinMultiMessageSource!

    static var pendingDeepLinks: [URL] = []

    /// NOTE: These are demo purposes only
    private static let walletId: String = "wallet"

    /// NOTE: These are demo purposes only
    private static let passphrase: String = "EXAMPLE_PURPOSE_ONLY_DO_NOT_HARDCODE"

    /// NOTE: These are demo purposes only
    static let walletConfig: WalletConfiguration = .init(id: walletId, passphrase: passphrase)

    static func configure() throws {
        self.userClient = try DefaultSudoUserClient(keyNamespace: "diExample")
        self.keyManager = DefaultSudoKeyManager(serviceName: "com.sudoplatform.diedgeagent.example", keyTag: "com.sudoplatform", namespace: "client")
        self.authenticator = Authenticator(userClient: self.userClient, keyManager: self.keyManager)
        self.entitlementsClient = try DefaultSudoEntitlementsClient(userClient: self.userClient)

        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.profilesClient = try DefaultSudoProfilesClient(sudoUserClient: self.userClient, blobContainerURL: documentsDir)
        self.sudoManager = SudoManager(profilesClient: self.profilesClient)

        self.relayClient = try DefaultSudoDIRelayClient(sudoUserClient: self.userClient)
        self.relayManager = RelayManager(relayClient: self.relayClient, sudoManager: self.sudoManager)


        let driver: LogDriverProtocol = NSLogDriver(level: .debug)
        self.logger = Logger(identifier: "di-edge-example", driver: driver)

        guard let sovGenesisFile = Bundle.main.url(
            forResource: "genesis_ledger.json",
            withExtension: nil
        ) else {
            fatalError("Failed to get genesis file")
        }

        self.messageSource = UrlMessageSource(logger: Clients.logger)
        self.relaySource = SudoDIRelayMessageSource(relayClient: Clients.relayClient, logger: Clients.logger)

        self.mutliMessageSource = RoundRobinMultiMessageSource(logger: Clients.logger)
        mutliMessageSource.addMessageSource(messageSource: relaySource)
        mutliMessageSource.addMessageSource(messageSource: messageSource)

        self.agentConfiguration = AgentConfiguration(
            networkConfiguration: .init(
                sovConfiguration: .init(
                    genesisFiles: [sovGenesisFile],
                    namespace: "indicio:testnet"
                ),
                cheqdConfiguration: NetworkConfiguration.Cheqd()
            ),
            peerConnectionConfiguration: PeerConnectionConfiguration(label: "Sudo DI Agent iOS")
        )
        self.agent = try SudoDIEdgeAgentBuilder()
            .setAgentConfiguration(agentConfiguration: self.agentConfiguration)
            .setLogger(logger: logger)
            .registerExternalCryptoProvider(provider: IOSHardwareCryptoProvider())
            .build()
    }

    static func changeAgentConfiguration(configuration: AgentConfiguration) throws {
        self.agentConfiguration = configuration
        try self.agent.setAgentConfiguration(agentConfiguration: self.agentConfiguration)
    }

    /// Deregisters the authenticator which registers the user to the sudo user client
    static func deregisterClients() async throws {
        do {
            _ = try await authenticator.deregister()
        } catch {
            NSLog("Failed to deregister: \(error)")
        }
    }

    /// Resets the clients in the proper order
    static func reset() async throws {
        // Deregisters the sudo user from the client
        try await self.deregisterClients()
        // Resets the profiles client and unassigns the sudo
        try self.sudoManager.reset()
        // The user client is the last one to be reset as the other clients depend on it
        try await self.userClient.reset()
    }
}
