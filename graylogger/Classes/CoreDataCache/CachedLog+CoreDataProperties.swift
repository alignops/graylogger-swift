//
//  CachedLog+CoreDataProperties.swift
//  graylogger
//
//  Created by Jim Boyd on 7/3/17.
//
//

import Foundation
import CoreData


extension CachedLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedLog> {
        return NSFetchRequest<CachedLog>(entityName: "CachedLog")
    }

	@NSManaged public var type: String?
	@NSManaged public var host: String?
    @NSManaged public var payload: NSData?
    @NSManaged public var port: NSNumber?
    @NSManaged public var level: NSNumber?

}
