import UIKit
import XCTest
import SwiftyJSON
import DBC
@testable import graylogger


class FailingNetworkProvider: NetworkProvider {
	func submitLog(endpoint: GraylogEndpoint, payload jsonData: Data, completion: ((Any?, Error?) -> Void)?) {
		completion?(nil, GraylogSessionError.reachabilityError)
	}
}

class FailThanPassNetworkProvider: NetworkProvider {
	var toggled = false
	
	func submitLog(endpoint: GraylogEndpoint, payload jsonData: Data, completion: ((Any?, Error?) -> Void)?) {
		completion?(nil, toggled ? nil : GraylogSessionError.reachabilityError)
		toggled = true
	}
}

class CachedNetworkProviderTests: XCTestCase {
	var networkCacheProvider:CachedNetworkProvider! = nil
	let endpoint = GraylogEndpoint(logType: .http, host: "192.168.0.1", port: 1111)
	
    override func setUp() {
        super.setUp()
		networkCacheProvider = CachedNetworkProvider(cacheProvider: MemoryCacheProvider(), networkProvider: FailingNetworkProvider())
		networkCacheProvider.cacheTimerDuration = 1000
	}
    
    override func tearDown() {
        networkCacheProvider = nil
        super.tearDown()
    }
    
	func testCacheing() {
		let testData = ["1":1, "2":2, "3":3]
		let json = try? JSON(testData).rawData()
		XCTAssert(json != nil)

		XCTAssertFalse(networkCacheProvider.cacheProvider.hasCache)

		networkCacheProvider.submitLog(endpoint: endpoint, payload: json!) { (response, error) in
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
		// Fill the cache with something
		testCacheing()
		
		// Force a cache flush and signal a successful submition
		networkCacheProvider.cacheProvider.flushCache { (endpoint, payload, completion) in
			completion(true)
		}

		// Cache should be empty
		XCTAssertFalse(networkCacheProvider.cacheProvider.hasCache)

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
		let expect = expectation(description: "testTimerFlushing")
		
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
