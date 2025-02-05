
import UIKit
import Network
@available(iOS 12.0, *)
class iOS13UDP {
    var connection: NWConnection?
    var hostUDP: NWEndpoint.Host
    var portUDP: NWEndpoint.Port
    var content: Data
    
    static var udpConnections = [iOS13UDP]()
    
    init(hostUDP: NWEndpoint.Host, portUDP: NWEndpoint.Port, content: Data) {
        self.hostUDP = hostUDP
        self.portUDP = portUDP
        self.content = content
    }

    func connectToUDPAndSend(completion: @escaping (_ ipAddress: NWEndpoint.Host,_ port: NWEndpoint.Port,_ data: Data) -> Void) -> iOS13UDP {
        // Transmited message:
        self.connection = NWConnection(host: hostUDP, port: portUDP, using: .udp)
        self.connection?.stateUpdateHandler = { [weak self] (newState) in
            guard let self = self else { return }
//            print("This is stateUpdateHandler:")
            switch (newState) {
                case .ready:
//                    print("State: Ready UDP\n")
                self.sendUDP()
                self.receiveUDP { udpData in
                    if let udpData = udpData {
                        completion(self.hostUDP, self.portUDP, udpData)
                    }
                }
                case .setup: break
//                    print("State: Setup\n")
                case .cancelled:break
//                    print("State: Cancelled\n")
                case .preparing:break
//                    print("State: Preparing\n")
                default:break
//                    print("ERROR! State not defined!\n")
            }
        }

        connection?.start(queue: .global())
        
        return self
    }

    func sendUDP() {
        connection?.send(content: content, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
//                print("Data was sent to UDP")
            } else {
//                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
    }

    func receiveUDP(completion: @escaping (_ data: Data?) -> Void) {
        connection?.receiveMessage { (data, context, isComplete, error) in
            if (isComplete) {
                if (data != nil) {
                    completion(data)
                } else {
                    completion(nil)
//                    print("Data == nil")
                }
            }
        }
    }

    static func fullScanUDP(fullScanData: Data, port: NWEndpoint.Port, completion: @escaping (_ ipAddress: String,_ port: Int,_ data: Data) -> Void) {
        guard iOS13UDP.udpConnections.isEmpty else { return }
        guard let array = getIPAddress()?.split(separator: ".") else { return }
        guard array.count == 4 else { return }
        print("connection address: \(array)")
        for ip in 1..<255 {
            let ip_add = "\(String(array[0])).\(String(array[1])).\(String(array[2])).\(ip)"
            let connection = iOS13UDP(hostUDP: NWEndpoint.Host(ip_add), portUDP: port, content: fullScanData)
                .connectToUDPAndSend { ip,port,data in
                        completion("\(ip)",Int("\(port)")!,data)
                }
            self.udpConnections.append(connection)
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            for (index,_) in iOS13UDP.udpConnections.enumerated() {
                iOS13UDP.udpConnections[index].connection?.cancel()
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+1.3) {
                iOS13UDP.udpConnections.removeAll()
            }
        }
    }
    
    static func getIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                guard let interface = ptr?.pointee else { return "" }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                    // wifi = ["en0"]
                    // wired = ["en2", "en3", "en4"]
                    // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]

                    let name: String = String(cString: (interface.ifa_name))
                    if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }

}
