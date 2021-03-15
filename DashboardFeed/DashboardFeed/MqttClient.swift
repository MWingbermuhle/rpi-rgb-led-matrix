//
//  MqttClient.swift
//  DashboardFeed
//
//  Created by Maurice Wingbermühle on 12/03/2021.
//

import Foundation
import CocoaMQTT

class MqttClient {
    var cocoaMqtt = CocoaMQTT(clientID: "DashboardFeeder", host: "klaverstraat11.local", port: 1883)
    var listener : MqttClientListener? = nil
    
    func connect() {
        _ = cocoaMqtt.connect()
    }
    
    func disconnect() {
        cocoaMqtt.disconnect()
    }
    
    func sendBranchUpdate(index: Int, name: String, status: String) {
        var message = CocoaMQTTMessage(topic: "DashboardFeed/branch/\(index)/name", string: name)
        cocoaMqtt.publish(message)
        message = CocoaMQTTMessage(topic: "DashboardFeed/branch/\(index)/status", string: status)
        cocoaMqtt.publish(message)
    }
    
}

protocol MqttClientListener {
    func connected()
    
    func disconnected()
}

extension MqttClient : CocoaMQTTDelegate {
    
    // Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        TRACE("trust: \(trust)")
        /// Validate the server certificate
        ///
        /// Some custom validation...
        ///
        /// if validatePassed {
        ///     completionHandler(true)
        /// } else {
        ///     completionHandler(false)
        /// }
        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        TRACE("ack: \(ack)")

        if ack == .accept {
            // TODO subscribe?
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        TRACE("new state: \(state)")
        switch state {
        case .connected:
            listener?.connected()
        case .disconnected:
            listener?.disconnected()
        default:
            TRACE("state \(state) ignored")
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message: \(String(describing: message)), id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        TRACE("id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        TRACE("message: \(String(describing: message)), id: \(id)")

        let name = NSNotification.Name(rawValue: "MQTTMessageNotification")
        NotificationCenter.default.post(name: name, object: self, userInfo: ["message": message.string!, "topic": message.topic])
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        TRACE("subscribed: \(success), failed: \(failed)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        TRACE("topic: \(topics)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        TRACE()
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        TRACE()
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        TRACE("\(String(describing: err))")
    }
}

extension MqttClient {
    fileprivate func TRACE(_ message: String = "", fun: String = #function) {
        let names = fun.components(separatedBy: ":")
        var prettyName: String
        if names.count == 2 {
            prettyName = names[0]
        } else {
            prettyName = names[1]
        }
        
        if fun == "mqttDidDisconnect(_:withError:)" {
            prettyName = "didDisconnect"
        }

        print("[TRACE] [\(prettyName)]: \(message)")
    }
}
