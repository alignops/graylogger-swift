import DBC

class GraylogUtils {
	class func hostname() -> String
	{
		var name = UnsafeMutablePointer<Int8>.allocate(capacity: 256)
		defer { name.deallocate(capacity: 256) }
		
		if gethostname(name, 255) == -1 {
			print("gethostname is attempting to return a hostname that is too long (\(errno)): \(strerror(errno))")
		}
		
		return String(cString: name)
	}
}

extension String {
	func truncated(toLength newLength: Int, trailing: String? = "…") -> String {
		if self.characters.count > newLength {
			let trailingText = trailing ?? ""
			let uptoIndex = newLength - 1 - trailingText.characters.count
			let index = self.index(self.startIndex, offsetBy:uptoIndex)
			
			return self.substring(to: index) + trailingText
		} else {
			return self
		}
	}
}

extension Date {
	static var iso8601formatter: DateFormatter? = nil
	
	func formatDateAndTime() -> String {
		if nil == Date.iso8601formatter {
			Date.iso8601formatter = DateFormatter()
			Date.iso8601formatter?.dateFormat = NSLocalizedString("yyyy-MM-dd'T'HH:mm:ssZZZZZ", comment:"Date format: ISO 8601")
			Date.iso8601formatter?.locale = NSLocale(localeIdentifier: NSLocale.preferredLanguages[0]) as Locale!
		}
		
		if let result = Date.iso8601formatter?.string(from: self) {
			return result
		}
		else {
			checkFailure("Unable to serialize date \(self)")
			return "\(self)"
		}
	}
}

extension Bundle {
	public var appName: String {
		var appName = self.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
		
		if appName == nil || appName!.isEmpty {
			appName = self.object(forInfoDictionaryKey: "CFBundleName") as? String
		}
		
		ensure(appName != nil && !appName!.isEmpty)
		return appName ?? "UNKNOWN"
	}
	
	public var appVersion: String {
		let versionNumber = self.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
		check(versionNumber != nil && !versionNumber!.isEmpty)
		
		let buildNumber = self.object(forInfoDictionaryKey: "CFBundleVersion") as? String
		check(buildNumber != nil && !buildNumber!.isEmpty)
		
		return "\(versionNumber ?? "UNKNOWN") (\(buildNumber ?? "UNKNOWN"))"
	}
	
	public var bundleId: String {
		let bundleId = self.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String
		
		ensure(bundleId != nil && !bundleId!.isEmpty)
		return bundleId ?? "UNKNOWN"
	}
}

#if !os(OSX)
public extension UIDevice {
	
	public var idStringForVendor: String? {
		return self.identifierForVendor?.uuidString
	}
}
#endif
