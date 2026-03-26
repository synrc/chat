import SwiftASN1
import Crypto
import CoreFoundation
import Foundation

public class Cmd {

  public static func exists(f: String) -> Bool { return FileManager.default.fileExists(atPath: f) }

  public static func nop() { print(">", terminator: " ") }
/*
  public static func showKDF(data: Array<String>) throws {
     let x = KDF.derive(alg: "sha512", key: Data([0,1,2,3,4]),
                        len: 20, data: Data([100,101,102,103,104]))
     var serializer = DER.Serializer()
     print(": KDF \(Array(x))")
  }

  public static func showK(data: Array<String>) throws {
      let k: K? = try K(derEncoded: [48,10,49,8,48,6,48,4,2,2,1,1])
     if let k { print(": k \(k)") }
     var serializer = DER.Serializer()
     try k!.serialize(into: &serializer)
     print(": DER.k \(serializer.serializedBytes)")
  }
*/
  public static func showName(data: Array<String>) throws {
     let name: Name? = try Name(derEncoded: [48,13,49,11,48,9,6,3,85,4,6,19,2,85,65])
     if let name { print(": name \(name)") }
     var serializer = DER.Serializer()
     try name!.serialize(into: &serializer)
     print(": DER.name \(serializer.serializedBytes)")
  }
/*
  public static func showA(data: Array<String>) throws {
// V 12
// > io:format("~p~n",['List':encode('V',{'V',[1],[2],3,4,true,true,[5],[6],7,0,<<"HELO">>,true})]).
// {ok,<<48,57,161,3,2,1,1,162,5,49,3,2,1,2,131,1,3,164,3,2,1,4,133,1,255,166,3,
//      1,1,255,167,3,2,1,5,168,5,49,3,2,1,6,137,1,7,160,3,2,1,0,4,4,72,69,76,
//      79,1,1,255>>}

// K 8
// > io:format("~p~n",['List':encode('K',{'K',v1,1,{k_y,true,true,7,0},[[[[[[[[1,2,3],[4,5,6]],[[1]]]]]]]]})]).
// {ok,<<48,63,2,1,1,2,1,1,48,12,1,1,255,1,1,255,2,1,7,2,1,0,49,41,48,39,49,37,
//      48,35,49,33,48,31,49,22,48,9,2,1,1,2,1,2,2,1,3,48,9,2,1,4,2,1,5,2,1,6,
//      49,5,48,3,2,1,1>>}

// K 8
// > io:format("~p~n",['List':encode('K',{'K',v1,1,{k_y,true,true,7,0},[[[[[[[[1]]]]]]]]})]).
// {ok,<<48,39,2,1,1,2,1,1,48,12,1,1,255,1,1,255,2,1,7,2,1,0,49,17,48,15,49,13,
//       48,11,49,9,48,7,49,5,48,3,2,1,1>>}

// K 2
// > io:format("~p~n",['List':encode('K',{'K',v1,1,{k_y,true,true,7,0},[[1]]})]).
// {ok,<<48,27,2,1,1,2,1,1,48,12,1,1,255,1,1,255,2,1,7,2,1,0,49,5,48,3,2,1,1>>}

// K 3
// > io:format("~p~n",['List':encode('K',{'K',v1,1,{k_y,true,true,7,0},[[[1]]]})]).
// {ok,<<48,27,2,1,1,2,1,1,48,12,1,1,255,1,1,255,2,1,7,2,1,0,49,5,48,3,2,1,1>>}

// K 4
// >  io:format("~p~n",['List':encode('K',{'K',v1,1,{k_y,true,true,7,0},[[[[1]]]]})]).
// {ok,<<48,31,2,1,1,2,1,1,48,12,1,1,255,1,1,255,2,1,7,2,1,0,49,9,48,7,49,5,48,3,2,1,1>>}

     let k2: K? = try K(derEncoded: [48,27,2,1,1,2,1,1,48,12,1,1,255,1,1,255,2,1,7,2,1,0,49,5,48,3,2,1,1])
//     let k3: K? = try K(derEncoded: [48,29,2,1,1,2,1,1,48,12,1,1,255,1,1,255,2,1,7,2,1,0,49,7,48,5,49,3,2,1,1])
//     let k4: K? = try K(derEncoded: [48,31,2,1,1,2,1,1,48,12,1,1,255,1,1,255,2,1,7,2,1,0,49,9,48,7,49,5,48,3,2,1,1])
     let xx: V? = try V(derEncoded: [48,57,161,3,2,1,1,162,5,49,3,2,1,2,131,1,3,164,3,2,1,4,133,1,255,166,3,
                                     1,1,255,167,3,2,1,5,168,5,49,3,2,1,6,137,1,7,160,3,2,1,0,4,4,72,69,76,
                                     79,1,1,255])
//     if let k4 { print(": k4 \(k4)") }
     if let k2 { print(": k2 \(k2)") }
     var serializer = DER.Serializer()
     try k2!.serialize(into: &serializer)
     print(": DER.k4 \(serializer.serializedBytes)")

//   if let k2 { print(": k2 \(k2)") }
//   if let xx { print(": xx \(xx)") }

     var timer: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
     var vv = V(a: [[1]], b: [[2]], c: [3], d: [4], e: true, f: true,
                g: [[5]], h: [[6]], i: [7], j: [0], k: ASN1OctetString(contentBytes: [50,51,52,54]), l: true)
     var decoded: K? = nil
     timer = CFAbsoluteTimeGetCurrent()
     for i in 1...1_000_000 { try K(derEncoded: serializer.serializedBytes) }
     timer = Double((CFAbsoluteTimeGetCurrent() - timer)*1000)
     print("DECODE 1 000 000: \(Int(timer)) ms")
     timer = CFAbsoluteTimeGetCurrent()
     for i in 1...1_000_000 { try k2!.serialize(into: &serializer) }
     timer = Double((CFAbsoluteTimeGetCurrent() - timer)*1000)
     print("ENCODE 1 000 000: \(Int(timer)) ms")

         serializer = DER.Serializer()
     try xx!.serialize(into: &serializer)
     print(": V.xx \(xx)")
     print(": DER.V \(serializer.serializedBytes)")

     let ll = List(data: ASN1OctetString(contentBytes: [48,48]), next: List_next_Choice.end(ASN1Null()))
     let a = A.list_x(ll)
         serializer = DER.Serializer()
     try a.serialize(into: &serializer)
     print(": A \(a)")
     print(": DER.A \(serializer.serializedBytes)")

     let b = A.v(vv)
         serializer = DER.Serializer()
     try b.serialize(into: &serializer)
     print(": B \(b)")
     print(": DER.B \(serializer.serializedBytes)")

  }
*/

