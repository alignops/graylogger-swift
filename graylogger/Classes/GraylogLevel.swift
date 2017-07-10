//
//  GraylogLevel.swift
//  graylogger
//
//  Created by Jim Boyd on 6/29/17.
//

import Foundation

public enum GraylogLevel : Int, Comparable {
	case alert = 1
	case critical
	case error
	case warning
	case notice
	case informational
	case debug
	
	static public func ==(lhs: GraylogLevel, rhs: GraylogLevel) -> Bool {
		return lhs.rawValue == rhs.rawValue
	}
	
	static public func <(lhs: GraylogLevel, rhs: GraylogLevel) -> Bool {
		return lhs.rawValue < rhs.rawValue
	}
}
