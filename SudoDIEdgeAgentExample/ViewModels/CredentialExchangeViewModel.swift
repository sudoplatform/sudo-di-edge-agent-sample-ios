//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIEdgeAgent
import SwiftUI

class CredentialExchangeViewModel: ObservableObject {

    /// The shown credential for the view
    @Published var credential: CredentialExchange

    init(credential: CredentialExchange) {
        self.credential = credential
    }
}

/// Conforms `AnoncredV1CredentialAttribute` to `Hashable` by combining all attributes together to
/// create a unique value. This is done here because the extension is outside of the Edge SDK where this is declared.
extension AnoncredV1CredentialAttribute: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(value)
        hasher.combine(mimeType)
    }
}