  public static func help() {
     print(": form — Get by NO and list FORMS")
     print(": show — Show X.509 Envelopes <CMS CSR CRT ECDSA>")
     print(": bye — Quit Application")
     print(": kw — AES Key Wrap")
     print(": kdf — Key Derive Function ")
     print(": login <NICK> — Connect to Relay")
     print(": send <TO> <TEXT> — Send Message")
     print(": logout — Disconnect")
  }

  public static func execute(_ data: Array<String>) throws -> Bool {
     switch (data[0]) {
         case "bye": return true
  //       case "der": try Cmd.showK(data: data) ; return false
         case "cho": try Cmd.showName(data: data) ; return false
         case "?": help() ; return false
//         case "kw": try Block.testKeyWrap() ; return false
         case "form": try Form.show(data: data) ; return false
         case "show": try Cmd.showDER(data: data) ; return false
//         case "kdf": try Cmd.showKDF(data: data) ; return false
         case "login":
             if data.count > 1 { try RelayClient.shared.login(nickname: data[1]) }
             else { print(": usage: login <nickname>") }
             return false
         case "logout": RelayClient.shared.logout(); return false
         case "send":
             if data.count > 2 {
                 let text = data.dropFirst(2).joined(separator: " ")
                 try RelayClient.shared.send(to: data[1], text: text)
             } else { print(": usage: send <to> <text>") }
             return false
         default: return false
     }
  }

  public static func showDER(data: Array<String>) throws {
     if (data.count > 2) {
         switch (data[2]) {
            case "crt": try Cmd.showCRT(name: data[1])
//            case "csr": try Cmd.showCSR(name: data[1])
//            case "cms": try Cmd.showCMS(name: data[1])
//            case "ecdsa": try Cmd.showECDSA(name: data[1])
            default: ()
         }
     } else {
         print(": Not enough arguments: show <FILE> <crt|csr|cms|ecdsa>")
     }
  }
/*
  public static func showECDSA(name: String) throws {
     print(": ECDSA=\(name)")
     let url = URL(fileURLWithPath: name)
     if (!Cmd.exists(f: url.path)) { print(": ECDSA file not found.") } else {
         let data = try Data(contentsOf: url)
         let ecdsa = try ECDSASigValue(derEncoded: Array(data))
         print(": \(ecdsa)")
     }
  }

  public static func showCMS(name: String) throws {
     print(": CMS=\(name)")
     let url = URL(fileURLWithPath: name)
     if (!Cmd.exists(f: url.path)) { print(": CMS file not found.") } else {
         let data = try Data(contentsOf: url)
         let cms = try CMSContentInfo(derEncoded: Array(data))
         print(": \(cms)")
     }
  }
*/
  public static func showCRT(name: String) throws {
     print(": CRT=\(name)")
     let url = URL(fileURLWithPath: name)
     if (!Cmd.exists(f: url.path)) { print(": CRT file not found.") } else {
         let data = try Data(contentsOf: url)
         print(": CERT.Serialized \(Array(data))")
         var crt = try Certificate(derEncoded: Array(data))
         print(": CERT.ASN1 \(crt)")
         var serializer = DER.Serializer()
         try crt.serialize(into: &serializer)
         print(": CERT.Serialized \(serializer.serializedBytes)")
         crt = try Certificate(derEncoded: Array(serializer.serializedBytes))
         print(": CERT.ASN1 \(crt)")
     }
  }
/*
  public static func showCSR(name: String) throws {
     print(": CSR=\(name)")
     let url = URL(fileURLWithPath: name)
     if (!Cmd.exists(f: url.path)) { print(": CSR file not found.") } else {
         let data = try Data(contentsOf: url)
         let csr = try CertificateSigningRequest(derEncoded: Array(data))
         print(": \(csr)")
     }
  }
*/
}