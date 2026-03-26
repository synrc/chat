import Foundation
import MQTTNIO
import SwiftASN1
import NIO

// Helper to flush stdout for prompt
func fflush(_ stream: UnsafeMutablePointer<FILE>) {
    // Stub
}

public class RelayClient {
    public static let shared = RelayClient()
    
    var client: MQTTClient?
    var nickname: String?
    
    public init() {}
    
    public func login(nickname: String) throws {
        self.nickname = nickname
        let client = MQTTClient(
            host: "localhost",
            port: 1883,
            identifier: nickname,
            eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton)
        )
        self.client = client
        
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            do {
                try await client.connect()
                print(": Connected to Relay as \(nickname)")
                
                // Subscribe to own user topic
                let topic = "user/\(nickname)"
                _ = try await client.subscribe(to: [MQTTSubscribeInfo(topicFilter: topic, qos: .atLeastOnce)])
                print(": Subscribed to \(topic)")
                
                // Start listener
                self.setupListener()
                
                semaphore.signal()
            } catch {
                print(": Login Failed: \(error)")
                semaphore.signal()
            }
        }
        semaphore.wait()
    }
    
    func setupListener() {
        guard let client = client else { return }
        
        client.addPublishListener(named: "RelayListener") { result in
            switch result {
            case .success(let packet):
                let topic = packet.topicName
                var payload = packet.payload
                let bytes = payload.readBytes(length: payload.readableBytes) ?? []
                self.handleMessage(topic: topic, bytes: bytes)
            case .failure(let error):
                print("MQTT Error: \(error)")
            }
        }
    }
    
    func handleMessage(topic: String, bytes: [UInt8]) {
        // Decode ASN.1
        do {
            // 1. Try Decode Protocol Direct (Server style)
            // Note: Server re-publishes the payload. If we send Protocol, we receive Protocol.
            let protocolMsg = try CHAT_Protocol(derEncoded: bytes)
            // let envelope = try CHAT_Envelope(derEncoded: bytes)
            // let protocolMsg = envelope.body
            
            switch protocolMsg {
            case .message(let msg):
                 // msg is CHAT_Message (13-fields)
                 // .bytes access for ASN1OctetString
                 if let src = String(bytes: msg.from.bytes, encoding: .utf8),
                    let text = try? extractText(from: msg) {
                     print("\nFROM \(src): \(text)")
                     print("> ", terminator: "")
                     fflush(stdout)
                 } else {
                     print("\nMSG: \(msg)")
                 }
            default:
                print("\nRECV: \(protocolMsg)")
            }
        } catch {
            print("\nDecode Error on \(topic): \(error)")
        }
    }
    
    func extractText(from msg: CHAT_Message) throws -> String? {
        // Look in files for text/plain
        for file in msg.files {
           if let mime = String(bytes: file.mime.bytes, encoding: .utf8), mime == "text/plain" {
               // Payload is ASN1Any. We need to unwrap it.
               // Serialize ANY to get raw bytes (TLV)
               var serializer = DER.Serializer()
               try file.payload.serialize(into: &serializer)
               let rawBytes = serializer.serializedBytes
               
               // Decode OCTET STRING from those bytes
               if let octet = try? ASN1OctetString(derEncoded: rawBytes) {
                   return String(bytes: octet.bytes, encoding: .utf8)
               }
           }
        }
        return nil
    }
    
    public func send(to: String, text: String) throws {
        guard let client = client, let nick = nickname else {
            print(": Not logged in.")
            return
        }
        
        // 1. Construct FileDesc with text
        let textBytes = Array(text.utf8)
        let textOctet = ASN1OctetString(contentBytes: ArraySlice(textBytes))
        var serializer = DER.Serializer()
        try textOctet.serialize(into: &serializer)
        let payloadAny = try ASN1Any(derEncoded: serializer.serializedBytes)
        
        let file = CHAT_FileDesc(
            id: ASN1OctetString(contentBytes: ArraySlice(UUID().uuidString.data(using: .utf8)!)), 
            mime: ASN1OctetString(contentBytes: ArraySlice("text/plain".utf8)), 
            payload: payloadAny, 
            parentid: ASN1OctetString(contentBytes: []), 
            data: []
        )
        
        // 2. Feed P2P
        let p2p = CHAT_P2P(
            src: ASN1OctetString(contentBytes: ArraySlice(nick.utf8)), 
            dst: ASN1OctetString(contentBytes: ArraySlice(to.utf8))
        )
        
        // 3. Message
        let msg = CHAT_Message(
            id: ASN1OctetString(contentBytes: ArraySlice(UUID().uuidString.data(using: .utf8)!)),
            feed_id: CHAT_Message_feed_id_Choice.p2p(p2p),
            signature: ASN1OctetString(contentBytes: []),
            from: ASN1OctetString(contentBytes: ArraySlice(nick.utf8)),
            to: ASN1OctetString(contentBytes: ArraySlice(to.utf8)),
            created: [0], 
            files: [file],
            type: CHAT_MessageType.sys, 
            link: [0],
            seenby: ASN1OctetString(contentBytes: []),
            repliedby: ASN1OctetString(contentBytes: []),
            mentioned: [],
            status: CHAT_MessageStatus(rawValue: 1) // async
        )
        
        // 4. Wrap in CHAT_Protocol
        let proto = CHAT_Protocol.message(msg)
        
        // 5. Wrap in CHAT_Envelope (SKIPPED - Server expects Protocol)
        // let envelope = CHAT_Envelope(
        //     no: [1], 
        //     headers: [],
        //     body: proto
        // )
        
        // 6. Encode Protocol Directly
        serializer = DER.Serializer()
        try proto.serialize(into: &serializer)
        let data = serializer.serializedBytes
        
        // 7. Publish
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            _ = try await client.publish(
                to: "relay/ingress",
                payload: ByteBuffer(bytes: data),
                qos: .atLeastOnce
            )
            print(": Sent.")
            semaphore.signal()
        }
        semaphore.wait()
    }
    
    public func logout() {
         guard let client = client else { return }
         Task {
             try? await client.disconnect()
         }
         self.client = nil
         print(": Logged out.")
    }
}
