//
//  GraylogInput.swift
//  graylogger
//
//  Created by Jim Boyd on 6/29/17.
//

import Foundation
import DBC
import SwiftyJSON

#if os(iOS)
import UIKit
#endif

/// Provides access to a configurable [graylog message input](https://www.graylog.org)
///
/// Example usage:
///```
/// let accessPoint = GraylogInput.AccessPoint.http(host: "107.21.12.75", port: 12301)
/// var bbTestLog  = GraylogInput(accessPoint:accessPoint)
///
/// var bbTestLog2:GraylogInput = {
/// 	let accessPoint = GraylogInput.AccessPoint.http(host: "107.21.12.75", port: 12302)
///		let log = GraylogInput(accessPoint:accessPoint)
///		log.network = CachedNetworkProvider(cacheProvider: CoreDataCacheProvider())
///	    return log
///	}()
///
/// var bbTestLog3:GraylogInput = {
/// 	let accessPoint = GraylogInput.AccessPoint.http(host: "107.21.12.75", port: 12303)
///		let log = GraylogInput(accessPoint:accessPoint)
///		log.network = AlamofireNetworkProvider()
///	    return log
///	}()
///
/// var bbTestLog4:GraylogInput = {
/// 	let accessPoint = GraylogInput.AccessPoint.http(host: "107.21.12.75", port: 12304)
///		let log = GraylogInput(accessPoint:accessPoint, maxLogLevel:.debug, includeStackTraceInfo:true)
///		log.reachability = ReachabilitySwiftProvider()
///	    return log
///	}()
/// ....
/// bbTestLog.log(message:"Something to see here")
/// bbTestLog.log(message:"Something to see here", longMessage:"This is a longer description of the event or issue")
/// bbTestLog2.log(message:"Here is some data", additionalData:["String":"Stuff Here","Date": Date(),"Array": [1, 2, 3],"Dictionary": ["one":1, "two":2, "three":3],)
///```
public class GraylogInput {

	/// - http: An http access-point to a graylog server.
	/// - https: An https access-point to a graylog server.
	/// - udp: : A udp access-point to a graylog server. The default network provider does not support udp. If you require upd support you must provide your own
	///        udp NetworkProvider. See `network: NetworkProvider` below
	public enum AccessPoint: Hashable {
		/// An http access-point to a graylog server.
		///
		/// - Associated Values:
		///   - host: http url to the target graylog server.
		///   - port: port number to target a specific graylog input.
		case http(host:String, port: Int)
		
		/// An https access-point to a graylog server.
		///
		/// - Associated Values:
		///   - host: https url to the target graylog server.
		///   - port: port number to target a specific graylog input.
		case https(host:String, port: Int)
		
		/// An udp access-point to a graylog server.  The default network provider does not support udp. If you require upd support you must provide your own
		///        udp NetworkProvider. See `network: NetworkProvider` below
		///
		/// - Associated Values:
		///   - host: udp url to the target graylog server.
		///   - port: port number to target a specific graylog input.
		case udp(host:String, port: Int)

		
		/// A static property providing access to the associated `NetworkProvider`. Defaults to the shared URLSession.
		/// May be set by the client to a custom `NetworkProvider`. See the AlamoFire and AFNetworking providers included with this framework.
		///
		/// See Also: `CachedNetworkProvider.swift` for details of a builtin log caching mechanism provided with the framwework.
		public static var network: NetworkProvider = { return URLSession.shared}() {
			didSet {
				if self.reachability == nil {
					if let reachability = network as? ReachabilityProvider {
						self.reachability = reachability
					}
					else if let cached = network as? CachedNetworkProvider, let reachability = cached.passThrough as? ReachabilityProvider {
						self.reachability = reachability
					}
				}
			}
		}
		
		/// An optional static property providing access to the associated `ReachabilityProvider`. Defaults to nil.
		/// Note that if the associated `NetworkProvider` also implements `ReachabilityProvider` this property will automatically be
		/// assinged through the `network` property above. See the ReachabilitySwift provider included with this framework.
		public static var reachability: ReachabilityProvider?
	}

	/// The access-point definition (url and port) for the graylog input
	let accessPoint: AccessPoint

	/// The maximum GraylogLevel that this endpoint will log.  All logs with levels > then this maximum will be ignored. Defaults to `.informational`
	let maxLogLevel: GraylogLevel

	/// If `true` file paths and line numbers of the calling functions will be automatically included in the log. Defaults to `false`
	let includeFileLineInfo: Bool
	
	/// If `true` file a call-stack-trace will be automatically included in the log. Defaults to `false`
	let includeStackTraceInfo: Bool

