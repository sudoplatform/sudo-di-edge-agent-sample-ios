//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct RegisterView: View {
    @State private var navPath = NavigationPath()
    @StateObject var viewModel: RegisterViewModel

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                if viewModel.isResetting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(3, anchor: .center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.gray)
                }

                VStack {
                    Spacer()
                    Image("sudoplatform")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Text("Sudo Edge Agent")
                        .font(.largeTitle)
                    Text("Example App")
                        .font(.title)
                    Spacer()

                    Button(action: viewModel.register) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Unlock")
                        }
                    }
                        .padding()
                        .frame(width: 200)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .disabled(viewModel.isLoading || viewModel.isResetting)
                }
                .padding()
            }
            .alert("An Error Occurred", isPresented: $viewModel.presentError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Reset Clients", isPresented: $viewModel.resetWarning) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) { viewModel.reset() }
            } message: {
                Text("Resetting the app will cause all data to be deleted and cannot be reversed.")
            }
            .alert("Success", isPresented: $viewModel.isSuccessfulReset) {
                Button("OK") {}
            } message: {
                Text("The app has successfully been reset.")
            }
            .navigationDestination(isPresented: $viewModel.showHome) {
                HomeView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset", action: viewModel.showResetWarning)
                        .disabled(viewModel.isLoading || viewModel.isResetting)
                }
            }
        }

    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(viewModel: RegisterViewModel())
    }
}
