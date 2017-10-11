//
//  ReachabilitySwiftProvider.swift
//  graylogger
//
//  Created by Jim Boyd on 6/29/17.
//

import Foundation
import Reachability

public class ReachabilitySwiftProvider : ReachabilityProvider {
	let reach = Reachability()
	
	public init() {
		try? reach?.startNotifier()
	}
	
	public func networkIsReachable(endpoint:GraylogEndpoint) -> Bool {
		return reach?.isReachable ?? true
	}
}

