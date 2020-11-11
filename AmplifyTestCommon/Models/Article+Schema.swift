//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// swiftlint:disable all
import Amplify
import Foundation

extension Article {
    // MARK: - CodingKeys
    public enum CodingKeys: String, ModelKey {
        case id
        case content
        case createdAt
        case owner
        case authorNotes

        public var modelType: Model.Type {
            return Article.self
        }
    }

    public static let keys = CodingKeys.self
    //  MARK: - ModelSchema

    public static let schema = defineSchema { model in
        let article = Article.keys

        model.pluralName = "Articles"

        model.authRules = [
            rule(allow: .owner, ownerField: "owner", operations: [.create, .read]),
            rule(allow: .groups, groups: ["Admin"]),
        ]

        model.fields(
            .id(),
            .field(article.content, is: .required, ofType: .string),
            .field(article.createdAt, is: .required, ofType: .dateTime),
            .field(article.owner, is: .optional, ofType: .string),
            .field(article.authorNotes,
                   is: .optional,
                   ofType: .string,
                   authRules: [rule(allow: .owner, ownerField: "owner", operations: [.update])]
            )
        )
    }
}
