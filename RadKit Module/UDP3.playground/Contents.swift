import Network
import Foundation
import PlaygroundSupport

class Main {

    init() {
        let connection = NWConnection(host: "192.168.1.39", port: 56792, using: .udp)
        self.connection = connection
    }

    let connection: NWConnection

    func start() {
        // Start the connection.
        connection.stateUpdateHandler = self.stateDidChange(to:)
        connection.start(queue: .main)
        self.setupReceive(connection)
        // Start the send timer.
        let sendTimer = DispatchSource.makeTimerSource(queue: .main)
        sendTimer.setEventHandler(handler: self.send)
        sendTimer.schedule(deadline: .now(), repeating: 1.0)
        sendTimer.resume()
        self.sendTimer = sendTimer
    }

    var sendTimer: DispatchSourceTimer?

    func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .setup:
            break
        case .waiting(let error):
            self.connectionDidFail(error: error)
        case .preparing:
            print("Preparing")
        case .ready:
            print("Connected")
        case .failed(let error):
            self.connectionDidFail(error: error)
        case .cancelled:
            break
        }
    }

    func send() {
        let messageID = UUID()
        self.connection.send(content: "\(messageID)\r\n".data(using: .utf8)!, completion: .contentProcessed({ sendError in
            if let error = sendError {
                self.connectionDidFail(error: error)
            } else {
                print("Did send, messageID: \(messageID)")
            }
        }))
    }

    func setupReceive(_ connection: NWConnection) {
        connection.receiveMessage { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                print("Did receive, size: \(data.count)")
            }
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            self.setupReceive(connection)
        }
    }

    func connectionDidFail(error: Error) {
        print("Failed, error: \(error)")
        if connection.stateUpdateHandler != nil {
            self.connection.stateUpdateHandler = nil
            connection.cancel()
        }
        exit(0)
    }
}

PlaygroundPage.current.needsIndefiniteExecution = true
let m = Main()
m.start()