	/// If `true` file a app and device details will be automatically included in the log. Defaults to `true`
	/// - The following will be provided: `App Name`, `App Id`, `App Version`, `Device Peferred Language`,
	/// `OS Version`, `Device Model`, `Device Platform`, `Device Name`, and the `vender device id``
	let includeAppDetails:Bool
	
	public init(accessPoint: AccessPoint, maxLogLevel: GraylogLevel = .informational, includeFileLineInfo: Bool = false, includeStackTraceInfo: Bool = false, includeAppDetails:Bool = true) {
		self.accessPoint = accessPoint
		self.maxLogLevel = maxLogLevel
		self.includeFileLineInfo = includeFileLineInfo
		self.includeStackTraceInfo = includeStackTraceInfo
		self.includeAppDetails = includeAppDetails
	}

	/// Send a log to the graylog endpoint
	///
	/// - Parameters:
	///   - host: the name of the host, source or application that sent this message; Default is set via a call to `gethostname()`.
	///   - level: the level equal to the standard syslog levels; optional, default is 1 (ALERT).  All levels > then the endpoint's maximum will be ignored.
	///   - message: a short descriptive message; MUST be set by client.
	///   - longMessage: a long message that can i.e. contain a backtrace.
	///   - additionalData: every key:value pair will be treated as an additional field.  Defaults to nil.
	///     Allowed characters in field names are any word character (letter, number, underscore), dashes and dots.
	///     DO NOT send `id` or `_id` as an additional field, the framework will fail a DBC require if it detects this key .
	///   - timeStamp: seconds since UNIX epoch with optional decimal places for milliseconds. Defaults to the current date and time.
	///   - file: the file (with path if you want) that caused the error. Defaults to the current file path of the call.
	///   - line: the line in a file that caused the error. Defaults to the current file line number of the call.
	///
	public func log(host:String = GraylogUtils.hostname(), level:GraylogLevel = .alert, message:String, longMessage:String? = nil, additionalData:[String:Any]? = nil, timeStamp:Date = Date(), file: StaticString = #file, line: UInt = #line) {
		
		// ignore messages that are not important enough to log
		if (level > self.maxLogLevel) { return }
		
		let payload = self.buildPayload(host: host, level: level, message: message, longMessage: longMessage, timeStamp: timeStamp, additionalData: additionalData, file: file, line: line)
		var json:Data? = nil
		
		// If we get a serialization error then attemt to log the specifics of the error in place of the log
		do {
			json = try self.serializePayload(payload: payload)
		}
		catch {
			checkFailure("Failed to serialize error log : \(error)")
			self.submitErrorReport(host: host, error: error, timeStamp: timeStamp, file: file, line: line)
			return
		}
		
		check(json != nil)
		
		network.submitLog(accessPoint: self.accessPoint, payload: json!) { (response,error) in
			check(error != nil, "Failed to submit error log : \(error!)")

			// If we get a error not handled by the cache mechanism then attemt to log the specifics of the error in place of the log
			if let error = error {
				switch error {
				case GraylogSessionError.cahedLogWithError(_):
					return // This is really more informative then it is an error
				default:
					self.submitErrorReport(host: host, error: error, timeStamp: timeStamp, file: file, line: line)
				}
			}
		}
	}
}

public extension GraylogInput.AccessPoint {
	/// The `host` associated value of the access-point.
	var host: String {
		switch self {
		case .http(let host, _):
			return host
		case .https(let host, _):
			return host
		case .udp(let host, _):
			return host
		}
	}
	
	/// The `port` associated value of the access-point.
	var port: Int {
		switch self {
		case .http(_, let port):
			return port
		case .https(_, let port):
			return port
		case .udp(_, let port):
			return port
		}
	}

	/// Supplies a properly formatted gelf url to the graylog input.
	var url: URL {
		switch self {
		case .http(let host, let port):
			return URL(string: String(format: "http://%@:%d/gelf", host, port))!
		case .https(let host, let port):
			return URL(string: String(format: "https://%@:%d/gelf", host, port))!
		case .udp(let host, let port):
			return URL(string: String(format: "udp://%@:%d/gelf", host, port))!
		}
	}
}

