//
//  NetworkProvider.swift
//  graylogger
//
//  Created by Jim Boyd on 6/29/17.
//

import Foundation

/// Protocol to provide network log submition for the graylog endpoints.
/// See the `URLSession`, `AFNetworking` and `Alamofire` implementations included in this framework.
public protocol NetworkProvider {
	/// Submit the log to the graylog server associated with the provided endpoint.
	///
	/// - Parameters:
	///   - endpoint: The endpoint representing the graylog message input
	///   - jsonData: THe JSON serialized graylog payload
	///   - completion: call this closure (if provided) with any network responce data, or an error if submition fails.
	///					Note that the submition is considered to fail if the request return a status outside of the bounds 200..<300.
	func submitLog(endpoint: GraylogEndpoint, payload jsonData: Data, completion: ((_ response: Any?, _ error:Error?) -> Void)?)
}
	
/// Protocol to provide a network reacahability query.
/// See the `ReachabilitySwift`, `AFNetworking` and `Alamofire` implementations included in this framework.
public protocol ReachabilityProvider {
	/// Return true if the network is reachable, false otherwise.
	func networkIsReachable() -> Bool
}

extension NetworkProvider {
	public func networkIsReachable() -> Bool {
		if let reachability = GraylogEndpoint.reachability {
			return reachability.networkIsReachable()
		}
		
		return true
	}
}
