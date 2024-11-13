//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

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

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