fileprivate extension GraylogInput {
	func appDetails() -> [String:Any] {
		var appDetails = [String:Any]()
		appDetails["app_name"] = Bundle.main.appName
		appDetails["app_id"] = Bundle.main.bundleId
		appDetails["app_version"] = Bundle.main.appVersion
		appDetails["manufacturer"] = "Apple"
		appDetails["language"] = NSLocale.preferredLanguages[0]
		
		#if os(iOS)
			appDetails["os_version"] = UIDevice.current.systemVersion
			appDetails["model"] = UIDevice.current.model
			appDetails["platform"] = UIDevice.current.systemName
			appDetails["device_name"] = UIDevice.current.name
			
			if let identifierForVendor = UIDevice.current.idStringForVendor {
				appDetails["vendor_device_id"] = identifierForVendor
			}
		#endif
		
		return appDetails
	}
	
	// http://docs.graylog.org/en/2.2/pages/gelf.html#gelf-payload-specification
	func buildPayload(host:String, level:GraylogLevel, message:String, longMessage:String?, timeStamp:Date, additionalData:[String:Any]?, file: StaticString, line: UInt) -> [String:Any] {
		var dict = [String: Any](minimumCapacity: 16)
		
		// Defaults/Required data
		do {
			dict["version"] = "1.1"
			dict["host"] = host
			dict["short_message"] = message
			dict["timestamp"] = timeStamp.timeIntervalSince1970
			dict["level"] = level.rawValue
			
			if let longMessage = longMessage {
				dict["full_message"] = longMessage.truncated(toLength: 32000)
			}
		}
		
		var moreData = additionalData ?? [String:Any]()
		
		// Supplimental data
		do {
			if self.includeFileLineInfo {
				moreData["_file"] = "\(file)"
				moreData["_line"] = line
			}

			if self.includeAppDetails {
				let addDetailsJSON = JSON(self.appDetails())
				moreData["_app_details"] = addDetailsJSON.rawString()
			}
			
			if self.includeStackTraceInfo  && (moreData["trace"] == nil && moreData["_trace"] == nil) {
				moreData["_trace"] = Thread.callStackSymbols
			}
		}
		
		// Additional data
		do {
			for key: String in moreData.keys {
				require(key != "id", "_id is a reserved graylog attribute: \(message), \(moreData)")
				require(key != "_id", "_id is a reserved graylog attribute: \(message), \(moreData)")
				
				if let data = moreData[key] {
					var value:Any = data
					
					// Try to catch a few specific data types that we can pre-process for graylog (and the JSON serializer)
					// If we can not serialize child maps and arraays then provide an error message instead of failing the
					// log attempt.
					if let date = value as? Date {
						value = date.formatDateAndTime()
					}
					else if let map = value as? [String:Any] {
						let paramsJSON = JSON(map)
						
						if let jsonStr = paramsJSON.rawString() {
							value = jsonStr
						}
						else {
							checkFailure("Unable to serialize dictionary to JSON : \(key):\(value)")
							value = "Unable to serialize dictionary to JSON : \(key):\(value)"
						}
					}
					else if let array = value as? [Any] {
						let paramsJSON = JSON(array)
						
						if let jsonStr = paramsJSON.rawString() {
							value = jsonStr
						}
						else {
							checkFailure("Unable to serialize array to JSON  : \(key):\(value)")
							value = "Unable to serialize array to JSON  : \(key):\(value)"
						}
					}
					
					// No whitespace allowed in the keys...
					let useKey = key.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "_")
					
					if let str = value as? String {
						value = str.truncated(toLength: 32000)
					}
					
					// Non-standard keys must be proceeded with an "_"
					if useKey.hasPrefix("_") || (useKey == "full_message") {
						dict[useKey] = value
					}
					else {
						dict["_" + (useKey)] = value
					}
				}
			}
		}
		
		return dict
	}
	
	func serializePayload(payload: [String:Any]) throws -> Data  {
		var json:Data? = nil
		
		do {
			json = try JSON(payload).rawData()
			if (json == nil || json!.isEmpty) {
				throw GraylogSessionError.emptyPayloadSerializationError(info: "Payload : /(payload)")
			}
		}
		catch {
			throw GraylogSessionError.jsonSerializationError(error: error)
		}
		
		return json!
	}
	
	func submitErrorReport(host:String, error:Error, timeStamp:Date, file: StaticString, line: UInt) {
		let payload = self.buildPayload(host: host, level: .error, message: "Logging failed with error", longMessage: "Logging failed with error : \(error)", timeStamp: timeStamp, additionalData: nil, file: file, line: line)
		var json:Data? = nil
		
		do {
			json = try JSON(payload).rawData()
			check(json != nil, "Failed to serialize error log : \(error)")
		}
		catch {
			checkFailure("Failed to serialize error log : \(error)")
		}
		
		if let json = json {
			network.submitLog(accessPoint: self.accessPoint, payload: json) { (response,error) in
				if let error = error {
					checkFailure("Failed to submit error log : \(error)")
				}
			}
		}
	}
}
