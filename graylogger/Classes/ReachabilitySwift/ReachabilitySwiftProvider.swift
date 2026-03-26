//
//  ReachabilitySwiftProvider.swift
//  graylogger
//
//  Created by Jim Boyd on 6/29/17.
//

import Foundation
import Reachability

public class ReachabilitySwiftProvider : ReachabilityProvider {
	let reach = try? Reachability()
	
	public init() {
		((try? reach?.startNotifier()) as ()??)
	}
	
	public func networkIsReachable(endpoint:GraylogEndpoint) -> Bool {
		if let reach = reach {
			return reach.connection != .unavailable
		}
		
		return true
	}
}

