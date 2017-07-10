//
//  URLSession+NetworkSubmition.swift
//  graylogger
//
//  Created by Jim Boyd on 6/29/17.
//

import Foundation
import SwiftyJSON
import DBC

extension URLSession: NetworkProvider {
	public func submitLog(endpoint: GraylogEndpoint, payload jsonData: Data, completion: ((_ response: Any?, _ error:Error?) -> Void)?) {
		
		if case GraylogEndpoint.udp(_, _, _) = endpoint {
			requireFailure("Can not support UDP endpoint with URLSession")
		}
		
		if self.networkIsReachable() {
			let dataTask = self.dataTask(with: endpoint.request(withPayload: jsonData)) { data, response, error in
				
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
							completeErr = GraylogSessionError.httpRequestFailed(response: httpResponse, result: data)
						}
					}
					
					DispatchQueue.main.async {
						completion(data, completeErr)
					}
				}
			}
			
			dataTask.resume()
		}
		else if let completion = completion {
			DispatchQueue.main.async {
				completion(nil, GraylogSessionError.reachabilityError)
			}
		}
	}
}


