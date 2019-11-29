//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class AWSMutationEventIngesterTests: XCTestCase {

    // Used by tests to assert that the MutationEvent table is being updated
    var storageAdapter: SQLiteStorageEngineAdapter!

    override func setUp() {
        Amplify.reset()

        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStoreCategoryPlugin": true
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        let apiPlugin = MockAPICategoryPlugin()

        do {
            let connection = try Connection(.inMemory)
            storageAdapter = SQLiteStorageEngineAdapter(connection: connection)

            let syncEngineFactory: CloudSyncEngineBehavior.Factory = { adapter in
                CloudSyncEngine(storageAdapter: adapter)
            }
            let storageEngine = StorageEngine(adapter: storageAdapter,
                                              syncEngineFactory: syncEngineFactory)

            let publisher = DataStorePublisher()
            let dataStorePlugin = AWSDataStoreCategoryPlugin(storageEngine: storageEngine,
                                                             dataStorePublisher: publisher)

            try Amplify.add(plugin: apiPlugin)
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I invoke DataStore.save()
    /// - Then:
    ///    - The mutation queue writes events
    func testMutationQueueWritesSaveEvents() {
        let post = Post(title: "Post title",
                        content: "Post content",
                        createdAt: Date())

        let saveCompleted = expectation(description: "Local save completed")
        Amplify.DataStore.save(post) { result in
            defer {
                saveCompleted.fulfill()
            }
            if case .failure(let dataStoreError) = result {
                XCTFail(String(describing: dataStoreError))
                return
            }
        }

        wait(for: [saveCompleted], timeout: 1.0)

        let mutationEventQueryCompleted = expectation(description: "Mutation event query completed")
        storageAdapter.query(MutationEvent.self) { result in
            defer {
                mutationEventQueryCompleted.fulfill()
            }

            let mutationEvents: [MutationEvent]
            switch result {
            case .failure(let dataStoreError):
                XCTFail(String(describing: dataStoreError))
                return
            case .success(let eventsFromResult):
                mutationEvents = eventsFromResult
            }

            XCTAssert(!mutationEvents.isEmpty)
            XCTAssert(mutationEvents.first?.json.contains(post.id) ?? false)
        }

        wait(for: [mutationEventQueryCompleted], timeout: 1.0)

    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I invoke `save()`
    ///    - The MutationIngester encounters an error
    /// - Then:
    ///    - The entire `save()` operation fails
    func testMutationQueueFailureCausesSaveFailure() {
        XCTFail("Not yet implemented")
    }
}