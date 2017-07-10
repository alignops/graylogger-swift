//
//  MemoryCacheProvider.swift
//  Pods
//
//  Created by Jim Boyd on 6/30/17.
//
//

import Foundation


fileprivate struct GraylogCache {
	let endpoint: GraylogEndpoint
	let payload: Data
}

public class MemoryCacheProvider: CacheProvider {
	fileprivate var logCache = [GraylogCache]()
	fileprivate let lockQueue = DispatchQueue(label: "Graylogger::MemoryCacheProvider")
	
	public init() {
		
	}
	
	public var hasCache: Bool  {
		return lockQueue.sync() {
			return !logCache.isEmpty
		}
	}
	
	public func cacheLog(endpoint: GraylogEndpoint, payload: Data) {
		lockQueue.sync() {
			self.logCache.append(GraylogCache(endpoint: endpoint, payload: payload))
		}
	}
	
	public func flushCache(submitCacheItem: @escaping (_ endpoint: GraylogEndpoint, _ payload: Data, _ completion: @escaping (_ didSubmit:Bool) -> Void) -> Void) {
		// Copy the cache to local storage ...
		var localCache:[GraylogCache] =  lockQueue.sync() {

			defer {
				// .. and delete the contents of the managed cache.
				self.logCache.removeAll();
			}
			
			return self.logCache
		}
		
		// Run through the local cache and submit again...
		for cache in localCache {
			submitCacheItem(cache.endpoint, cache.payload) { [weak self] (_ didSubmit:Bool) -> Void in
				// Put it back if it could not be submitted.
				if !didSubmit {
					self?.lockQueue.sync() {
						self?.logCache.append(cache)
					}
				}
			}
		}
	}
}
