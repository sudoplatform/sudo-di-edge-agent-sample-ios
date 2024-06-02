//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
// 

import Foundation
import SudoDIEdgeAgent
import SwiftUI
import CoreImage.CIFilterBuiltins

struct ConnectionInvitationCreateView: View {
    // SwiftUI doesn't make it easy to dismiss/pop views so one way is to use the `@Environment(.\dismiss).
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: ConnectionInvitationCreateViewModel
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }

    var body: some View {
        NavigationView {
            VStack {
                if !viewModel.isLoading, let invitation = viewModel.createdInvitationUrl {
                    Image(uiImage: generateQRCode(from: invitation))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .padding()
                    Text("Scan with another wallet")
                } else {
                    ProgressView()
                }
            }
        }
        .task {
            viewModel.initialize()
        }
        .onDisappear(perform: viewModel.teardown)
        .alert("Error Occurred", isPresented: $viewModel.showAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("Success!", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        }
        .sheet(
            item: $viewModel.incomingRequest,
            onDismiss: { dismiss()},
            content: { exchange in
                VStack {
                    Spacer()
                    Text("Incoming Request")
                        .font(.largeTitle)
                    Text("From: \(exchange.theirLabel ?? "")")
                        .font(.title)
                    Spacer()
                    HStack {
                        if !viewModel.isLoading {
                            Button("Accept") {
                                viewModel.accept()
                            }
                                .padding()
                                .padding(.leading)
                                .padding(.trailing)
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                            Button("Decline") {
                                viewModel.decline()
                            }
                                .padding()
                                .padding(.leading)
                                .padding(.trailing)
                                .background(.red)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                                .disabled(viewModel.isLoading)
                        } else {
                            ProgressView()
                        }
                    }
                }
            }
        )
    }
}

struct ConnectionInvitationCreateView1_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionInvitationCreateView(viewModel: ConnectionInvitationCreateViewModel(
            createdInvitationUrl: "test.com?c_i"
        ))
    }
}

struct ConnectionInvitationCreateView2_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionInvitationCreateView(viewModel: ConnectionInvitationCreateViewModel(
            createdInvitationUrl: nil
        ))
    }
}

struct ConnectionInvitationCreateView3_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionInvitationCreateView(viewModel: ConnectionInvitationCreateViewModel(
            isLoading: true,
            createdInvitationUrl: "test.com?c_i",
            incomingRequest: ConnectionExchange(
                connectionExchangeId: "connEx1",
                connectionId: nil,
                role: .inviter,
                state: .request,
                theirLabel: "Bob",
                verkey: "",
                errorMessage: nil,
                tags: []
            )
        ))
    }
}
