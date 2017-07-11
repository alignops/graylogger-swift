import UIKit
import XCTest
import SwiftyJSON
import DBC
import CoreData

@testable import graylogger


class CoreDataCacheProviderTests: XCTestCase {
	var networkCacheProvider:CachedNetworkProvider! = nil
	let endpoiunt = GraylogEndpoint(logType: .http, host: "192.168.0.1", port: 1111, loglevel: .alert)
	
    override func setUp() {
        super.setUp()
		
		let cacheProvider = CoreDataCacheProvider(in:Bundle(identifier: "org.cocoapods.graylogger")!)
		cacheProvider.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: cacheProvider.managedObjectModel)
			
		do {
			try cacheProvider.persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
		} catch {
			print("Adding in-memory persistent store failed")
		}
		
		networkCacheProvider = CachedNetworkProvider(cacheProvider: cacheProvider, networkProvider: FailingNetworkProvider())
		networkCacheProvider.cacheTimerDuration = 1000
	}
    
    override func tearDown() {
        networkCacheProvider = nil
        super.tearDown()
    }
    
	func testBundlePath() {
		let bundleMain = Bundle.main
		let bundleDoingTest = Bundle(for: type(of: self ))
		let bundleBeingTested = Bundle(identifier: "org.cocoapods.graylogger")!
		
		print("bundleMain.bundlePath : \(bundleMain.bundlePath)")
		// …/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Xcode/Agents
		print("bundleDoingTest.bundlePath : \(bundleDoingTest.bundlePath)")
		// …/PATH/TO/Debug/ExampleTests.xctest
		print("bundleBeingTested.bundlePath : \(bundleBeingTested.bundlePath)")
		// …/PATH/TO/Debug/Example.app
		
		print("bundleMain = " + bundleMain.description) // Xcode Test Agent
		print("bundleDoingTest = " + bundleDoingTest.description) // Test Case Bundle
		print("bundleBeingTested = " + bundleBeingTested.description) // Framework Bundle
	}
	
    func testCacheing() {
		let testData = ["1":1, "2":2, "3":3]
		let json = try? JSON(testData).rawData()
		XCTAssert(json != nil)

		XCTAssertFalse(networkCacheProvider.cacheProvider.hasCache)

		networkCacheProvider.submitLog(endpoint: endpoiunt, payload: json!) { (response, error) in
			XCTAssert(error != nil)

			// Should be a GraylogSessionError.cahedLogWithError
			switch error! {
			case GraylogSessionError.cahedLogWithError(_):
				break
			default:
				XCTFail()
			}
		}
		
		XCTAssertTrue(networkCacheProvider.cacheProvider.hasCache)
    }
	
	func testForcedFlushing() {
		let expect = expectation(description: "testForcedFlushing")

		// Fill the cache with something
		testCacheing()
		
		// Force a cache flush and signal a successful submition
		networkCacheProvider.cacheProvider.flushCache { (endpoint, payload, completion) in
			completion(true)
		}

		let deadlineTime = DispatchTime.now() + .seconds(2)
		DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
			// Cache should be empty
			XCTAssertFalse(self.networkCacheProvider.cacheProvider.hasCache)
			
			expect.fulfill()
		}
		
		waitForExpectations(timeout: 3) { error in
			if let error = error {
				XCTFail("waitForExpectationsWithTimeout errored: \(error)")
			}
		}

	}
	
	func testForcedFlushingFail() {
		// Fill the cache with something
		testCacheing()
		
		// Force a cache flush and signal a error in submition
		networkCacheProvider.cacheProvider.flushCache { (endpoint, payload, completion) in
			completion(false)
		}
		
		// Cache should still have the item in it
		XCTAssertTrue(networkCacheProvider.cacheProvider.hasCache)
	}
	
	func testTimerFlushing() {
		let expect = expectation(description: "testTimerFlushing")

		networkCacheProvider = CachedNetworkProvider(cacheProvider: MemoryCacheProvider(), networkProvider: FailThanPassNetworkProvider())
		networkCacheProvider.cacheTimerDuration = 2

		// Fill the cache with something
		testCacheing()
		
		let deadlineTime = DispatchTime.now() + .seconds(3)
		DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
			// Cache should be empty
			XCTAssertFalse(self.networkCacheProvider.cacheProvider.hasCache)

			expect.fulfill()
		}
		
		waitForExpectations(timeout: 4) { error in
			if let error = error {
				XCTFail("waitForExpectationsWithTimeout errored: \(error)")
			}
		}

	}

	
	func testTimerFlushingFail() {
		let expect = expectation(description: "testTimerFlushingFail")
		
		networkCacheProvider = CachedNetworkProvider(cacheProvider: MemoryCacheProvider(), networkProvider: FailingNetworkProvider())
		networkCacheProvider.cacheTimerDuration = 2
		
		// Fill the cache with something
		testCacheing()
		
		let deadlineTime = DispatchTime.now() + .seconds(3)
		DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
			// Cache should be empty
			XCTAssertTrue(self.networkCacheProvider.cacheProvider.hasCache)
			
			expect.fulfill()
		}
		
		waitForExpectations(timeout: 4) { error in
			if let error = error {
				XCTFail("waitForExpectationsWithTimeout errored: \(error)")
			}
		}
		
	}


}
