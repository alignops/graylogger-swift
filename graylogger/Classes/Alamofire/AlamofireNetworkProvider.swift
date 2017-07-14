//
//  AlamofireNetworkProvider.swift
//  graylogger
//
//  Created by Jim Boyd on 6/29/17.
//

import Foundation
import Alamofire
import DBC

public class AlamofireNetworkProvider: NetworkProvider {
	#if !os(watchOS)
	let reachabilityManager = Alamofire.NetworkReachabilityManager()
	#endif
	
	public init() {
		#if !os(watchOS)
		reachabilityManager?.startListening()
		#endif
	}
	
	public func submitLog(endpoint: GraylogEndpoint, payload jsonData: Data, completion: ((Any?, Error?) -> Void)?) {
		
		if case GraylogEndpoint.udp(_, _, _) = endpoint {
			requireFailure("Can not support UDP endpoint with URLSession")
		}
		
		if self.networkIsReachable() {
			Alamofire.request(endpoint.request(withPayload: jsonData))
			.response { response in
				if let completion = completion {
					var completeErr:Error? = nil
					if let error = response.error {
						completeErr = GraylogSessionError.responseError(error: error)
					} else {
						guard let httpResponse = response.response else {
							completeErr = GraylogSessionError.nonHTTPResponse(response: response.response)
							return
						}
						
						if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
							completeErr = GraylogSessionError.httpRequestFailed(response: httpResponse, result: response.data)
						}
					}
					
					DispatchQueue.main.async {
						completion(response.data, completeErr)
					}
				}
			}
		}
		else if let completion = completion {
			DispatchQueue.main.async {
				completion(nil, GraylogSessionError.reachabilityError)
			}
		}
	}
}

#if !os(watchOS)
extension AlamofireNetworkProvider: ReachabilityProvider {

	public func networkIsReachable() -> Bool {
		// Must call reachabilityManager?.startListenings() to start the monitoring.
		if (reachabilityManager?.networkReachabilityStatus == .unknown) {
			reachabilityManager?.startListening()
			return true
		}
		
		return reachabilityManager?.isReachable ?? true
	}
}
#endif

