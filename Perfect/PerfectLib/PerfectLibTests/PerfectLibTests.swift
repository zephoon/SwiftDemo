//
//  PerfectLibTests.swift
//  PerfectLibTests
//
//  Created by Kyle Jessup on 2015-10-19.
//  Copyright © 2015 PerfectlySoft. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU Affero General Public License as
//	published by the Free Software Foundation, either version 3 of the
//	License, or (at your option) any later version, as supplemented by the
//	Perfect Additional Terms.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU Affero General Public License, as supplemented by the
//	Perfect Additional Terms, for more details.
//
//	You should have received a copy of the GNU Affero General Public License
//	and the Perfect Additional Terms that immediately follow the terms and
//	conditions of the GNU Affero General Public License along with this
//	program. If not, see <http://www.perfect.org/AGPL_3_0_With_Perfect_Additional_Terms.txt>.
//


import XCTest
@testable import PerfectLib

class PerfectLibTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		Foundation.srand(UInt32(time(nil)))
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	// !FIX! broken test
	/*
	func testJSONEncodeDecode() {
		
		let srcAry: [[String:JSONValue]] = [["i": -41451, "i2": 41451, "d": -42E+2, "t": true, "f": false, "n": JSONNull(), "a":[1, 2, 3, 4]], ["another":"one"]]
		let decode = JSONDecode()
		let encode = JSONEncode()
		var encoded = ""
		var decoded: JSONArrayType?
		do {
			
			encoded = try encode.encode(srcAry)
			
		} catch let e {
			XCTAssert(false, "Exception while encoding JSON \(e)")
			return
		}
		
		do {
			
			decoded = try decode.decode(encoded) as? JSONArrayType
			
		} catch let e {
			XCTAssert(false, "Exception while decoding JSON \(e)")
			return
		}
		
		XCTAssert(decoded != nil)
		
		let resAry = decoded!.array
		
		XCTAssert(srcAry.count == resAry.count)
		
		for index in 0..<srcAry.count {
			
			let d1 = srcAry[index]
			let a2 = resAry[index] as? JSONDictionaryType
			
			XCTAssert(a2 != nil)
			
			let d2 = a2!.dictionary
			
			for (key, value) in d1 {
				
				let value2 = d2[key]
				
				XCTAssert(value2 != nil)
				
				switch value {
				case let i as Int:
					XCTAssert(i == value2 as! Int)
				case let d as Double:
					XCTAssert(d == value2 as! Double)
				case let s as String:
					XCTAssert(s == value2 as! String)
				case let s as Bool:
					XCTAssert(s == value2 as! Bool)
					
				default:
					()
					// does not go on to test sub-sub-elements
				}
			}
			
		}
	}
	*/
	
	func testSQLite() {
		
		let testDb = "/tmp/sqlitetest.db"
		let check = File(testDb)
		if check.exists() {
			check.delete()
		}
		
		defer {
			let check = File(testDb)
			if check.exists() {
			check.delete()
			}
		}
		
		do {
			
			let sqlite = try SQLite(testDb)
			
			try sqlite.execute("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT, int, doub, blob)")
			
			try sqlite.doWithTransaction {
				try sqlite.execute("INSERT INTO test (id,name,int,doub,blob) VALUES (?,?,?,?,?)", count: 5) {
					(stmt: SQLiteStmt, num: Int) throws -> () in
					
					try stmt.bind(1, num)
					try stmt.bind(2, "This is name bind \(num)")
					try stmt.bind(3, num)
					try stmt.bind(4, Double(num))
					try stmt.bind(5, [Int8](arrayLiteral: num+1, num+2, num+3, num+4, num+5))
				}
			}
			
			try sqlite.forEachRow("SELECT name,int,doub,blob FROM test ORDER BY id") {
				(stmt: SQLiteStmt, num: Int) -> () in
				
				let name = stmt.columnText(0)
				let int = stmt.columnInt(1)
				let doub = stmt.columnDouble(2)
				let blob = stmt.columnBlob(3)
				
				XCTAssert(name == "This is name bind \(num)")
				XCTAssert(int == num)
				XCTAssert(doub == Double(num))
				
				let model: [Int8] = [1, 2, 3, 4, 5]
				for idx in 0..<blob.count {
					XCTAssert(model[idx] + num == blob[idx])
				}
			}
			
			sqlite.close()
			
		} catch let e {
			XCTAssert(false, "Exception while testing SQLite \(e)")
			return
		}
	}
	
	func _rand(to: Int32) -> Int32 {
		return Foundation.rand() % Int32(to)
	}
	
	func testMimeReader() {
		
		let boundary = "---------------------------9051914041544843365972754266"
		
		var testData = Array<Dictionary<String, String>>()
		let numTestFields = 1 + _rand(1000)
		
		for idx in 0..<numTestFields {
			var testDic = Dictionary<String, String>()
			
			testDic["name"] = "test_field_\(idx)"
			
			let isFile = _rand(3) == 2
			if isFile {
				var testValue = ""
				for _ in 1..<_rand(100000) {
					testValue.appendContentsOf("O")
				}
				testDic["value"] = testValue
				testDic["file"] = "1"
			} else {
				var testValue = ""
				for _ in 0..<_rand(1000) {
					testValue.appendContentsOf("O")
				}
				testDic["value"] = testValue
			}
			
			testData.append(testDic)
		}
		
		let file = File("/tmp/mimeReaderTest.txt")
		do {
			
			try file.openTruncate()
			
			for testDic in testData {
				try file.writeString("--" + boundary + "\r\n")
				
				let testName = testDic["name"]!
				let testValue = testDic["value"]!
				let isFile = testDic["file"]
				
				if let _ = isFile {
					
					try file.writeString("Content-Disposition: form-data; name=\"\(testName)\"; filename=\"\(testName).txt\"\r\n")
					try file.writeString("Content-Type: text/plain\r\n\r\n")
					try file.writeString(testValue)
					try file.writeString("\r\n")
					
				} else {
					
					try file.writeString("Content-Disposition: form-data; name=\"\(testName)\"\r\n\r\n")
					try file.writeString(testValue)
					try file.writeString("\r\n")
				}
				
			}
			
			try file.writeString("--" + boundary + "--")
			
			for num in 1...2048 {
				
				file.close()
				try file.openRead()
				
				print("Test run: \(num) bytes with \(numTestFields) fields")
				
				let mimeReader = MimeReader("multipart/form-data; boundary=" + boundary)
				
				XCTAssertEqual(mimeReader.boundary, "--" + boundary)
				
				var bytes = try file.readSomeBytes(num)
				while bytes.count > 0 {
					mimeReader.addToBuffer(bytes)
					bytes = try file.readSomeBytes(num)
				}
				
				XCTAssertEqual(mimeReader.bodySpecs.count, testData.count)
				
				var idx = 0
				for body in mimeReader.bodySpecs {
					
					let testDic = testData[idx++]
					
					XCTAssertEqual(testDic["name"]!, body.fieldName)
					if let _ = testDic["file"] {
						
						let file = File(body.tmpFileName)
						try file.openRead()
						let contents = try file.readSomeBytes(file.size())
						file.close()
						
						let decoded = UTF8Encoding.encode(contents)
						let v = testDic["value"]!
						XCTAssertEqual(v, decoded)
					} else {
						XCTAssertEqual(testDic["value"]!, body.fieldValue)
					}
					
					body.cleanup()
				}
			}
			
			file.close()
			file.delete()
			
		} catch let e {
			print("Exception while testing MimeReader: \(e)")
		}
	}

	func testMimeReaderSimple() {
		
		let boundary = "--6"
		
		var testData = Array<Dictionary<String, String>>()
		let numTestFields = 2
		
		for idx in 0..<numTestFields {
			var testDic = Dictionary<String, String>()
			
			testDic["name"] = "test_field_\(idx)"
			
			var testValue = ""
			for _ in 1...4 {
				testValue.appendContentsOf("O")
			}
			testDic["value"] = testValue
			
			testData.append(testDic)
		}
		
		let file = File("/tmp/mimeReaderTest.txt")
		do {
			
			try file.openTruncate()
			
			for testDic in testData {
				try file.writeString("--" + boundary + "\r\n")
				
				let testName = testDic["name"]!
				let testValue = testDic["value"]!
					
				try file.writeString("Content-Disposition: form-data; name=\"\(testName)\"; filename=\"\(testName).txt\"\r\n")
				try file.writeString("Content-Type: text/plain\r\n\r\n")
				try file.writeString(testValue)
				try file.writeString("\r\n")
			}
			
			try file.writeString("--" + boundary + "--")
			
			for num in 1...1 {
				
				file.close()
				try file.openRead()
				
				print("Test run: \(num) bytes with \(numTestFields) fields")
				
				let mimeReader = MimeReader("multipart/form-data; boundary=" + boundary)
				
				XCTAssertEqual(mimeReader.boundary, "--" + boundary)
				
				var bytes = try file.readSomeBytes(num)
				while bytes.count > 0 {
					mimeReader.addToBuffer(bytes)
					bytes = try file.readSomeBytes(num)
				}
				
				XCTAssertEqual(mimeReader.bodySpecs.count, testData.count)
				
				var idx = 0
				for body in mimeReader.bodySpecs {
					
					let testDic = testData[idx++]
					
					XCTAssertEqual(testDic["name"]!, body.fieldName)
					
					let file = File(body.tmpFileName)
					try file.openRead()
					let contents = try file.readSomeBytes(file.size())
					file.close()
					
					let decoded = UTF8Encoding.encode(contents)
					let v = testDic["value"]!
					XCTAssertEqual(v, decoded)
					
					body.cleanup()
				}
			}
			
			file.close()
			file.delete()
			
		} catch let e {
			print("Exception while testing MimeReader: \(e)")
		}
	}
	
	func testNetSendFile() {
		
		let testFile = File("/tmp/file_to_send.txt")
		let testContents = "Here are the contents"
		let port = "/tmp/foo.sock"
		let sockFile = File(port)
		if sockFile.exists() {
			sockFile.delete()
		}
		
		do {
			
			try testFile.openTruncate()
			try testFile.writeString(testContents)
			testFile.close()
			try testFile.openRead()
			
			let server = NetNamedPipe()
			let client = NetNamedPipe()
			
			try server.bind(port)
			server.listen()
			
			let serverExpectation = self.expectationWithDescription("server")
			let clientExpectation = self.expectationWithDescription("client")
			
			try server.accept(-1.0) {
				(inn: NetTCP?) -> () in
				let n = inn as? NetNamedPipe
				XCTAssertNotNil(n)
				
				do {
					try n?.sendFile(testFile) {
						(b: Bool) in
						
						XCTAssertTrue(b)
						
						n!.close()
						
						serverExpectation.fulfill()
					}
				} catch let e {
					XCTAssert(false, "Exception accepting connection: \(e)")
					serverExpectation.fulfill()
				}
			}
			
			try client.connect(port, timeoutSeconds: 5) {
				(inn: NetTCP?) -> () in
				let n = inn as? NetNamedPipe
				XCTAssertNotNil(n)
				
				do {
					try n!.receiveFile {
						(f: File?) in
						
						XCTAssertNotNil(f)
						
						do {
							let testDataRead = try f!.readSomeBytes(f!.size())
							if testDataRead.count > 0 {
								XCTAssertEqual(UTF8Encoding.encode(testDataRead), testContents)
							} else {
								XCTAssertTrue(false, "Got no data from received file")
							}
							
							f!.close()
						} catch let e {
							XCTAssert(false, "Exception in connection: \(e)")
						}
						clientExpectation.fulfill()
					}
					
				} catch let e {
					XCTAssert(false, "Exception in connection: \(e)")
					clientExpectation.fulfill()
				}
			}
			
			self.waitForExpectationsWithTimeout(10000, handler: {
				(_: NSError?) in
				server.close()
				client.close()
				testFile.close()
				testFile.delete()
			})
			
		} catch PerfectError.NetworkError(let code, let msg) {
			XCTAssert(false, "Exception: \(code) \(msg)")
		} catch let e {
			XCTAssert(false, "Exception: \(e)")
		}
	}
	
	func testSysProcess() {
		
		do {
			let proc = try SysProcess("ls", args:["-l", "/"], env:[("PATH", "/usr/bin:/bin")])
			
			XCTAssertTrue(proc.isOpen())
			XCTAssertNotNil(proc.stdin)
			
			let fileOut = proc.stdout!
			let data = try fileOut.readSomeBytes(4096)
			
			XCTAssertTrue(data.count > 0)
			
			print(UTF8Encoding.encode(data))
			let waitRes = try proc.wait()
			
			XCTAssertEqual(0, waitRes)
			
			proc.close()
		} catch let e {
			print("\(e)")
			XCTAssert(false, "Exception running SysProcess test")
		}
	}
	
	func testStringByEncodingHTML() {
		let src = "<b>\"quoted\" '& ☃"
		let res = src.stringByEncodingHTML
		XCTAssertEqual(res, "&lt;b&gt;&quot;quoted&quot; &#39;&amp; &#9731;")
	}
	
	func testStringByEncodingURL() {
		let src = "This has \"weird\" characters & ßtuff"
		let res = src.stringByEncodingURL
		XCTAssertEqual(res, "This%20has%20%22weird%22%20characters%20&%20%C3%9Ftuff")
	}
	
	func testStringByDecodingURL() {
		let src = "This has \"weird\" characters & ßtuff"
		let mid = src.stringByEncodingURL
		guard let res = mid.stringByDecodingURL else {
			XCTAssert(false, "Got nil String")
			return
		}
		XCTAssert(res == src, "Bad URL decoding")
	}
	
	func testStringByDecodingURL2() {
		let src = "This is badly%PWencoded"
		let res = src.stringByDecodingURL
		
		XCTAssert(res == nil, "Bad URL decoding")
	}
	
	func testStringByReplacingString() {
		
		let src = "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ"
		let test = "ABCFEDGHIJKLMNOPQRSTUVWXYZABCFEDGHIJKLMNOPQRSTUVWXYZABCFEDGHIJKLMNOPQRSTUVWXYZ"
		let find = "DEF"
		let rep = "FED"
		
		let res = src.stringByReplacingString(find, withString: rep)
		
		XCTAssert(res == test)
	}
	
	func testStringByReplacingString2() {
		
		let src = ""
		let find = "DEF"
		let rep = "FED"
		
		let res = src.stringByReplacingString(find, withString: rep)
		
		XCTAssert(res == src)
	}
	
	func testStringByReplacingString3() {
		
		let src = "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ"
		let find = ""
		let rep = "FED"
		
		let res = src.stringByReplacingString(find, withString: rep)
		
		XCTAssert(res == src)
	}
	
	func testSubstringTo() {
		
		let src = "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ"
		let res = src.substringTo(src.startIndex.advancedBy(5))
		
		XCTAssert(res == "ABCDE")
	}
	
	func testRangeTo() {
		
		let src = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		
		let res = src.rangeOf("DEF")
		XCTAssert(res == Range(start: src.startIndex.advancedBy(3), end: src.startIndex.advancedBy(6)))
		
		let res2 = src.rangeOf("FED")
		XCTAssert(res2 == nil)
		
		
		let res3 = src.rangeOf("def", ignoreCase: true)
		XCTAssert(res3 == Range(start: src.startIndex.advancedBy(3), end: src.startIndex.advancedBy(6)))
	}
	
	func testSubstringWith() {
		
		let src = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		let range = Range(start: src.startIndex.advancedBy(3), end: src.startIndex.advancedBy(6))
		XCTAssert("DEF" == src.substringWith(range))
	}
	
	func testICUFormatDate() {
		let dateThen = 0.0
		let formatStr = "E, dd-MMM-yyyy HH:mm:ss 'GMT'"
		do {
			let result = try ICU.formatDate(dateThen, format: formatStr, timezone: "GMT")
			XCTAssertEqual(result, "Thu, 01-Jan-1970 00:00:00 GMT")
		} catch let e {
			print("\(e)")
			XCTAssert(false, "Exception running testICUFormatDate")
		}
	}
	
	func testICUParseDate() {
		let formatStr = "E, dd-MMM-yyyy HH:mm:ss 'GMT'"
		do {
			let result = try ICU.parseDate("Thu, 01-Jan-1970 00:00:00 GMT", format: formatStr, timezone: "GMT")
			XCTAssertEqual(0, result)
		} catch let e {
			print("\(e)")
			XCTAssert(false, "Exception running testICUParseDate")
		}
	}
	
	func testMustacheParser1() {
		let usingTemplate = "TOP {\n{{#name}}\n{{name}}{{/name}}\n}\nBOTTOM"
		do {
			let template = try MustacheParser().parse(usingTemplate)
			let d = ["name":"The name"] as [String:Any]
			let context = MustacheEvaluationContext(map: d)
			let collector = MustacheEvaluationOutputCollector()
			template.evaluate(context, collector: collector)
			
			XCTAssertEqual(collector.asString(), "TOP {\n\nThe name\n}\nBOTTOM")
		} catch {
			XCTAssert(false)
		}
	}
	
	func testCURL() {
		
		let url = "https://www.treefrog.ca"
		let curl = CURL(url: url)
		
		XCTAssert(curl.url == url)
		
		var header = [UInt8]()
		var body = [UInt8]()
		
		var perf = curl.perform()
		while perf.0 {
			if let h = perf.2 {
				header.appendContentsOf(h)
			}
			if let b = perf.3 {
				body.appendContentsOf(b)
			}
			perf = curl.perform()
		}
		if let h = perf.2 {
			header.appendContentsOf(h)
		}
		if let b = perf.3 {
			body.appendContentsOf(b)
		}
		let perf1 = perf.1
		XCTAssert(perf1 == 0)
		
		let response = curl.responseCode
		XCTAssert(response == 200)
		
		
		XCTAssert(header.count > 0)
		XCTAssert(body.count > 0)
		
		let headerStr = UTF8Encoding.encode(header)
		let bodyStr = UTF8Encoding.encode(body)
		
		print(headerStr)
		print(bodyStr)
	}
	
	
	func testTCPSSLClient() {
		
		let address = "www.treefrog.ca"
		let requestString = [UInt8](("GET / HTTP/1.0\r\nHost: \(address)\r\n\r\n").utf8)
		let requestCount = requestString.count
		let clientExpectation = self.expectationWithDescription("client")
		let net = NetTCPSSL()
		
		let setOk = net.setDefaultVerifyPaths()
		XCTAssert(setOk, "Unable to setDefaultVerifyPaths \(net.sslErrorCode(1))")
		
		do {
			try net.connect(address, port: 443, timeoutSeconds: 5.0) {
				(net: NetTCP?) -> () in
				
				if let ssl = net as? NetTCPSSL {
					
					ssl.beginSSL {
						(success: Bool) in
						
						XCTAssert(success, "Unable to begin SSL \(ssl.errorStr(Int32(ssl.errorCode())))")
						if !success {
							clientExpectation.fulfill()
							return
						}
						
						do {
							let x509 = ssl.peerCertificate
							XCTAssert(x509 != nil)
							let peerKey = x509?.publicKeyBytes
							XCTAssert(peerKey != nil && peerKey!.count > 0)
						}
						
						ssl.writeBytes(requestString) {
							(sent:Int) -> () in
							
							XCTAssert(sent == requestCount)
							
							ssl.readBytesFully(1, timeoutSeconds: 5.0) {
								(readBytes: [UInt8]?) -> () in
								
								XCTAssert(readBytes != nil && readBytes!.count > 0)
								
								let s1 = UTF8Encoding.encode(readBytes!)
								
								ssl.readSomeBytes(4096) {
									(readBytes: [UInt8]?) -> () in
									
									XCTAssert(readBytes != nil && readBytes!.count > 0)
									
									let s = s1 + UTF8Encoding.encode(readBytes!)
									
									XCTAssert(s.hasPrefix("HTTP/1.1 200 OK"))
									
									print(s)
									
									clientExpectation.fulfill()
								}
							}
						}
					}
				} else {
					XCTAssert(false, "Did not get NetTCPSSL back after connect")
				}
			}
		} catch {
			XCTAssert(false, "Exception thrown")
		}
		
		self.waitForExpectationsWithTimeout(10000) {
			(_: NSError?) in
			net.close()
		}
	}
	
	func testStringByResolvingSymlinksInPath() { // YMMV tmp is a link on OSX
		
		let path = "/tmp/".stringByResolvingSymlinksInPath
		XCTAssert(path == "/private/tmp")
	}
	
