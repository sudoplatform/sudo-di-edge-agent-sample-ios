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
    @Published var credentials: [Credential] = []

    /// The `Credential` that is presented in the sheet
    @Published var presentedCredential: Credential?

    // Empty initializer
    init() {}

    /// Lists all of the credentials
    func refresh() {
        Task { @MainActor in
            isLoading = true
            do {
                let result = try await Clients.agent.credentials.listAll(options: nil)
                credentials = result
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
        let idsToDelete = offsets.map { credentials[$0].credentialId }
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
    func showInfo(_ credential: Credential) {
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

extension CredentialFormatData {
    var previewName: String {
        switch self {
        case .w3c(let w3cCred):
            return w3cCred.types.first { $0 != "VerifiableCredential" } ?? "VerifiableCredential"
        case .anoncredV1(let metadata, _):
            return metadata.credentialDefinitionInfo?.name ?? metadata.credentialDefinitionId
        }
    }
    
    var formatPreviewName: String {
        switch self {
        case .anoncredV1:
            return "Anoncred"
        case .w3c:
            return "W3C"
        }
    }
}
