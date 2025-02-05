
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
    
    func connectToUDPAndSend(completion: @escaping (_ ipAddress: NWEndpoint.Host?,_ port: NWEndpoint.Port?,_ data: Data?) -> Void) -> iOS13UDP {
        // Transmited message:
        self.connection = NWConnection(host: hostUDP, port: portUDP, using: .udp)
        self.connection?.stateUpdateHandler = { [weak self] (newState) in
            guard let self = self else { return }
            switch (newState) {
            case .ready:
                self.sendUDP()
                self.receiveUDP { udpData in
                    if let udpData = udpData {
                        completion(self.hostUDP, self.portUDP, udpData)
                    } else {
                        completion(nil, nil, nil)
                    }
                }
            case .setup:
                completion(nil, nil, nil)
                break
            case .cancelled:
                completion(nil, nil, nil)
                break
            case .preparing:
                completion(nil, nil, nil)
                break
            default:
                completion(nil, nil, nil)
                break
            }
        }
        
        connection!.start(queue: .global())
        
        return self
    }
    
    func sendUDP() {
        connection?.send(content: content, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                print("Data was sent to UDP")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
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
                }
            } else {
                completion(nil)
            }
        }
    }
    
    static func fullScanUDP(fullScanData: Data, port: NWEndpoint.Port, completion: @escaping (_ ipAddress: String?,_ port: Int?,_ data: Data?) -> Void) {
        for ip in 1..<255 {
            let ip_add = "192.168.1.\(ip)"
            iOS13UDP(hostUDP: NWEndpoint.Host(ip_add), portUDP: port, content: fullScanData)
                .connectToUDPAndSend { ip,port,data in
                    print(ip,port,data)
                    completion("\(ip)",Int("\(port)"),data)
                }
        }
    }
}

