//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIEdgeAgent

/// The `Credential` list is where connections can be viewed.
/// This class contains interactions with the `agent.credentials` module in the Edge SDK.
class CredentialListViewModel: ObservableObject {

    /// Shows when the list is loading
    @Published var isLoading: Bool = false

    /// Shows when there is an error
    @Published var showAlert: Bool = false

    /// The message to show in the alert
    @Published var alertMessage: String = ""

    /// The list of credentials from the agent
    @Published var credentials: [UICredential] = []

    /// The `Credential` that is presented in the sheet
    @Published var presentedCredential: UICredential?

    // Empty initializer
    init() {}

    /// Lists all of the credentials
    func refresh() {
        Task { @MainActor in
            isLoading = true
            do {
                let result = try await Clients.agent.credentials.listAll(options: nil)
                credentials = try await result
                    .sorted { $0.createdAt ?? .now > $1.createdAt ?? .now }
                    .asyncCompactMap {
                        try await UICredential.fromCredential(agent: Clients.agent, credential: $0)
                    }
            } catch {
                NSLog("Error getting credentials \(error.localizedDescription)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    /// Method for swiping to delete a credential
    func delete(at offsets: IndexSet) {
        let idsToDelete = offsets.map { credentials[$0].id }
        _ = idsToDelete.compactMap({ id in
            Task { @MainActor [weak self] in
                do {
                    try await Clients.agent.credentials.deleteById(credentialId: id)
                    self?.refresh()
                } catch {
                    self?.showAlert = true
                    self?.alertMessage = error.localizedDescription
                    NSLog("Failed to delete credential: \(error.localizedDescription)")
                }
            }
        })
    }

    /// Shows the info of a given credential in a sheet
    func showInfo(_ credential: UICredential) {
        presentedCredential = credential
    }

    /// Dismisses the sheet view of the credential
    func dismissInfo() {
        presentedCredential = nil
    }
}

/// Conforms to Identifiable to provide some Swift magic for the `ForEach`
extension Credential: Identifiable {
    public var id: String { self.credentialId }
}

/// Convenience to get the `created_timestamp`
extension Credential {
    /// The date value retrieved from the `~created_timestamp` in the tags property
    var createdAt: Date? {
        return self.tags
            .first { $0.name == "~created_timestamp" }
            .flatMap { Double($0.value) }
            .flatMap { Date(timeIntervalSince1970: $0) }
    }
}
