//
//  CoreDataCacheProvider.swift
//  graylogger
//
//  Created by Jim Boyd on 7/3/17.
//

import Foundation
import CoreData
import DBC
import SwiftyJSON

public class CoreDataCacheProvider: NSObject, CacheProvider {
	private lazy var cacheDirectory: URL = {
		return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!.appendingPathComponent(Bundle.main.bundleId)
	}()
	
	private lazy var managedObjectModel: NSManagedObjectModel = {
		var bundle = Bundle(for: type(of: self))
		return NSManagedObjectModel.mergedModel(from: [bundle])!
	}()
	
	private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		let psc =  NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		
		var storeURL: URL? = self.cacheDirectory.appendingPathComponent("CoreDataCacheProvider.sqlite")
		do {
			_ = try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
		}
		catch {
			requireFailure("[CoreDataCacheProvider] Error \(error)")
		}
		
		return psc
	}()
	
	fileprivate lazy var managedObjectContext: NSManagedObjectContext = {
		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		moc.persistentStoreCoordinator = self.persistentStoreCoordinator
		
		return moc
	}()
	
	public var hasCache: Bool {
		return self.count() > 0
	}
	
	public func cacheLog(endpoint: GraylogEndpoint, payload jsonData: Data) {
		self.managedObjectContext.perform {
			let cachedObject:CachedLog = NSEntityDescription.insertNewObject(forEntityName: "CachedLog", into: self.managedObjectContext) as! CachedLog
			
			cachedObject.type = endpoint.logType.rawValue
			cachedObject.host = endpoint.host
			cachedObject.port = endpoint.port as NSNumber
			cachedObject.level = NSNumber(value: endpoint.maxLogLevel.rawValue)
			cachedObject.payload = jsonData as NSData
			
			do {
				try self.managedObjectContext.save()
			}
			catch {
				requireFailure("Could not create/save log cache : /(error)")
			}
		}
	}
	
	public func flushCache(submitCacheItem: @escaping (GraylogEndpoint, Data, @escaping (Bool) -> Void) -> Void) {
		
		self.managedObjectContext.perform {
			let fetchRequest:NSFetchRequest<CachedLog> = CachedLog.fetchRequest()
			var cacheItems = [CachedLog]()
			
			fetchRequest.entity = NSEntityDescription.entity(forEntityName: "CachedLog", in: self.managedObjectContext)
			fetchRequest.includesPropertyValues = true
			
			do {
				cacheItems = try self.managedObjectContext.fetch(fetchRequest)
			}
			catch {
				print("[CABOGeocoderCache] Error occured getting all objects in core data store. \(error)")
			}
			
			for cache in cacheItems {
				guard let type = cache.type,
					let logType = GraylogType(rawValue: type),
					let host = cache.host,
					let port = cache.port,
					let level = cache.level,
					let logLevel =  GraylogLevel(rawValue: level.intValue),
					let payload = cache.payload as Data? else {
						requireFailure("Could not load log values for cached object")
						return
					}
				
				let endpoint = GraylogEndpoint(logType: logType, host: host, port: port.intValue, loglevel: logLevel)
				
				submitCacheItem(endpoint, payload) { (_ didSubmit:Bool) -> Void in
					// Remove the item if it was submitted.
					if didSubmit {
						self.managedObjectContext.perform {
							self.managedObjectContext.delete(cache)
							
							do {
								try self.managedObjectContext.save()
							}
							catch {
								requireFailure("Could not delete log cache : /(error)")
							}
							
						}
					}
				}
			}
		}
		
	}
}

fileprivate extension CoreDataCacheProvider {
	func count() -> Int {
		var result = 0
		
		self.managedObjectContext.performAndWait {
			let fetchRequest:NSFetchRequest<CachedLog> = CachedLog.fetchRequest()
			
			fetchRequest.entity = NSEntityDescription.entity(forEntityName: "CachedLog", in: self.managedObjectContext)
			fetchRequest.includesPropertyValues = false
			
			do {
				result = try self.managedObjectContext.count(for: fetchRequest)
			}
			catch {
				print("[CABOGeocoderCache] Error occured getting all objects in core data store. \(error)")
			}
		}
		
		return result
	}
}
