//
//  GraylogEndpoint.swift
//  Pods
//
//  Created by Jim Boyd on 7/21/17.
//

import Foundation

/// - http: An http access-point to a graylog server.
/// - https: An https access-point to a graylog server.
/// - udp: : A udp access-point to a graylog server. The default network provider does not support udp. If you require upd support you must provide your own
///        udp NetworkProvider. See `network: NetworkProvider` below
public enum GraylogEndpoint {
	/// An http access-point to a graylog server.
	///
	/// - Associated Values:
	///   - host: http url to the target graylog server.
	///   - port: port number to target a specific graylog input.
	case http(host:String, port: Int)
	
	/// An https access-point to a graylog server.
	///
	/// - Associated Values:
	///   - host: https url to the target graylog server.
	///   - port: port number to target a specific graylog input.
	case https(host:String, port: Int)
	
	/// An udp access-point to a graylog server.  The default network provider does not support udp. If you require upd support you must provide your own
	///        udp NetworkProvider. See `network: NetworkProvider` below
	///
	/// - Associated Values:
	///   - host: udp url to the target graylog server.
	///   - port: port number to target a specific graylog input.
	case udp(host:String, port: Int)
}

public extension GraylogEndpoint  {
	
	/// A static property providing access to the associated `NetworkProvider`. Defaults to the shared URLSession.
	/// May be set by the client to a custom `NetworkProvider`. See the AlamoFire and AFNetworking providers included with this framework.
	/// Note there is one setting per enum case (i.e .http, .https, .enum each jave only one settable value regardless of associated values)
	///
	/// See Also: `CachedNetworkProvider.swift` for details of a builtin log caching mechanism provided with the framwework.
	var network: NetworkProvider {
		get {
			return self.networkProvider ?? URLSession.shared
		}
		set {
			self.networkProvider = newValue
		}
	}

	func submitLog(payload jsonData: Data, completion: ((Any?, Error?) -> Void)?) {
		self.network.submitLog(endpoint:self, payload:jsonData, completion:completion)
	}
}

public extension GraylogEndpoint {
	
	/// An optional static property providing access to the associated `ReachabilityProvider`. Defaults to nil.
	/// Note there is one setting per enum case (i.e .http, .https, .enum each jave only one settable value regardless of associated values)
	/// Note that if the associated `NetworkProvider` also implements `ReachabilityProvider` this property will automatically be
	/// assinged through the `network` property above. See the ReachabilitySwift provider included with this framework.
	var reachability: ReachabilityProvider? {
		get {
			return self.reachabilityProvider
		}
		set {
			self.reachabilityProvider = newValue
		}
	}

	func isReachable() -> Bool {
		if let reachability = self.reachability {
			return reachability.networkIsReachable(endpoint:self)
		}
		
		return true
	}
}

public extension GraylogEndpoint {
	/// The `host` associated value of the access-point.
	var host: String {
		switch self {
		case .http(let host, _):
			return host
		case .https(let host, _):
			return host
		case .udp(let host, _):
			return host
		}
	}
	
	/// The `port` associated value of the access-point.
	var port: Int {
		switch self {
		case .http(_, let port):
			return port
		case .https(_, let port):
			return port
		case .udp(_, let port):
			return port
		}
	}
}

extension GraylogEndpoint: Hashable {
	private static var networkProviders:[GraylogEndpoint:NetworkProvider] = [:]
	private static var reachabilityProviders:[GraylogEndpoint:ReachabilityProvider] = [:]

	fileprivate var networkProvider: NetworkProvider? {
		get {
			return GraylogEndpoint.networkProviders[self]
		}
		set {
			if let newValue = newValue {
				GraylogEndpoint.networkProviders[self] = newValue
				
				if self.reachabilityProvider == nil {
					if let reachability = newValue as? ReachabilityProvider {
						self.reachabilityProvider = reachability
					}
					else if let cached = newValue as? CachedNetworkProvider, let reachability = cached.passThrough as? ReachabilityProvider {
						self.reachabilityProvider = reachability
					}
				}
			}
		}
	}
	
	fileprivate  var reachabilityProvider: ReachabilityProvider? {
		get {
			return GraylogEndpoint.reachabilityProviders[self]
		}
		set {
			if let newValue = newValue {
				GraylogEndpoint.reachabilityProviders[self] = newValue
			}
		}
	}

	public func hash(into hasher: inout Hasher) {
		switch self {
		case .http: hasher.combine(1)
		case .https: hasher.combine(2)
		case .udp:  hasher.combine(3)
		}
	}

	
	public static func ==(lhs: GraylogEndpoint, rhs: GraylogEndpoint) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}
