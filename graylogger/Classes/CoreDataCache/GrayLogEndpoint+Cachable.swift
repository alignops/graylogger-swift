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

	init(logType:GraylogType, host:String, port:Int) {
		switch logType {
		case .http:
			self = .http(host: host, port: port)
		case .https:
			self = .https(host: host, port: port)
		case .udp:
			self = .udp(host: host, port: port)
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
