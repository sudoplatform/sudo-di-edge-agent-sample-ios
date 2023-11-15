//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIEdgeAgent

class ConnectionViewModel: ObservableObject {

    /// Shows when the list is loading
    @Published var isLoading: Bool = false

    /// Shows when there is an error
    @Published var showAlert: Bool = false

    /// The message to show in the alert
    @Published var alertMessage: String = ""

    /// The list of connections from the agent
    @Published var connections: [Connection] = []

    // Empty initializer
    init() {}

    /// Loads or refreshes the current connections
    func refresh() {
        Task { @MainActor in
            isLoading = true
            do {
                let result = try await Clients.agent.connections.listAll(options: nil)
                connections = result
            } catch {
                NSLog("Error getting connections \(error.localizedDescription)")
                showAlert = true
                alertMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    /// Method for swiping to delete a connection
    func delete(at offsets: IndexSet) {
        let idsToDelete = offsets.map { connections[$0].connectionId }
        _ = idsToDelete.compactMap({ id in
            Task { @MainActor [weak self] in
                do {
                    try await Clients.agent.connections.deleteById(connectionId: id)
                    self?.refresh()
                } catch {
                    self?.showAlert = true
                    self?.alertMessage = error.localizedDescription
                    NSLog("Failed to delete connection: \(error.localizedDescription)")
                }
            }
        })
    }
}

/// Conforms to Identifiable to provide some Swift magic for the `ForEach`
extension Connection: Identifiable {
    public var id: String { self.connectionId }
}

/// Convenience to get the `created_timestamp`
extension Connection {
    /// The date value retrieved from the `~created_timestamp` in the tags property
    var createdAt: Date? {
        return self.tags
            .first { $0.name == "~created_timestamp" }
            .flatMap { Double($0.value) }
            .flatMap { Date(timeIntervalSince1970: $0) }
    }
}
