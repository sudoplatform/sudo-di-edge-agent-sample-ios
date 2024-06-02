//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoKeyManager
import SudoUser
// import AuthenticationServices

enum AuthenticatorError: LocalizedError {
    case registerFailed
    case alreadyRegistered
    case missingTestKey
    case missingTestKeyId

    var errorDescription: String? {
        switch self {
        case .registerFailed: return "Something went wrong while trying to register, inspect the logs for details"
        case .alreadyRegistered: return "Already registered"
        case .missingTestKey: return "Missing registration TEST key. Please follow instructions in the README"
        case .missingTestKeyId: return "Missing registration TEST key ID. Please follow instructions in the README"
        }
    }
}

class Authenticator {
    let userClient: SudoUserClient
    let keyManager: SudoKeyManager

    // Keep track of the last method used to sign in.
    @UserDefaultsBackedWithDefault(key: "lastSignInMethod", defaultValue: ChallengeType.unknown.rawValue)
    private var _lastSignInMethod: String

    var lastSignInMethod: ChallengeType {
        get {
            return ChallengeType(rawValue: _lastSignInMethod) ?? .unknown
        }
        set {
            _lastSignInMethod = newValue.rawValue
        }
    }

    init(userClient: SudoUserClient, keyManager: SudoKeyManager) {
        self.userClient = userClient
        self.keyManager = keyManager
    }

    func authenticationProvider() throws -> TESTAuthenticationProvider {
        guard let testKeyPath = Bundle.main.path(forResource: "register_key", ofType: "private") else {
            throw AuthenticatorError.missingTestKey
        }

        guard let testKeyIdPath = Bundle.main.path(forResource: "register_key", ofType: "id") else {
            throw AuthenticatorError.missingTestKeyId
        }

        do {
            let testKey = try String(contentsOfFile: testKeyPath)
            let testKeyId = try String(contentsOfFile: testKeyIdPath).trimmingCharacters(in: .whitespacesAndNewlines)
            return try TESTAuthenticationProvider(
                name: "testRegisterAudience",
                key: testKey,
                keyId: testKeyId,
                keyManager: keyManager
            )
        } catch {
            fatalError("Authentication error: \(error)")
        }
    }

    func register() async throws {
        do {
            if try await userClient.isRegistered() { throw AuthenticatorError.alreadyRegistered }
            let provider = try authenticationProvider()
            _ = try await userClient.registerWithAuthenticationProvider(
                authenticationProvider: provider,
                registrationId: UUID().uuidString
            )
        } catch {
            NSLog("Pre-registration Failure: \(error)")
        }
    }

    func registerAndSignIn() async throws {
        let userClient: SudoUserClient = Clients.userClient

        func signIn() async throws {
            if try await !userClient.isSignedIn() {
                _ = try await userClient.signInWithKey()
                lastSignInMethod = .test
            }
        }

        if try await !userClient.isRegistered() {
            try await register()
        }

        try await signIn()
    }

    func deregister() async throws -> String {
        let deregisteredUserId = try await userClient.deregister()
        lastSignInMethod = .unknown
        return deregisteredUserId
    }
}
