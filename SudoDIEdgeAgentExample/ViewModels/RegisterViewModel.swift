//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import SudoDIEdgeAgent
import SudoProfiles

class RegisterViewModel: ObservableObject {

    /// True if the loading indicator is visible.
    @Published var isLoading = false

    /// Published bool for presenting a register error.
    @Published var presentError = false

    /// Published register error message.
    @Published var errorMessage: String = ""

    /// True if the home screen should be shown.
    @Published var showHome: Bool = false

    /// Shows a progess view while resetting.
    @Published var isResetting: Bool = false

    /// Shows a warning before resetting the clients.
    @Published var resetWarning: Bool = false 

    /// Shows when the app has successfully been reset.
    @Published var isSuccessfulReset: Bool = false

    init() {}

    /// Method for following standard Sudo initialization and registration
    func register() {
        Task { @MainActor in
            isLoading = true
            do {
                NSLog("Registering client...")
                try await Clients.authenticator.registerAndSignIn()

                NSLog("Redeeming Entitlements...")
                _ = try await Clients.entitlementsClient.redeemEntitlements()

                let sudo = try await Clients.sudoManager.getSudo()
                if sudo == nil {
                    NSLog("Creating Sudo...")
                    try await Clients.sudoManager.createSudo()
                }

                // Open a wallet if it exists or create a new wallet after registering
                if try await Clients.agent.wallet.exists(walletId: Clients.walletConfig.id) {
                    NSLog("Opening Wallet...")
                    try await Clients.agent.wallet.open(walletConfiguration: Clients.walletConfig)
                } else {
                    NSLog("Creating Wallet...")
                    try await Clients.agent.wallet.create(walletConfiguration: Clients.walletConfig)
                    try await Clients.agent.wallet.open(walletConfiguration: Clients.walletConfig)
                }
                NSLog("Success! Redirecting to Home...")
                showHome = true
            } catch {
                NSLog("Unable to sign in: \(error)")
                presentError = true
                errorMessage = "Unable to sign in: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    /// Shows the reset warning alert
    func showResetWarning() {
        resetWarning = true
    }

    /// Closes and deletes the wallet then resets all of the clients
    func reset() {
        Task { @MainActor in
            isResetting = true
            do {
                NSLog("Stopping all agent processes...")
                Clients.agent.stop()
                Clients.agent.unsubscribeAll()

                NSLog("Closing and deleting wallets...")
                do {
                    // wrapping to ignore error if wallet is already closed
                    try await Clients.agent.wallet.close()
                } catch {
                    NSLog("Wallet is already closed \(error.localizedDescription)")
                }
                do {
                    // wrapping to continue the reset if wallet has issues
                    try await Clients.agent.wallet.delete(walletConfiguration: Clients.walletConfig)
                } catch {
                    NSLog("Error deleting the wallet: \(error.localizedDescription)")
                }
                // reset the clients in the proper order
                NSLog("Resetting clients...")
                try await Clients.reset()
                isSuccessfulReset = true
            } catch {
                NSLog("Error occurred trying to reset the app \(error.localizedDescription)")
                presentError = true
                errorMessage = error.localizedDescription
            }
            isResetting = false
        }
    }
}
