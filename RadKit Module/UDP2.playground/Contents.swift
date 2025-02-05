import UIKit
import Network

@available(iOS 12.0, *)
class iOS13UDP {
    var connection: NWConnection?
    var hostUDP: NWEndpoint.Host
    var portUDP: NWEndpoint.Port
    var content: Data
    
    init(hostUDP: NWEndpoint.Host, portUDP: NWEndpoint.Port, content: Data) {
        self.hostUDP = hostUDP
        self.portUDP = portUDP
        self.content = content
    }

    func connectToUDPAndSend(completion: @escaping (_ ipAddress: NWEndpoint.Host,_ port: NWEndpoint.Port,_ data: Data) -> Void) -> iOS13UDP {
        // Transmited message:
        self.connection = NWConnection(host: hostUDP, port: portUDP, using: .udp)
        self.connection?.stateUpdateHandler = { (newState) in
//            print("This is stateUpdateHandler:")
            switch (newState) {
                case .ready:
//                    print("State: Ready\n")
                self.sendUDP()
                self.receiveUDP { udpData in
                    if let udpData = udpData {
                        print("FOUND:",udpData.bytes)
                        completion(self.hostUDP, self.portUDP, udpData)
                    }
                }
                case .setup: break
//                    print("State: Setup\n")
                case .cancelled: break
//                    print("State: Cancelled\n")
                case .preparing: break
//                    print("State: Preparing\n")
                default: break
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
                print("Receive is complete")
                if (data != nil) {
                    completion(data)
                } else {
                    completion(nil)
                    print("Data == nil")
                }
            }
        }
    }

    static func fullScanUDP(fullScanData: Data, port: NWEndpoint.Port, completion: @escaping (_ ipAddress: String,_ port: Int,_ data: Data) -> Void) {
        for ip in 2..<255 {
            let ip_add = "192.168.1.\(ip)"
            iOS13UDP(hostUDP: NWEndpoint.Host(ip_add), portUDP: port, content: fullScanData)
                .connectToUDPAndSend { ip,port,data in
                        completion("\(ip)",Int("\(port)")!,data)
                }
        }
    }
}








func encryptByte(input:String, key:UInt8) -> Data {
    var inputBytes: [UInt8] = Array(input.utf8).map { $0^key }
    let nsdata = NSData(bytes: &inputBytes, length: inputBytes.count)
    let data = Data.init(referencing: nsdata)
    return data
}

func decryptByte(data:Data, key:UInt8) -> String? {
    let bytes = data.bytes
    let inputBytes: [UInt8] = bytes.map { $0^key }
    guard let utf8String = String.init(bytes: inputBytes, encoding: .utf8) else {
        return nil
    }
    return utf8String
}

extension Data {
    var bytes : [UInt8] {
        return [UInt8](self)
    }
}


extension String {
    
    func scan(components:String,split:String) -> [String] {
        let strArray = components.components(separatedBy: split)
        print("scan is complete in: \n\(strArray) numbers")
        
        return strArray
    }
    
}


let data = encryptByte(input: "rad", key: 155)
//iOS13UDP(hostUDP: "192.168.1.39", portUDP: 56792, content: data)
//    .connectToUDPAndSend { ip,port,data in
//        if let item = decryptByte(data: data, key: 155) {
//            let scan = item.scan(components: item, split: ":")
//            print(scan)
//        }
//
//    }
//
iOS13UDP.fullScanUDP(fullScanData: data, port: 56792) { ipAddress, port, data in
    print("FOUND:",data,port,ipAddress)
}
