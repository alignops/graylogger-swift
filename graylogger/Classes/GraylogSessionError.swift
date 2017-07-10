//
//  GraylogSessionError.swift
//  graylogger
//
//  Created by Jim Boyd on 7/6/17.
//

import Foundation

public enum GraylogSessionError: Swift.Error {
	/// Network is not reachable
	case reachabilityError
	/// Response is not NSHTTPURLResponse
	case nonHTTPResponse(response: URLResponse?)
	/// Response is not successful. (not in `200 ..< 300` range)
	case httpRequestFailed(response: HTTPURLResponse, result:Any?)
	/// Response error.
	case responseError(error: Swift.Error)
	/// Could not serialize payload due to error.
	case jsonSerializationError(error: Swift.Error)
	/// Payload was serialized with an empty result.
	case emptyPayloadSerializationError(info: String)
	/// Log was cached due to the assigned error.
	case cahedLogWithError(error: Swift.Error)
}

extension GraylogSessionError : CustomDebugStringConvertible {
	/// A textual representation of `self`, suitable for debugging.
	public var debugDescription: String {
		switch self {
		case .reachabilityError:
			return "Network is unreachable."
		case let .nonHTTPResponse(response):
			return "Response is not NSHTTPURLResponse: `\(String(describing: response))`."
		case let .httpRequestFailed(response, result):
			return "HTTP request failed with statusCode: `\(response.statusCode)` and result: `\(String(describing: result))`."
		case let .responseError(error):
			return "Error returned with response: \(error)"
		case let .cahedLogWithError(error):
			return "The item was cached as a result of the following error: \(error)"
		case let .jsonSerializationError(error):
			return "There was a serialization error: \(error)"
		case let .emptyPayloadSerializationError(info):
			return "Payload was serialized with an empty : \(info)"
		}
	}
}
