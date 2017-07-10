//
//  GraylogEndpoint.swift
//  graylogger
//
//  Created by Jim Boyd on 6/29/17.
//

import Foundation
import DBC
import SwiftyJSON

/// Provides access to a specific [graylog message input](https://www.graylog.org)
///
/// - http: An http endpoint to a graylog server.
/// - https: An https endpoint to a graylog server.
/// - udp: : A udp endpoint to a graylog server. The default network provider does not support udp. If you require upd support you must provide your own
///        udp NetworkProvider. See `network: NetworkProvider` below
///
/// Example usage:
///```
/// var bbTestLog  = GraylogEndpoint.http(host: "192.21.12.75", port: 12301, maxLogLevel: .informational)
///
/// var bbTestLog2:GraylogEndpoint = {
///	let log = GraylogEndpoint.http(host: "107.21.12.75", port: 12302, maxLogLevel: .informational)
///		GraylogEndpoint.network = CachedNetworkProvider(cacheProvider: CoreDataCacheProvider())
///	    return log
///	}()
///
/// var bbTestLog3:GraylogEndpoint = {
///	let log = GraylogEndpoint.http(host: "107.21.12.75", port: 12303, maxLogLevel: .informational)
///		GraylogEndpoint.network = AlamofireNetworkProvider()
///	    return log
///	}()
///
/// var bbTestLog4:GraylogEndpoint = {
///	let log = GraylogEndpoint.http(host: "107.21.12.75", port: 12304, maxLogLevel: .informational)
///		GraylogEndpoint.reachability = ReachabilitySwiftProvider()
///	    return log
///	}()
/// ....
/// bbTestLog.log(message:"Something to see here")
/// bbTestLog.log(message:"Something to see here", longMessage:"This is a longer description of the event or issue")
/// bbTestLog2.log(message:"Here is some data", additionalData:["String":"Stuff Here","Date": Date(),"Array": [1, 2, 3],"Dictionary": ["one":1, "two":2, "three":3],)
///```
public enum GraylogEndpoint {
	/// An http endpoint to a graylog server.
	///
	/// - Associated Values:
	///   - host: http url to the target graylog server.
	///   - port: port number to target a specific graylog input.
	///   - maxLogLevel: the maximum GraylogLevel that this endpoint will log.  All logs with levels > then this maximum will be ignored.
	case http(host:String, port: Int, maxLogLevel: GraylogLevel)
	
	/// An https endpoint to a graylog server.
	///
	/// - Associated Values:
	///   - host: https url to the target graylog server.
	///   - port: port number to target a specific graylog input.
	///   - maxLogLevel: the maximum GraylogLevel that this endpoint will log.  All logs with levels > then this maximum will be ignored.
	case https(host:String, port: Int, maxLogLevel: GraylogLevel)
	
	/// An udp endpoint to a graylog server.  The default network provider does not support udp. If you require upd support you must provide your own
	///        udp NetworkProvider. See `network: NetworkProvider` below
	///
	/// - Associated Values:
	///   - host: udp url to the target graylog server.
	///   - port: port number to target a specific graylog input.
	///   - maxLogLevel: the maximum GraylogLevel that this endpoint will log.  All logs with levels > then this maximum will be ignored.
	case udp(host:String, port: Int, maxLogLevel: GraylogLevel)
}

public extension GraylogEndpoint {
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
	/// - App Details : The following app detail information is also provided with each log:
	///   `App Name, App Id, App Version, Device Peferred Language, OS Version, Device Model, Devoce Platform, Device Name, and the vender device id`
	///
	func log(host:String = GraylogUtils.hostname(), level:GraylogLevel = .alert, message:String, longMessage:String? = nil, additionalData:[String:Any]? = nil, timeStamp:Date = Date(), file: StaticString = #file, line: UInt = #line) {
		
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
		
		GraylogEndpoint.network.submitLog(endpoint: self, payload: json!) { (response,error) in
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

public extension GraylogEndpoint {
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

public extension GraylogEndpoint {
	/// Access the `host` associated value of the endpoint.
	var host: String {
		switch self {
		case .http(let host, _, _):
			return host
		case .https(let host, _, _):
			return host
		case .udp(let host, _, _):
			return host
		}
	}
	
	/// Access the `port` associated value of the endpoint.
	var port: Int {
		switch self {
		case .http(_, let port, _):
			return port
		case .https(_, let port, _):
			return port
		case .udp(_, let port, _):
			return port
		}
	}
	
	/// Access the `maxLogLevel` associated value of the endpoint.
	var maxLogLevel: GraylogLevel {
		switch self {
		case .http(_, _, let maxLogLevel):
			return maxLogLevel
		case .https(_, _, let maxLogLevel):
			return maxLogLevel
		case .udp(_, _, let maxLogLevel):
			return maxLogLevel
		}
	}
	
	/// Supplies a properly formatted gelf url to the graylog input.
	var url: URL {
		switch self {
		case .http(let host, let port, _):
			return URL(string: String(format: "http://%@:%d/gelf", host, port))!
		case .https(let host, let port, _):
			return URL(string: String(format: "https://%@:%d/gelf", host, port))!
		case .udp(let host, let port, _):
			return URL(string: String(format: "udp://%@:%d/gelf", host, port))!
		}
	}
}

fileprivate extension GraylogEndpoint {
	func appDetails() -> [String:Any] {
		var appDetails = [String:Any]()
		appDetails["app_name"] = Bundle.main.appName
		appDetails["app_id"] = Bundle.main.bundleId
		appDetails["app_version"] = Bundle.main.appVersion
		appDetails["manufacturer"] = "Apple"
		appDetails["language"] = NSLocale.preferredLanguages[0]
		
		#if !os(OSX)
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
	
	func buildPayload(host:String, level:GraylogLevel, message:String, longMessage:String?, timeStamp:Date, additionalData:[String:Any]?, file: StaticString, line: UInt) -> [String:Any] {
		var dict = [String: Any](minimumCapacity: 16)
		
		dict["version"] = "1.1"
		dict["host"] = host
		dict["short_message"] = message
		dict["timestamp"] = timeStamp.timeIntervalSince1970
		dict["level"] = level.rawValue
		dict["file"] = "\(file)"
		dict["line"] = line
		
		if let longMessage = longMessage {
			dict["full_message"] = longMessage
		}
		
		let addDetailsJSON = JSON(self.appDetails())
		dict["_app_details"] = addDetailsJSON.rawString()
		
		if let additionalData = additionalData {
			for key: String in additionalData.keys {
				require(key != "id", "_id is a reserved graylog attribute: \(message), \(additionalData)")
				require(key != "_id", "_id is a reserved graylog attribute: \(message), \(additionalData)")
				
				if let data = additionalData[key] {
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
			GraylogEndpoint.network.submitLog(endpoint: self, payload: json) { (response,error) in
				if let error = error {
					checkFailure("Failed to submit error log : \(error)")
				}
			}
		}
	}
}
