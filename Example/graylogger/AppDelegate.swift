//
//  AppDelegate.swift
//  graylogger
//
//  Created by jjamminjm on 06/27/2017.
//  Copyright (c) 2017 jjamminjm. All rights reserved.
//

import UIKit
import AnalyticsKit
import graylogger
import AFNetworking

public enum BusyAKChannel: String {
	case debug
	case userEvent
}

public extension AnalyticsKit {
	
	public class var debug: AnalyticsKitChannel {
		return channel(BusyAKChannel.debug.rawValue)
	}
	
	public class var userEvent: AnalyticsKitChannel {
		return channel(BusyAKChannel.userEvent.rawValue)
	}
	
	public class func initializeProviders() {
		debug.initializeProviders([GraylogAnalyticsKitProvider(input: grayLogDebugLogger)])
		userEvent.initializeProviders([GraylogAnalyticsKitProvider(input: grayLogUserEventLogger)])
	}
	
	@inline(__always)
	public class func channel(_ busyChannel: BusyAKChannel) -> AnalyticsKitChannel {
		return self.channel(busyChannel.rawValue)
	}
}

fileprivate extension AnalyticsKit {
	static var grayLogDebugLogger: GraylogInput = {
		var endpoint = GraylogEndpoint.https(host: "graylog2.busybusy.io", port: 12302)
		endpoint.network = CachedNetworkProvider(cacheProvider: CoreDataCacheProvider(), networkProvider: AFHTTPSessionManager())
		
		let log = GraylogInput(endpoint: endpoint, maxLogLevel: .debug, includeFileLineInfo: true, includeStackTraceInfo: true)
		
		return log
	}()
	
	static  var grayLogUserEventLogger: GraylogInput = {
		let endpoint = GraylogEndpoint.https(host: "graylog2.busybusy.io", port: 12301)
		let log = GraylogInput(endpoint: endpoint)
		
		return log
	}()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		AnalyticsKit.initializeProviders()
		
        return true
    }
	
	var testData:[String:Any] {
		return [
				"Test Date": Date(),
				"    Test Array    ": [1, 2, 3],
				"Test Dictionary": ["one":1, "two":2, "three":3],
				"NON-JSON array": [GraylogSessionError.reachabilityError, GraylogSessionError.emptyPayloadSerializationError(info: "Stuff here")],
//				"This should fail": GraylogSessionError.reachabilityError
				]
	}

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
		AnalyticsKit.debug.logError("Graylog App applicationWillResignActive", message:" Should show in stream", properties:self.testData, error:nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		AnalyticsKit.debug.logEvent("Graylog App applicationDidEnterBackground",withProperties:self.testData)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
		AnalyticsKit.userEvent.logEvent("Graylog App applicationWillEnterForeground", withProperties:self.testData)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		AnalyticsKit.userEvent.logEvent("Graylog App applicationDidBecomeActive", withProperties:self.testData)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		AnalyticsKit.debug.logEvent("Graylog App applicationWillTerminate", withProperties:self.testData)
    }
}

