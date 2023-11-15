//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            List {
                Button(action: viewModel.changeAgentState) {
                    viewModel.serverState == .stopped
                    ? Text("Run Agent")
                    : Text("Stop Agent")
                }

                NavigationLink("Connection Exchanges") {
                    ConnectionExchangeView()
                }

                NavigationLink("Connection") {
                    ConnectionView()
                }

                NavigationLink("Credential Exchanges") {
                    CredentialExchangeListView()
                }

                NavigationLink("Credentials") {
                    CredentialListView()
                }

                NavigationLink("Proof Exchanges") {
                    ProofExchangeListView()
                }
            }
            .navigationTitle("Home")
        }
        .navigationBarBackButtonHidden(true)
        .task { viewModel.prepare() }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
