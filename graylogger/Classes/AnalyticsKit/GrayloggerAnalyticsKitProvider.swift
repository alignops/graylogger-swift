//
//  GraylogAnalyticsKitProvider.swift
//  graylogger
//
//  Created by Jim Boyd on 6/29/17.
//

import Foundation
import AnalyticsKit
import DBC

public class GraylogAnalyticsKitProvider: NSObject, AnalyticsKitProvider {
	
	let glInput: GraylogInput
	
	public init(input: GraylogInput) {
		self.glInput = input
		super.init()
	}
	
	public func applicationWillEnterForeground() {}
	public func applicationDidEnterBackground() {}
	public func applicationWillTerminate() {}

	// MARK: - Log Screens
	public func logScreen(_ screenName: String) {
		logEvent("Screen - \(screenName)")
	}

	public func logScreen(_ screenName: String, withProperties dict: [String : Any]) {
		logEvent("Screen - \(screenName)", withProperties: dict)
	}

	// MARK: - Log Events
	public func logEvent(_ event: String) {
		log(level:.informational, message:event)
	}

	public func logEvent(_ event: String, withProperties dict: [String : Any]) {
		log(level:.informational, message:event, additionalData:dict)
	}

	public func logEvent(_ event: String, withProperty key: String, andValue value: String) {
		logEvent(event, withProperties: [key: value])
	}

	public func logEvent(_ event: String, timed: Bool) {
		if timed {
			AnalyticsKitTimedEventHelper.startTimedEventWithName(event, forProvider: self)
		}

		logEvent(event)
	}

	public func logEvent(_ event: String, withProperties dict: [String : Any], timed: Bool) {
		if timed {
			AnalyticsKitTimedEventHelper.startTimedEventWithName(event, properties: dict, forProvider: self)
		}

		logEvent(event, withProperties: dict)
	}

	public func endTimedEvent(_ event: String, withProperties dict: [String : Any]) {
		if let timedEvent = AnalyticsKitTimedEventHelper.endTimedEventNamed(event, forProvider: self) {
			logEvent(timedEvent.name, withProperties: timedEvent.properties)
		}
	}

	// MARK: - Log Errors
	public func logError(_ name: String, message: String?, properties: [String : Any]?, exception: NSException?) {
		
		var additionalData = [String: Any]()
		
		if let properties = properties {
			additionalData["properties"] = properties
		}
		
		if let exception = exception {
			additionalData["name"] = exception.name.rawValue
			additionalData["trace"] = exception.callStackSymbols
			
			if let reason = exception.reason {
				additionalData["reason"] = reason
			}

			if let userInfo = exception.userInfo {
				additionalData["userInfo"] = userInfo
			}
		}
		
		if (!additionalData.isEmpty) {
			log(level:.error, message:"Exception - \(name)", longMessage:message, additionalData: additionalData)
		}
		else {
			log(level:.error, message:"Exception - \(name)", longMessage:message)
		}
	}

	public func logError(_ name: String, message: String?, properties: [String : Any]?, error: Error?) {
		
		var additionalData = [String: Any]()
		additionalData["trace"] = Thread.callStackSymbols

		if let properties = properties {
			additionalData["properties"] = properties
		}

		if let error = error as NSError? {
			additionalData["domain"] = error.domain
			additionalData["code"] = error.code
			additionalData["description"] = error.localizedDescription
			additionalData["userInfo"] = error.userInfo
		}
		else if let error = error {
			additionalData["description"] = "\(error)"
		}
		
		if (!additionalData.isEmpty) {
			log(level:.error, message:"Error - \(name)", longMessage:message, additionalData: additionalData)
		}
		else {
			log(level:.error, message:"Error - \(name)", longMessage:message)
		}
	}

	public func uncaughtException(_ exception: NSException) {
		logError("Uncaught Exception", message: "Crash on iOS \(UIDevice.current.systemVersion)", properties:nil, exception: exception)
	}
}

fileprivate extension GraylogAnalyticsKitProvider {
	func log(level:GraylogLevel, message:String, longMessage: String? = nil, additionalData:[String:Any]? = nil, file: StaticString = #file, line: UInt = #line) {
		glInput.log(level: level, message: message, longMessage:longMessage, additionalData: additionalData, file:file, line:line)
	}
}
