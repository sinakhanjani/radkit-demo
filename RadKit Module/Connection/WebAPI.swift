//
//  WebAPI.swift
//  Master
//
//  Created by Sinakhanjani on 10/27/1397 AP.
//  Copyright © 1397 iPersianDeveloper. All rights reserved.
//

import AVKit
import SystemConfiguration
import Reachability

class WebAPI {
    static let instance = WebAPI()
    
    typealias completion = (_ status: Constant.Alert) -> Void
    private let baseURL = URL(string: "")! //"http://radkit.ir/users
    private let baseURL2 = URL(string: "")!

    var isNetworkAvailable : Bool {
        return reachabilityStatus != .none
    }
    // 4. Tracks current NetworkStatus (notReachable, reachableViaWiFi, reachableViaWWAN)
    var reachabilityStatus: Reachability.Connection = .none
    // 5. Reachability instance for Network status monitoring
    let reachability = Reachability()!

    func sendSMS(photo: Data?,parameter: [String: String]?, completion: @escaping (_ data: String?) -> Void) {
        let url = baseURL.appendingPathComponent("request_sms.php")
        var request = URLRequest.init(url: url)
        request.httpMethod = "POST"
        let boundary = generateBoundary()
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let dataBody = createDataBody(withParameters: parameter, media: photo, boundary: boundary, photoKey: "setfile")
        request.httpBody = dataBody
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(nil)
                return
            }
            guard let data = data else { completion(nil) ; return }
            guard let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]) as [String : Any]??) else { completion(nil) ; return }
            print("json",json)
            completion(json?["message"] as? String)
        }
        task.resume()
    }
    
    func sendEmail(photo: Data?,parameter: [String: String]?, completion: @escaping (_ data: String?) -> Void) {
        let url = baseURL.appendingPathComponent("request_email.php")
        var request = URLRequest.init(url: url)
        request.httpMethod = "POST"
        let boundary = generateBoundary()
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let dataBody = createDataBody(withParameters: parameter, media: photo, boundary: boundary, photoKey: "setfile")
        request.httpBody = dataBody
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(nil)
                return
            }
            guard let data = data else { completion(nil) ; return }
            guard let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]) as [String : Any]??) else { completion(nil) ; return }
            print("json",json)
            completion(json?["message"] as? String)
        }
        task.resume()
    }
    
    func verifySMS(photo: Data?,parameter: [String: String]?, completion: @escaping (_ data: Respo?) -> Void) {
        let url = baseURL.appendingPathComponent("verify_otp.php")
        var request = URLRequest.init(url: url)
        request.httpMethod = "POST"
        let boundary = generateBoundary()
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let dataBody = createDataBody(withParameters: parameter, media: photo, boundary: boundary, photoKey: "setfile")
        request.httpBody = dataBody
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(nil)
                return
            }
            guard let data = data else {  completion(nil) ; return }
            print(String(data: data, encoding: .utf8))
            let decoder = JSONDecoder()
            if let res = try? decoder.decode(Respo.self, from: data) {
                completion(res)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
    
    func backup(photo: Data?,parameter: [String: String]?, completion: @escaping (_ data: String?) -> Void) {
        let url = baseURL.appendingPathComponent("upload.php")
        var request = URLRequest.init(url: url)
        request.httpMethod = "POST"
        let boundary = generateBoundary()
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let dataBody = createDataBody(withParameters: parameter, media: photo, boundary: boundary, photoKey: "setfile")
        request.httpBody = dataBody
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(nil)
                return
            }
            guard let data = data else { completion(nil) ; return }
            guard let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]) as [String : Any]??) else { completion(nil) ; return }
            if let _ = json?["error"] as? Bool {
                completion(json?["message"] as? String)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
    
    func share(photo: Data?,parameter: [String: String]?, completion: @escaping (_ data: String?) -> Void) {
        let url = baseURL.appendingPathComponent("share.php")
        var request = URLRequest.init(url: url)
        request.httpMethod = "POST"
        let boundary = generateBoundary()
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let dataBody = createDataBody(withParameters: parameter, media: photo, boundary: boundary, photoKey: "setfile")
        request.httpBody = dataBody
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(nil)
                return
            }
            guard let data = data else {  completion(nil) ; return }
            guard let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]) as [String : Any]??) else { completion(nil) ; return }
            if let _ = json?["error"] as? Bool {
                completion(json?["message"] as? String)
            } else {
                completion(nil)
            }
            
        }
        task.resume()
    }
    
    func delete(photo: Data?,parameter: [String: String]?, completion: @escaping (_ data: String?) -> Void) {
        let url = baseURL.appendingPathComponent("delete.php")
        var request = URLRequest.init(url: url)
        request.httpMethod = "POST"
        let boundary = generateBoundary()
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let dataBody = createDataBody(withParameters: parameter, media: photo, boundary: boundary, photoKey: "setfile")
        request.httpBody = dataBody
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(nil)
                return
            }
            guard let data = data else {  completion(nil) ; return }
            guard let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]) as [String : Any]??) else { completion(nil) ; return }
            if let _ = json?["error"] as? Bool {
                completion(json?["message"] as? String)
            } else {
                completion(nil)
            }
            
        }
        task.resume()
    }
    
    func download(photo: Data?,parameter: [String: String]?, completion: @escaping (_ data: [String:Any]?) -> Void) {
        let url = baseURL.appendingPathComponent("get_backup.php")
        var request = URLRequest.init(url: url)
        request.httpMethod = "POST"
        let boundary = generateBoundary()
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let dataBody = createDataBody(withParameters: parameter, media: photo, boundary: boundary, photoKey: "setfile")
        request.httpBody = dataBody
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(nil)
                return
            }
            guard let data = data else {  completion(nil) ; return }
            guard let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]) as [String : Any]??) else { completion(nil) ; return }
            completion(json)
        }
        task.resume()
    }
    
    func getList(photo: Data?,parameter: [String: String]?, completion: @escaping (_ data: [String]?) -> Void) {
        let url = baseURL.appendingPathComponent("get_backups_list.php")
        var request = URLRequest.init(url: url)
        request.httpMethod = "POST"
        let boundary = generateBoundary()
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let dataBody = createDataBody(withParameters: parameter, media: photo, boundary: boundary, photoKey: "setfile")
        request.httpBody = dataBody
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(nil)
                return
            }
            guard let data = data else {  completion(nil) ; return }
            guard let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]) as [String : Any]??) else { completion(nil) ; return }
            if let backups = json?["backups"] as? [String] {
                completion(backups)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
    
    func getNotificationStatus(completion: @escaping (_ data: NotificationStatus?) -> Void) {
        guard !Authentication.auth.token.isEmpty else { completion(nil) ; return }
        let url = baseURL2.appendingPathComponent("/apps/\(Authentication.auth.token)")
        var request = URLRequest.init(url: url)
        request.httpMethod = "GET"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(nil)
                return
            }
            let decoder = JSONDecoder()
            guard let data = data else { completion(nil) ; return }
            guard let json = try? decoder.decode(NotificationStatus.self, from: data) else { completion(nil) ; return }
            completion(json)
            
        }
        task.resume()
    }
    
    func changeNotificationStatus(status: Bool, completion: @escaping (_ data: NotificationStatus?) -> Void) {
        guard !Authentication.auth.token.isEmpty else { completion(nil) ; return }
        // MARK: - Send
        struct Send: Codable {
            let fcmID, customID, packageName: String
            let enablePush: Bool
            
            enum CodingKeys: String, CodingKey {
                case fcmID = "fcm_id"
                case customID = "custom_id"
                case packageName = "package_name"
                case enablePush = "enable_push"
            }
        }
        
        let url = baseURL2.appendingPathComponent("/apps")
        var request = URLRequest.init(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        request.httpBody = try? encoder.encode(Send(fcmID: Authentication.auth.token, customID: "", packageName: "com.iPersianDeveloper.radKit", enablePush: status))
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(nil)
                return
            }
            let decoder = JSONDecoder()
            
            guard let data = data else { completion(nil) ; return }
            guard let json = try? decoder.decode(NotificationStatus.self, from: data) else {
                completion(nil)
                return
            }
            completion(json)
        }
        task.resume()
    }
    
    func getNotifications(sn: String,completion: @escaping (_ data: RadkitNotification?) -> Void) {
        let url = baseURL2.appendingPathComponent("/notify/user").withQuries(["sn":sn,"user_key":Authentication.auth.token])!
        
        print(url)
        
        var request = URLRequest.init(url: url)
        
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(nil)
                return
            }
            let decoder = JSONDecoder()
            guard let data = data else { completion(nil) ; return }
            guard let json = try? decoder.decode(RadkitNotification.self, from: data) else {
                completion(nil)
                return
            }
            completion(json)
        }
        task.resume()
    }
    
    func postNotification(serial: String,intToken: String,selectedInputs: Int,inputsName: String,isPushEnable: Bool, isSMSEnable: Bool,completion: @escaping (_ data: RadkitNotification?) -> Void) {
        
        let url = baseURL2.appendingPathComponent("/notify")
        var request = URLRequest.init(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        let send = RadkitNotification(userKey: Authentication.auth.token, packageName: "com.iPersianDeveloper.radKit", fcmID: AppDelegate.fcmToken, serialNumber: serial, inetToken: intToken, selectedInputs: selectedInputs, inputNames: inputsName, phoneNumber: Authentication.auth.mobile, enablePush: isPushEnable, enableSMS: isSMSEnable, id: nil)
        print(send)
        request.httpBody = try? encoder.encode(send)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completion(nil)
                return
            }
            
            let decoder = JSONDecoder()
            guard let data = data else {  completion(nil) ; return }
            guard let json = try? decoder.decode(RadkitNotification.self, from: data) else {
                completion(nil)
                return
            }
            completion(json)
        }
        task.resume()
    }
    
    /////// /////// /////// //////
    private func generateBoundary() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    private func createDataBody(withParameters parameters: [String: String]?, media: Data?, boundary: String, photoKey: String?) -> Data {
        let lineBreak = "\r\n"
        var body = Data()
        if let parameters = parameters {
            for (key,value) in parameters {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
                body.append("\(value + lineBreak)")
            }
        }
        if let media = media, let photoKey = photoKey {
            body.append("--\(boundary + lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(photoKey)\"; filename=\"\("\(arc4random())" + ".json")\"\(lineBreak)")
            body.append("Content-Type: \(".json" + lineBreak + lineBreak)")
            body.append(media)
            body.append(lineBreak)
        }
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
    
    private func getOSInfo() -> String {
        let os = ProcessInfo().operatingSystemVersion
        return String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion)
    }
    
    private func getPlatformNSString() -> String {
#if (arch(i386) || arch(x86_64)) && os(iOS)
        let DEVICE_IS_SIMULATOR = true
#else
        let DEVICE_IS_SIMULATOR = false
#endif
        var machineSwiftString : String = ""
        if DEVICE_IS_SIMULATOR == true
        {
            // this neat trick is found at http://kelan.io/2015/easier-getenv-in-swift/
            if let dir = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                machineSwiftString = dir
                return machineSwiftString
            }
        } else {
            var size : size_t = 0
            sysctlbyname("hw.machine", nil, &size, nil, 0)
            var machine = [CChar](repeating: 0, count: Int(size))
            sysctlbyname("hw.machine", &machine, &size, nil, 0)
            machineSwiftString = String.init(cString: machine)
            return machineSwiftString
            
        }
        print("machine is \(machineSwiftString)")
        return machineSwiftString
    }
}

extension WebAPI {
    func startMonitoring() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changConnectionCallBack),
                                               name: Notification.Name.reachabilityChanged,
                                               object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print(error)
        }
    }

    @objc func changConnectionCallBack(notification: Notification) {
        print("-ReachabilityChanged:", WebAPI.instance.reachability.connection)
        if PresentManager.shared.firtOpen {
            PresentManager.shared.firtOpen = false
        } else {
            AppDelegate.reluanchApplication()
        }
    }
}

enum Network {
    case wifi
    case cellular
    case unavailable
}
