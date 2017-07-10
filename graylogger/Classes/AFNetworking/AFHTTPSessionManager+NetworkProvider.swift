//
//  AFHTTPSessionManager+NetworkProvider.swift
//  graylogger
//
//  Created by Jim Boyd on 6/29/17.
//

import Foundation
import AFNetworking
import DBC

extension AFHTTPSessionManager: NetworkProvider, ReachabilityProvider {
	public func submitLog(endpoint: GraylogEndpoint, payload jsonData: Data, completion: ((Any?, Error?) -> Void)?) {
		
		if case GraylogEndpoint.udp(_, _, _) = endpoint {
			requireFailure("Can not support UDP endpoint with URLSession")
		}
		
		if self.networkIsReachable() {
			let task = self.dataTask(with: endpoint.request(withPayload: jsonData), completionHandler: { (response:URLResponse, result:Any?, error:Error?) in
				
				if let completion = completion {
					var completeErr:Error? = nil
					
					if let error = error {
						completeErr = GraylogSessionError.responseError(error: error)
					} else {
						guard let httpResponse = response as? HTTPURLResponse else {
							completeErr = GraylogSessionError.nonHTTPResponse(response: response)
							return
						}
						
						if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
							completeErr = GraylogSessionError.httpRequestFailed(response: httpResponse, result: result)
						}
					}
					
					DispatchQueue.main.async {
						completion(result, completeErr)
					}
				}
			})
			
			task.resume()
		}
		else if let completion = completion {
			DispatchQueue.main.async {
				completion(nil, GraylogSessionError.reachabilityError)
			}
		}
	}
	
	public func networkIsReachable() -> Bool {
		// Must call AFNetworkReachabilityManager.shared().startMonitoring() to start the monitoring.
		if (AFNetworkReachabilityManager.shared().networkReachabilityStatus == .unknown) {
			AFNetworkReachabilityManager.shared().startMonitoring()
			return true
		}
		
		return AFNetworkReachabilityManager.shared().isReachable
	}
}

