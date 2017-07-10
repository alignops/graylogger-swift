//
//  GraylogEndpoint+URLRequest.swift
//  DBC
//
//  Created by Jim Boyd on 6/30/17.
//

import Foundation
import SwiftyJSON
import DBC

public extension GraylogEndpoint {
	/// Provides a default "POST" URLRequest for the endpoint. The provided payload is added as the `http body` of the request.
	///
	/// - Parameter jsonData: the payload serialized into a json data item.
	func request(withPayload jsonData: Data) -> URLRequest{
		var request = URLRequest(url: self.url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60.0)
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.httpMethod = "POST"
		request.httpBody = jsonData
		
		return request
	}
}