//	func testStringBeginsWithSeparator() {
//		XCTAssert(true == "/foo/bar".beginsWithPathSeparator)
//		XCTAssert(true == "/".beginsWithPathSeparator)
//		XCTAssert(false == "foo/bar".beginsWithPathSeparator)
//	}
//	
//	func testStringEndsWithSeparator() {
//		XCTAssert(true == "/foo/bar/".endsWithPathSeparator)
//		XCTAssert(true == "/".endsWithPathSeparator)
//		XCTAssert(false == "foo/bar".endsWithPathSeparator)
//	}
//	
//	func testStringPathComponents() {
//		do {
//			let s = "user/{id}/do////*//it"
//			let a = ["user","{id}","do","*","it"]
//			
//			let comps = s.pathComponents
//			
//			for n in 0..<a.count {
//				XCTAssert(a[n] == comps[n])
//			}
//		}
//		
//		do {
//			let s = "/user/{id}/do////*//it/"
//			let a = ["/", "user","{id}","do","*","it", "/"]
//			
//			let comps = s.pathComponents(true)
//			
//			for n in 0..<a.count {
//				XCTAssert(a[n] == comps[n])
//			}
//		}
//		
//	}
	
	func testStringLastComponent() {
		XCTAssert("/a/".lastPathComponent == "a")
		XCTAssert("/b/a".lastPathComponent == "a")
		XCTAssert("/".lastPathComponent == "/")
	}
	
	func testStringByDeletingLastPathComponent() {
		XCTAssert("/a/".stringByDeletingLastPathComponent == "/")
		XCTAssert("/b/a".stringByDeletingLastPathComponent == "/b/")
		XCTAssert("/".stringByDeletingLastPathComponent == "/")
	}
	
	func testPathComponentsExPerformance() {
		let s = "/foo/bar/baz/bilbo/bucket/salami"
		self.measureBlock {
			
			for _ in 0..<100000 {
				s.pathComponents.count
			}
			
		}
	}
	
	func testPathComponentsNatPerformance() {
		let s = "/foo/bar/baz/bilbo/bucket/salami" as NSString
		self.measureBlock {
			
			for _ in 0..<100000 {
				s.pathComponents.count
			}
			
		}
	}
	
	func testPathComponentsSplitPerformance() {
		let s = "/foo/bar/baz/bilbo/bucket/salami"
		self.measureBlock {
			
			for _ in 0..<100000 {
				s.characters.split(Character("/")).map { String($0) } .count
			}
			
		}
	}
}













