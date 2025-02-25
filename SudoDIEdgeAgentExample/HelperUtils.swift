//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SwiftUI
import SudoDIEdgeAgent

extension View {
    @inlinable func standardButtonTheme() -> some View {
        return self.padding()
            .frame(width: 200)
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

@propertyWrapper struct UserDefaultsBacked<Value> {
    let key: String
    var storage: UserDefaults = .standard

    var wrappedValue: Value? {
        get { storage.value(forKey: key) as? Value}
        set { storage.setValue(newValue, forKey: key) }
    }
}

@propertyWrapper struct UserDefaultsBackedWithDefault<Value> {
    let key: String
    var storage: UserDefaults = .standard
    var defaultValue: Value

    var wrappedValue: Value {
        get { (storage.value(forKey: key) as? Value) ?? defaultValue }
        set { storage.setValue(newValue, forKey: key) }
    }
}

/// Allows for async code to work within a compact map function.
extension Sequence {
    func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            if let transformed = try await transform(element) {
                values.append(transformed)
            }
        }

        return values
    }
}

extension Dictionary {
    func asyncCompactMap<T>(_ transform: (Key, Value) async throws -> T?) async rethrows -> [Key: T] {
        var values = [Key: T]()
        for (k, v) in self {
            if let transformed = try await transform(k, v) {
                values[k] = transformed
            }
        }

        return values
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

class PreviewDataHelper {
    static let dummyUICredentialAnoncred = UICredential.anoncred(.init(
        id: "1",
        source: .didCommConnection(connectionId: "conn1"),
        metadata: .init(
            schema: .init(id: "schema1", authorId: "author1", name: "name", version: "1.0", attributeNames: ["foo", "bar"]),
            credentialDefinition: .init(id: "cDef1", issuerId: "issuer1", schemaId: "schema1", tag: "1.0", isRevocable: true)
        ),
        credentialAttributes: [
            .init(name: "first_name", value: "John", mimeType: nil),
            .init(name: "family_name", value: "Doe", mimeType: nil)
        ]
    ))
    
    static let dummyW3cCredential = W3cCredential(
        contexts: [],
        id: nil,
        types: ["VerifiableCredential", "Sample"],
        credentialSubject: [
            .init(
                id: "did:example:123",
                properties: [
                    "givenName": .string("John"),
                    "familyName": .string("Smith")
                ]
            ),
            .init(
                id: "did:example:321",
                properties: [
                    "givenName": .string("Peter"),
                    "familyName": .string("Griffin")
                ]
            )
        ],
        issuer: .init(id: "did:example:issuer123", properties: [:]),
        issuanceDate: "2024-02-12T15:30:45.123Z",
        expirationDate: nil,
        proof: [],
        properties: [:]
    )
    
    static let dummyUICredentialW3C = UICredential.w3c(.init(
        id: "2",
        source: .didCommConnection(connectionId: "conn2"),
        w3cVc: .init(
            contexts: [],
            id: nil,
            types: ["VerifiableCredential", "Sample"],
            credentialSubject: [
                .init(
                    id: "did:example:123",
                    properties: [
                        "givenName": .string("John"),
                        "familyName": .string("Smith")
                    ]
                ),
                .init(
                    id: "did:example:321",
                    properties: [
                        "givenName": .string("Peter"),
                        "familyName": .string("Griffin")
                    ]
                )
            ],
            issuer: .init(id: "did:example:issuer123", properties: [:]),
            issuanceDate: "2024-02-12T15:30:45.123Z",
            expirationDate: nil,
            proof: [],
            properties: [:]
        ),
        proofType: .ecdsaSecp256r1Signature2019
    ))
    
    static let dummyUICredentialSdJwtVc = UICredential.sdJwtVc(.init(
        id: "3",
        source: .openId4VcIssuer(issuerUrl: "https://issuer.foo"),
        sdJwtVc: .init(
            compactSdJwt: "foo.bar.xyz",
            verifiableCredentialType: "ResidencyCard",
            issuer: "did:foo:bar",
            validAfter: nil,
            validBefore: nil,
            issuedAt: 1731369621,
            subject: "did:foo:sub",
            keyBinding: nil,
            claims: [
                "given_name": .string(canSelectiveDisclose: true, data: "Hello"),
                "family_name": .string(canSelectiveDisclose: true, data: "World")
            ]
        )
    ))
}
