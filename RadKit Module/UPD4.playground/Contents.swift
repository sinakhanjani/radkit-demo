import UIKit

var greeting = "Hello, playground"
import Foundation

extension sockaddr_storage {

    // not actually in Socket API Helper, but an 'obvious' extension

    init(sa: UnsafeMutablePointer<sockaddr>, saLen: socklen_t) {
        var ss = sockaddr_storage()
        withUnsafeMutableBytes(of: &ss) { ssPtr -> Void in
            let addrBuf = UnsafeRawBufferPointer(start: sa, count: Int(saLen))
            assert(addrBuf.count <= MemoryLayout<sockaddr_storage>.size)
            ssPtr.copyMemory(from: addrBuf)
        }
        self = ss
    }

    // from Socket API Helper

    static func fromSockAddr<ReturnType>(_ body: (_ sa: UnsafeMutablePointer<sockaddr>, _ saLen: inout socklen_t) throws -> ReturnType) rethrows -> (ReturnType, sockaddr_storage) {
        // We need a mutable `sockaddr_storage` so that we can pass it to `withUnsafePointer(to:_:)`.
        var ss = sockaddr_storage()
        // Similarly, we need a mutable copy of our length for the benefit of `saLen`.
        var saLen = socklen_t(MemoryLayout<sockaddr_storage>.size)
        let result = try withUnsafeMutablePointer(to: &ss) {
            try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                try body($0, &saLen)
            }
        }
        return (result, ss)
    }

    // from Socket API Helper

    func withSockAddr<ReturnType>(_ body: (_ sa: UnsafePointer<sockaddr>, _ saLen: socklen_t) throws -> ReturnType) rethrows -> ReturnType {
        // We need to create a mutable copy of `self` so that we can pass it to `withUnsafePointer(to:_:)`.
        var ss = self
        return try withUnsafePointer(to: &ss) {
            try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                try body($0, socklen_t(self.ss_len))
            }
        }
    }
}

func addressesFor(host: String, port: Int) throws -> [sockaddr_storage] {
    var hints = addrinfo()
    hints.ai_socktype = SOCK_DGRAM
    var addrList: UnsafeMutablePointer<addrinfo>? = nil
    let err = getaddrinfo(host, "\(port)", &hints, &addrList)
    guard err == 0, let start = addrList else {
        throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost, userInfo: nil)
    }
    defer { free(addrList) }
    return sequence(first: start, next: { $0.pointee.ai_next} ).map { (addr) -> sockaddr_storage in
        sockaddr_storage(sa: addr.pointee.ai_addr, saLen: addr.pointee.ai_addrlen)
    }
}

func sendExample() {
    guard let addresses = try? addressesFor(host: "192.168.1.39", port: 56792) else {
        print("host not found")
        return
    }
    if addresses.count != 1 {
        print("host ambiguous; using the first one")
    }
    let address = addresses[0]
    let fd = socket(Int32(address.ss_family), SOCK_DGRAM, 0)
    guard fd >= 0 else {
        print("`socket` failed`")
        return
    }
    defer {
        let junk = close(fd)
        assert(junk == 0)
    }
    let message = "Hello Cruel World!\r\n\(Date())\r\n".data(using: .utf8)!
    let messageCount = message.count
    let sendResult = message.withUnsafeBytes { (messagePtr: UnsafePointer<UInt8>) -> Int in
        return address.withSockAddr { (sa, saLen) -> Int in
            return sendto(fd, messagePtr, messageCount, 0, sa, saLen)
        }
    }
    guard sendResult >= 0 else {
        print("send failed")
        return
    }
    print("success")
}

sendExample()
