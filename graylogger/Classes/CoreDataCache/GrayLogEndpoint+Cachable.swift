//
//  GraylogEndpoint+Cachable.swift
//  graylogger
//
//  Created by Jim Boyd on 7/3/17.
//

import Foundation


enum GraylogType: String {
	case http
	case https
	case udp
}

extension GraylogEndpoint {
	
	init(logType:GraylogType, host:String, port:Int, loglevel: GraylogLevel) {
		switch logType {
		case .http:
			self = .http(host: host, port: port, maxLogLevel: loglevel)
		case .https:
			self = .https(host: host, port: port, maxLogLevel: loglevel)
		case .udp:
			self = .udp(host: host, port: port, maxLogLevel: loglevel)
		}
	}
	
	var logType: GraylogType {
		switch self {
		case .http:
			return .http
		case .https:
			return .https
		case .udp:
			return .udp
		}
	}
}
