//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import SudoDIEdgeAgent

// Since this view doesn't interact with the agent, there is no accompanying view model.
struct CredentialView: View {
    var credential: UICredential

    var body: some View {
        NavigationView {
            switch credential {
            case .anoncred(let credential):
                AnoncredCredentialInfoColumn(credential: credential)
            case .w3c(let credential):
                W3cCredentialInfoColumn(credential: credential)
            case .sdJwtVc(let credential):
                SdJwtCredentialInfoColumn(credential: credential)
            }
        }
    }
}

struct CredentialView_Previews: PreviewProvider {
    static var previews: some View {
        CredentialView(
            credential: PreviewDataHelper.dummyUICredentialAnoncred
        )
    }
}
