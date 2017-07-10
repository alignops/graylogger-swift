//
//  CachedNetworkProvider
//  graylogger
//
//  Created by Jim Boyd on 6/29/17.
//

import Foundation

public protocol CacheProvider {
	/// Return true if the cache has log items, false otherwise
	var hasCache: Bool { get }
	
	/// Cache the log item (must cache the endpoint as well as the payload)
	func cacheLog(endpoint: GraylogEndpoint, payload jsonData: Data)
	
	/// Called when the newtwork is avaliable and the cache items should be resubmitted.
	///
	/// - Parameter submitCacheItem: Call this closure with each item in the cache. This closure will attempt to resubmit the cache.
	/// The provided `completion` closure will be called with `didSubmit` == true if the item was submitted successfully, false otherwise.
	/// If `didSubmit` == true be sure to remove the log item from the cache, if false then retain the item in the cache.
	func flushCache(submitCacheItem: @escaping (_ endpoint: GraylogEndpoint, _ payload: Data, _ completion: @escaping (_ didSubmit:Bool) -> Void) -> Void)
}

/// Provides a cache mechanism for logs that fail to submit to the graylog endpoint.
/// Log requests are first sent to the `passthrough NetworkProvider`, if that request fails then the log is cached
/// through the associated `CacheProvider` object. An attempt to flush the cache (re-log the cache items) is made
/// every `cacheTimerDuration` seconds (only if the cache is not empty).
///
/// See `MemoryCacheProvider` and `CoreDataCacheProvider` included in this framework for examples of `CacheProvider` implementations
public class CachedNetworkProvider: NetworkProvider {
	
	public var cacheProvider: CacheProvider
	public var passThrough: NetworkProvider
	public var cacheTimerDuration: Int = 2 * 60 // Defaults to 2 minutes
	
	fileprivate var idleTimer: DispatchSourceTimer? = nil
	fileprivate let lockQueue = DispatchQueue(label: "Graylogger::CachedNetworkProvider")
	
	public init(cacheProvider: CacheProvider, networkProvider: NetworkProvider = URLSession.shared) {
		self.cacheProvider = cacheProvider
		self.passThrough = networkProvider
		
		let delay = DispatchTime.now() + .microseconds(100)
		DispatchQueue.main.asyncAfter(deadline: delay) {
			if self.cacheProvider.hasCache {
				self.resetIdleTimer()
			}
		}
	}
	
	deinit {
		self.stopTimer()
	}
	
	public func submitLog(endpoint: GraylogEndpoint, payload jsonData: Data, completion: ((Any?, Error?) -> Void)?) {
		passThrough.submitLog(endpoint: endpoint, payload: jsonData) {(response, error) in
			var submitErr:Error? = nil
			
			if let error = error {
				print("Log submition failed with error : \(error)")
				
				self.cacheProvider.cacheLog(endpoint: endpoint, payload: jsonData)
				self.resetIdleTimer()
				
				submitErr = GraylogSessionError.cahedLogWithError(error: error)
			}
			
			if let completion = completion {
				completion(response, submitErr)
			}
		}
	}
}


fileprivate extension CachedNetworkProvider {
	func flushCache() {
		if self.cacheProvider.hasCache && networkIsReachable() {
			self.cacheProvider.flushCache { [weak self] (endpoint, payload, completion) in
				self?.passThrough.submitLog(endpoint: endpoint, payload: payload) { (response, error) in
					completion(error == nil)
				}
			}
		}
		else {
			self.stopTimer()
		}
	}
	
	func resetIdleTimer() {
		// Only start a timer if we do not already have one
		let hasTimer:Bool = lockQueue.sync() { return idleTimer != nil }
		
		if !hasTimer {
			startTimer { [weak self] in
				self?.flushCache()
			}
		}
	}
	
	// Stop an existing timer if it exists and start (or restart) a new one
	func startTimer(eventHandler:@escaping (()->())) {
		lockQueue.sync() {
			idleTimer?.cancel()
			idleTimer = nil
			
			let queue = DispatchQueue.global(qos: .background)
			idleTimer = DispatchSource.makeTimerSource(queue: queue)
			idleTimer!.scheduleRepeating(deadline: .now() + .seconds(cacheTimerDuration), interval: .seconds(cacheTimerDuration))
			idleTimer!.setEventHandler(handler: eventHandler)
			idleTimer!.resume()
		}
	}
	
	func stopTimer() {
		lockQueue.sync() {
			idleTimer?.cancel()
			idleTimer = nil
		}
	}
}

extension CachedNetworkProvider : CustomDebugStringConvertible {
	public var debugDescription: String {
		return "\(type(of:self)) <CacheProvider:\(self.cacheProvider.self) NetworkProvider:\(self.passThrough.self)>"
	}
}
