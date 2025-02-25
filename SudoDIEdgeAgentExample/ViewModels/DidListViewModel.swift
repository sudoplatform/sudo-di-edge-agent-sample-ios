//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIEdgeAgent

class DidListViewModel: ObservableObject {

    /// Shows when the list is loading
    @Published var isLoading: Bool

    /// Shows when there is an error
    @Published var showAlert: Bool

    /// The message to show in the alert
    @Published var alertMessage: String

    /// The list of DIDs from the agent
    @Published var dids: [DidInformation]

    // Empty initializer
    init(
        isLoading: Bool = false,
        showAlert: Bool = false,
        alertMessage: String = "",
        dids: [DidInformation] = []
    ) {
        self.isLoading = isLoading
        self.showAlert = showAlert
        self.alertMessage = alertMessage
        self.dids = dids
    }

    /// Loads or refreshes the current DIDs
    func refresh() {
        Task { @MainActor in
            isLoading = true
            do {
                let result = try await Clients.agent.dids.listAll(options: nil)
                dids = result.sorted { $0.createdAt ?? .now > $1.createdAt ?? .now }
            } catch {
                NSLog("Error getting DIDs \(error.localizedDescription)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    /// Method for swiping to delete a DID
    func delete(at offsets: IndexSet) {
        let idsToDelete = offsets.map { dids[$0].did }
        _ = idsToDelete.compactMap({ id in
            Task { @MainActor in
                do {
                    try await Clients.agent.dids.deleteById(did: id)
                    self.refresh()
                } catch {
                    self.showAlert = true
                    self.alertMessage = error.localizedDescription
                    NSLog("Failed to delete DID: \(error.localizedDescription)")
                }
            }
        })
    }
    
    /// Create a new DID, use custom logic to assign an `alias` to the `DidInformation` metadata.
    ///
    /// Refreshing the displayed DID list if successful.
    func createDid(options: CreateDidOptions, alias: String) {
        Task { @MainActor in
            isLoading = true
            do {
                let did = try await Clients.agent.dids.createDid(options: options)
                try await assignAliasToDid(agent: Clients.agent, did: did, alias: alias)
                self.refresh()
            } catch {
                NSLog("Error getting DIDs \(error.localizedDescription)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    /// Custom application logic to apply a user-defined human readable "alias" to a DID.
    /// Assignment is done using the Edge Agent's record tagging ability. The given `did`
    /// is updated using the `agent` to have an alias record tag with the given `alias`.
    ///
    /// Then on subsequent interactions with `DidInformation`, the `alias` can be 
    /// recovered via the tags.
    private func assignAliasToDid(
        agent: SudoDIEdgeAgent,
        did: DidInformation,
        alias: String
    ) async throws {
        var newTags = did.tags
        newTags.append(.init(name: didAliasTagName, value: alias))
        _ = try await agent.dids.updateDid(did: did.did, didUpdate: .init(tags: newTags))
    }
}

/// Constant for the Record tag name assigned to DIDs to represent their "alias"
private let didAliasTagName = "alias"

extension DidInformation: Identifiable {
    public var id: String { self.did }
}

/// Convenience extensions
extension DidInformation {
    /// The date value retrieved from the `~created_timestamp` in the tags property
    var createdAt: Date? {
        return self.tags
            .first { $0.name == "~created_timestamp" }
            .flatMap { Double($0.value) }
            .flatMap { Date(timeIntervalSince1970: $0) }
    }
    
    /// Get the human readable DID method.
    var method: String {
        switch methodData {
        case .didKey:
            return "did:key"
        case .didJwk:
            return "did:jwk"
        }
    }
    
    /// Get the key type of the key which backs this DID.
    var keyType: DidKeyType {
        switch methodData {
        case .didKey(keyType: let keyType):
            return keyType
        case .didJwk(keyType: let keyType):
            return keyType
        }
    }
    
    /// Get the assigned "alias" from the DID, if any.
    var alias: String? {
        return tags.first { $0.name == didAliasTagName }?.value
    }
}

/// UI State for the flow stepped thru whilst selecting options for creating a DID.
enum CreateDidDialogState {
    case selectMethod
    case selectKeyType(method: DidMethod)
    case selectEnclaveType(method: DidMethod, keyType: DidKeyType)
    case enterAlias(
        method: DidMethod,
        keyType: DidKeyType,
        enclaveType: CreateKeyPairEnclaveOptions
    )
}
