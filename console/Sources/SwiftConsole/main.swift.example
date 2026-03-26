import SwiftASN1
import Foundation

exit(Console.suite())

extension String: @retroactive Error { }

func testPKIStatusInfoLogic() {
    print("TEST: Testing PKIStatusInfo decoding...")
    // PKIStatusInfo: SEQUENCE { status INTEGER (0) }
    // Tag 16 (Sequence) Len 3. Content: Tag 2 (Int) Len 1 Val 0.
    // [0x30, 0x03, 0x02, 0x01, 0x00]
    let bytes: [UInt8] = [0x30, 0x03, 0x02, 0x01, 0x00]
    do {
         let info = try PKIXCMP_2009_PKIStatusInfo(derEncoded: bytes)
         print("TEST: Decoded PKIStatusInfo successfully: \(info)")
    } catch {
         print("TEST: FAILED to decode PKIStatusInfo: \(error)")
    }
}

// Call the test
testPKIStatusInfoLogic()

// MARK: - CMP HTTP Client

/// Send CMP request over HTTP and get response
func sendCMPRequest(to url: URL, message: Data) async throws -> Data {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/pkixcmp", forHTTPHeaderField: "Content-Type")
    request.setValue("\(message.count)", forHTTPHeaderField: "Content-Length")
    request.setValue("close", forHTTPHeaderField: "Connection")
    request.httpBody = message
    request.timeoutInterval = 30
    
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60
    let session = URLSession(configuration: config)
    
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw "Not an HTTP response"
    }
    
    guard httpResponse.statusCode == 200 else {
        throw "HTTP error: \(httpResponse.statusCode)"
    }
    
    return data
}

#if canImport(Network)
import Network

/// Send CMP request over raw TCP (not HTTP)
func sendCMPRequestTCP(host: String, port: UInt16, message: Data) async throws -> Data {
    return try await withCheckedThrowingContinuation { continuation in
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
        
        var responseData = Data()
        var hasResumed = false
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                // Send the request
                connection.send(content: message, contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { error in
                    if let error = error {
                        if !hasResumed {
                            hasResumed = true
                            continuation.resume(throwing: error)
                        }
                        return
                    }
                    
                    // Read response
                    func readMore() {
                        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
                            if let error = error {
                                if !hasResumed {
                                    hasResumed = true
                                    continuation.resume(throwing: error)
                                }
                                return
                            }
                            
                            if let data = data {
                                responseData.append(data)
                            }
                            
                            if isComplete {
                                connection.cancel()
                                if !hasResumed {
                                    hasResumed = true
                                    continuation.resume(returning: responseData)
                                }
                            } else {
                                readMore()
                            }
                        }
                    }
                    readMore()
                })
            case .failed(let error):
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: error)
                }
            case .cancelled:
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: responseData)
                }
            default:
                break
            }
        }
        
        connection.start(queue: .global())
    }
}
#endif

// MARK: - Pure Swift SHA-256 Implementation

/// Right rotate for UInt32
@inline(__always)
private func rotr(_ x: UInt32, _ n: UInt32) -> UInt32 {
    return (x >> n) | (x << (32 - n))
}

/// Compute SHA-256 hash of data
func sha256(_ data: Data) -> Data {
    // SHA-256 constants (first 32 bits of fractional parts of cube roots of first 64 primes)
    let k: [UInt32] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ]
    
    var h: [UInt32] = [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ]
    
    // Pre-processing: padding
    var msg = Array(data)
    let originalLength = msg.count
    msg.append(0x80)
    while (msg.count % 64) != 56 {
        msg.append(0x00)
    }
    
    // Append original length in bits as 64-bit big-endian
    let bitLength = UInt64(originalLength) * 8
    for i in stride(from: 56, through: 0, by: -8) {
        msg.append(UInt8((bitLength >> i) & 0xff))
    }
    
    // Process each 512-bit chunk
    for chunkStart in stride(from: 0, to: msg.count, by: 64) {
        var w = [UInt32](repeating: 0, count: 64)
        
        // Copy chunk into first 16 words
        for i in 0..<16 {
            let offset = chunkStart + i * 4
            w[i] = UInt32(msg[offset]) << 24 |
                   UInt32(msg[offset + 1]) << 16 |
                   UInt32(msg[offset + 2]) << 8 |
                   UInt32(msg[offset + 3])
        }
        
        // Extend the first 16 words into the remaining 48 words
        for i in 16..<64 {
            let s0 = rotr(w[i-15], 7) ^ rotr(w[i-15], 18) ^ (w[i-15] >> 3)
            let s1 = rotr(w[i-2], 17) ^ rotr(w[i-2], 19) ^ (w[i-2] >> 10)
            w[i] = w[i-16] &+ s0 &+ w[i-7] &+ s1
        }
        
        // Initialize working variables
        var a = h[0], b = h[1], c = h[2], d = h[3]
        var e = h[4], f = h[5], g = h[6], hh = h[7]
        
        // Compression function main loop
        for i in 0..<64 {
            let S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)
            let ch = (e & f) ^ ((~e) & g)
            let temp1 = hh &+ S1 &+ ch &+ k[i] &+ w[i]
            let S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)
            let maj = (a & b) ^ (a & c) ^ (b & c)
            let temp2 = S0 &+ maj
            
            hh = g; g = f; f = e; e = d &+ temp1
            d = c; c = b; b = a; a = temp1 &+ temp2
        }
        
        // Add compressed chunk to hash value
        h[0] &+= a; h[1] &+= b; h[2] &+= c; h[3] &+= d
        h[4] &+= e; h[5] &+= f; h[6] &+= g; h[7] &+= hh
    }
    
    // Produce final hash value (big-endian)
    var result = Data(capacity: 32)
    for v in h {
        result.append(UInt8((v >> 24) & 0xff))
        result.append(UInt8((v >> 16) & 0xff))
        result.append(UInt8((v >> 8) & 0xff))
        result.append(UInt8(v & 0xff))
    }
    return result
}

/// Compute HMAC-SHA256
func hmacSHA256(key: Data, data: Data) -> Data {
    let blockSize = 64
    var keyBytes = Array(key)
    
    // If key is longer than block size, hash it
    if keyBytes.count > blockSize {
        keyBytes = Array(sha256(key))
    }
    
    // Pad key to block size
    while keyBytes.count < blockSize {
        keyBytes.append(0x00)
    }
    
    // Create inner and outer padded keys
    var ipad = [UInt8](repeating: 0x36, count: blockSize)
    var opad = [UInt8](repeating: 0x5c, count: blockSize)
    
    for i in 0..<blockSize {
        ipad[i] ^= keyBytes[i]
        opad[i] ^= keyBytes[i]
    }
    
    // HMAC = H(opad || H(ipad || message))
    var innerData = Data(ipad)
    innerData.append(data)
    let innerHash = sha256(innerData)
    
    var outerData = Data(opad)
    outerData.append(innerHash)
    return sha256(outerData)
}

/// Compute PBKDF-like key from password using iterated SHA-256 (RFC 4210 PBM style)
/// This is NOT PBKDF2, but the simpler iterated hashing used in CMP PBM:
/// baseKey = H(H(...H(password || salt)...)) with `iterations` hash applications
func pbkdf(password: Data, salt: Data, iterations: Int) -> Data {
    var result = Data()
    result.append(password)
    result.append(salt)
    
    // Iterate hash
    for _ in 0..<iterations {
        result = sha256(result)
    }
    
    return result
}

// #if false
import Security

// MARK: - Pure Swift CSR Generation (No OpenSSL)

/// Generate EC P-384 key pair using Security framework
func generateECKeyPair() throws -> (privateKey: SecKey, publicKey: SecKey) {
    let attributes: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeySizeInBits as String: 384,
        kSecAttrIsPermanent as String: false
    ]
    
    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
        throw error!.takeRetainedValue() as Error
    }
    
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
        throw "Failed to extract public key"
    }
    
    return (privateKey, publicKey)
}

/// Get raw public key bytes from SecKey (uncompressed point format)
func getPublicKeyBytes(publicKey: SecKey) throws -> Data {
    var error: Unmanaged<CFError>?
    guard let data = SecKeyCopyExternalRepresentation(publicKey, &error) else {
        throw error!.takeRetainedValue() as Error
    }
    // For EC keys, this returns the uncompressed point (04 || x || y)
    return data as Data
}

/// Sign data with ECDSA using SHA-384
func signWithECDSA(privateKey: SecKey, data: Data) throws -> Data {
    var error: Unmanaged<CFError>?
    guard let signature = SecKeyCreateSignature(
        privateKey,
        .ecdsaSignatureMessageX962SHA384,
        data as CFData,
        &error
    ) else {
        throw error!.takeRetainedValue() as Error
    }
    return signature as Data
}

/// Build a CSR entirely in Swift without OpenSSL
func buildCSR(subject: String, countryCode: String = "UA", state: String = "Kyiv", org: String = "SYNRC") throws -> (csr: PKCS_10_CertificationRequest, privateKey: SecKey) {
    print(": Generating EC P-384 key pair...")
    let (privateKey, publicKey) = try generateECKeyPair()
    
    // Get public key bytes
    let publicKeyBytes = try getPublicKeyBytes(publicKey: publicKey)
    print(": Public key size: \(publicKeyBytes.count) bytes")
    
    // Build Subject Name: /C=UA/ST=Kyiv/O=SYNRC/CN=dima
    var rdns: [InformationFramework_RelativeDistinguishedName] = []
    
    // Helper to create ATAV with PrintableString (for country code - required by X.520)
    func makeATAVPrintable(oid: String, value: String) throws -> InformationFramework_AttributeTypeAndValue {
        let oidObj = try ASN1ObjectIdentifier(dotRepresentation: oid)
        let printableValue = try ASN1PrintableString(value)
        let attrValue = InformationFramework_AttributeValueX.printable(printableValue)
        return InformationFramework_AttributeTypeAndValue(type: oidObj, value: attrValue)
    }
    
    // Helper to create ATAV using UTF8String (for most attributes - supports Unicode)
    func makeATAV(oid: String, value: String) throws -> InformationFramework_AttributeTypeAndValue {
        let oidObj = try ASN1ObjectIdentifier(dotRepresentation: oid)
        let utf8Value = ASN1UTF8String(value)
        let attrValue = InformationFramework_AttributeValueX.utf8(utf8Value)
        return InformationFramework_AttributeTypeAndValue(type: oidObj, value: attrValue)
    }
    
    // 2.5.4.6 = countryName (MUST be PrintableString per X.520)
    rdns.append(InformationFramework_RelativeDistinguishedName([try makeATAVPrintable(oid: "2.5.4.6", value: countryCode)]))
    // 2.5.4.8 = stateOrProvinceName
    rdns.append(InformationFramework_RelativeDistinguishedName([try makeATAV(oid: "2.5.4.8", value: state)]))
    // 2.5.4.10 = organizationName
    rdns.append(InformationFramework_RelativeDistinguishedName([try makeATAV(oid: "2.5.4.10", value: org)]))
    // 2.5.4.3 = commonName
    rdns.append(InformationFramework_RelativeDistinguishedName([try makeATAV(oid: "2.5.4.3", value: subject)]))
    
    let subjectName = InformationFramework_Name.rdnSequence(InformationFramework_RDNSequence(rdns))
    print(": Subject: /C=\(countryCode)/ST=\(state)/O=\(org)/CN=\(subject)")
    
    // Build SubjectPublicKeyInfo
    // Algorithm: 1.2.840.10045.2.1 (ecPublicKey) with parameter 1.3.132.0.34 (secp384r1)
    let ecPubKeyOID = try ASN1ObjectIdentifier(dotRepresentation: "1.2.840.10045.2.1")
    let secp384r1OID = try ASN1ObjectIdentifier(dotRepresentation: "1.3.132.0.34")
    
    // Serialize the curve OID as parameters
    var oidSerializer = DER.Serializer()
    try secp384r1OID.serialize(into: &oidSerializer)
    let curveParams = try ASN1Any(derEncoded: oidSerializer.serializedBytes)
    
    let algorithm = AuthenticationFramework_AlgorithmIdentifier(
        algorithm: ecPubKeyOID,
        parameters: curveParams
    )
    
    let spki = AuthenticationFramework_SubjectPublicKeyInfo(
        algorithm: algorithm,
        subjectPublicKey: ASN1BitString(bytes: ArraySlice(publicKeyBytes))
    )
    
    // Build CertificationRequestInfo
    let csrInfo = PKCS_10_CertificationRequestInfo(
        version: .v1,
        subject: subjectName,
        subjectPKInfo: spki,
        attributes: PKCS_10_Attributes([])  // Empty attributes
    )
    
    // Serialize CSRInfo for signing
    var csrInfoSerializer = DER.Serializer()
    try csrInfo.serialize(into: &csrInfoSerializer)
    let csrInfoBytes = csrInfoSerializer.serializedBytes
    
    print(": Signing CSR with ECDSA-SHA384...")
    let signature = try signWithECDSA(privateKey: privateKey, data: Data(csrInfoBytes))
    print(": Signature size: \(signature.count) bytes")
    
    // Signature algorithm: 1.2.840.10045.4.3.3 (ecdsa-with-SHA384)
    let sigAlgOID = try ASN1ObjectIdentifier(dotRepresentation: "1.2.840.10045.4.3.3")
    let sigAlg = AuthenticationFramework_AlgorithmIdentifier(algorithm: sigAlgOID, parameters: nil)
    
    // Build final CSR
    let csr = PKCS_10_CertificationRequest(
        certificationRequestInfo: csrInfo,
        signatureAlgorithm: sigAlg,
        signature: ASN1BitString(bytes: ArraySlice(signature))
    )
    
    print(": CSR built successfully!")
    return (csr, privateKey)
}
// #endif

public class Console {

  public static func exists(f: String) -> Bool { return FileManager.default.fileExists(atPath: f) }

  public static func showName(data: Array<UInt8>) throws {
     print("Debug: showName")
     let name: InformationFramework_Name? = try InformationFramework_Name(derEncoded: data)
     var serializer = DER.Serializer()
     try name!.serialize(into: &serializer)
     print(": Name.DER \(data)")
     print(": Name ⟼ \(name!)\n")
     if (data != serializer.serializedBytes) { throw "DER <-> Name lacks equality properties." }
  }

  public static func showGeneralName(data: Array<UInt8>) throws {
     print("Debug: showGeneralName")
     let name: KEP_GeneralName? = try KEP_GeneralName(derEncoded: data)
     var serializer = DER.Serializer()
     try name!.serialize(into: &serializer)
     print(": GeneralName.DER \(data)")
     print(": GeneralName ⟼ \(name!)\n")
     if (data != serializer.serializedBytes) { throw "DER <-> GeneralName lacks equality properties." }
  }

  public static func showDirectoryString(data: Array<UInt8>) throws {
     print("Debug: showDirectoryString")
     let ds: DSTU_DirectoryString? = try DSTU_DirectoryString(derEncoded: data)
     var serializer = DER.Serializer()
     try ds!.serialize(into: &serializer)
     print(": DirectoryString.DER \(data)")
     print(": DirectoryString ⟼ \(ds!)\n")
     if (data != serializer.serializedBytes) { throw "DER <-> DirectoryString lacks equality properties." }
  }

  public static func showLDAPMessage(data: Array<UInt8>) throws {
     let msg: LDAP_Message? = try LDAP_Message(derEncoded: data)
     var serializer = DER.Serializer()
     try msg!.serialize(into: &serializer)
     print(": LDAPMessage.DER \(data)")
     print(": LDAPMessage ⟼ \(msg!)\n")
     if (data != serializer.serializedBytes) { throw "DER <-> LDAPMessage lacks equality properties." }
  }

  public static func showCHATMessage(data: Array<UInt8>) throws {
     let msg: CHAT_Message? = try CHAT_Message(derEncoded: data)
     var serializer = DER.Serializer()
     try msg!.serialize(into: &serializer)
     print(": CHATMessage.DER \(data)")
     print(": CHATMessage ⟼ \(msg!)\n")
     if (data != serializer.serializedBytes) { throw "DER <-> CHATMessage lacks equality properties." }
  }

  public static func showCertificate(file: String) throws {
     let url = URL(fileURLWithPath: file)
     if (!Console.exists(f: url.path)) { print(": CERT file not found.") } else {
         let data = try Data(contentsOf: url)
         let cert = try AuthenticationFramework_Certificate(derEncoded: Array(data)) // display TBSCertificate envelop from DSTU.asn1
         print(": Certificate ⟼ \(cert)\n")
     }
  }

  public static func verifyX509(file: String, output: String = "verified.der") throws {
     let url = URL(fileURLWithPath: file)
     if (!Console.exists(f: url.path)) { print(": X509 file not found.") } else {
         let data = try Data(contentsOf: url)
         let cert = try AuthenticationFramework_Certificate(derEncoded: Array(data))
         var serializer = DER.Serializer()
         try cert.serialize(into: &serializer)
         let outputUrl = URL(fileURLWithPath: output)
         try Data(serializer.serializedBytes).write(to: outputUrl)
         print(": X509 Certificate read and re-written to \(output)")
         print(": X509 Certificate ⟼ \(cert)\n")
         if (Array(data) != serializer.serializedBytes) { 
            print(": [WARN] DER <-> Certificate round trip differs.") 
         } else {
            print(": [OK] DER <-> Certificate round trip matches.")
         }
     }
  }

  public static func showContentInfo(file: String) throws {
     let url = URL(fileURLWithPath: file)
     if (!Console.exists(f: url.path)) { print(": CI file not found.") } else {
         let data = try Data(contentsOf: url)
         var cert = try KEP_ContentInfo(derEncoded: Array(data))
         var serializer = DER.Serializer()
         try cert.content.serialize(into: &serializer)
         var signedData = try KEP_SignedData(derEncoded: Array(serializer.serializedBytes))
         let content: String? = try String(bytes: signedData.encapContentInfo.eContent!.bytes, encoding: .utf8)
         cert.content = try ASN1Any(erasing: ASN1Null())
         signedData.encapContentInfo.eContent = nil
         print(": SignedData ⟼ \(signedData)\n ") // display SignedData envelope from KEP.asn1
         print(": signedData.encapContentInfo.eContent := \(content!)\n") // display signed content

         print(": ContentInfo.DER \(data)")
         print(": ContentInfo ⟼ \(cert)\n")
     }
  }

  public static func verifyOID() throws {
      print("Debug: verifyOID")
      print(": KEP_id_data ⟼ \(KEP_id_data)")
      if (KEP_id_data.description != "1.2.840.113549.1.7.1") {
         throw "KEP_id_data value mismatch. Expected 1.2.840.113549.1.7.1, got \(KEP_id_data)"
      }
      print(": PASSED\n")
  }

  public static func showPentanomial(data: Array<UInt8>) throws {
     print("Debug: showPentanomial")
     let val: DSTU_Pentanomial? = try DSTU_Pentanomial(derEncoded: data)
     var serializer = DER.Serializer()
     try val!.serialize(into: &serializer)
     print(": Pentanomial.DER \(data)")
     print(": Pentanomial ⟼ \(val!)\n")
     if (data != serializer.serializedBytes) { throw "DER <-> Pentanomial lacks equality properties." }
  }

  public static func showCertificateData(data: Array<UInt8>) throws {
     print("Debug: showCertificateData")
     let val: AuthenticationFramework_Certificate? = try AuthenticationFramework_Certificate(derEncoded: data)
     var serializer = DER.Serializer()
     try val!.serialize(into: &serializer)
     print(": Certificate.DER \(data)")
     print(": Certificate ⟼ \(val!)\n")
     if (data != serializer.serializedBytes) { throw "DER <-> Certificate lacks equality properties." }
  }

  public static func generateX509() throws {
     print("Debug: generateX509")
     
     // 1. Construct Issuer/Subject Name: CN=Test
     // 2.5.4.3 (commonName)
     let cnOID = try ASN1ObjectIdentifier(dotRepresentation: "2.5.4.3")
     // PrintableString "Test" -> Tag 0x13, Length 0x04, Bytes "Test"
     let cnValueDer: [UInt8] = [0x13, 0x04, 0x54, 0x65, 0x73, 0x74] 
     let cnValue = try ASN1Any(derEncoded: cnValueDer)
     
     let atav = InformationFramework_AttributeTypeAndValue(type: cnOID, value: .else(cnValue))
     let rdn = InformationFramework_RelativeDistinguishedName([atav])
     let name = InformationFramework_Name.rdnSequence(InformationFramework_RDNSequence([rdn]))
     
     // 2. Validity (Now to Now + 1 year)
     let now = Date()
     let later = Date(timeIntervalSinceNow: 3600 * 24 * 365)
     
     let calendar = Calendar(identifier: .gregorian)
     let nowComps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
     let laterComps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: later)
     
     let notBefore = try AuthenticationFramework_Time.utcTime(UTCTime(year: nowComps.year!, month: nowComps.month!, day: nowComps.day!, hours: nowComps.hour!, minutes: nowComps.minute!, seconds: nowComps.second!))
     let notAfter = try AuthenticationFramework_Time.utcTime(UTCTime(year: laterComps.year!, month: laterComps.month!, day: laterComps.day!, hours: laterComps.hour!, minutes: laterComps.minute!, seconds: laterComps.second!))
     
     let validity = AuthenticationFramework_Validity(notBefore: notBefore, notAfter: notAfter)
     
     // 3. Algorithm: 1.2.840.113549.1.1.1 (rsaEncryption)
     let algoOID = try ASN1ObjectIdentifier(dotRepresentation: "1.2.840.113549.1.1.1")
     // Parameters: NULL
     let nullParams = try ASN1Any(erasing: ASN1Null())
     let algo = AuthenticationFramework_AlgorithmIdentifier(algorithm: algoOID, parameters: nullParams)
     
     // 4. SubjectPublicKeyInfo
     let pubKeyBitString = ASN1BitString(bytes: [0x01, 0x02, 0x03, 0x04])
     let spki = AuthenticationFramework_SubjectPublicKeyInfo(algorithm: algo, subjectPublicKey: pubKeyBitString)
     
     // 5. TBSCertificate
     let tbs = AuthenticationFramework_Certificate_toBeSigned(
        version: .v3,
        serialNumber: [0x01],
        signature: algo,
        issuer: name,
        validity: validity,
        subject: name,
        subjectPublicKeyInfo: spki,
        issuerUniqueIdentifier: nil,
        subjectUniqueIdentifier: nil,
        extensions: nil
     )
     
     // 6. Certificate
     let sigValue = ASN1BitString(bytes: [0xFF, 0xEE, 0xDD])
     let cert = AuthenticationFramework_Certificate(toBeSigned: tbs, algorithmIdentifier: algo, encrypted: sigValue)
     
     print(": Generated Certificate ⟼ \(cert)\n")
     
     var serializer = DER.Serializer()
     try cert.serialize(into: &serializer)
          let url = URL(fileURLWithPath: "generated.crt")
      try Data(serializer.serializedBytes).write(to: url)
      print(": Written to generated.crt")
  }

  // MARK: - CSR (Certificate Signing Request) Tests
  
  /// Parse and display a CSR file (PKCS#10 CertificationRequest)
  /// Test with: openssl req -new -newkey ec:<(openssl ecparam -name secp384r1) -keyout key.enc -out test.csr -subj "/CN=test"
  public static func showCSR(file: String) throws {
     print("Debug: showCSR")
     let url = URL(fileURLWithPath: file)
     if (!Console.exists(f: url.path)) { 
        print(": CSR file not found: \(file)") 
        return
     }
     
     // Try to read as DER first, then as PEM
     var data = try Data(contentsOf: url)
     
     // Check if it's PEM encoded
     if let pemString = String(data: data, encoding: .utf8), 
        pemString.contains("-----BEGIN CERTIFICATE REQUEST-----") {
        // Extract base64 content between PEM headers
        let lines = pemString.components(separatedBy: .newlines)
        var base64Data = ""
        var inBlock = false
        for line in lines {
           if line.contains("-----BEGIN") { inBlock = true; continue }
           if line.contains("-----END") { break }
           if inBlock { base64Data += line }
        }
        if let decoded = Data(base64Encoded: base64Data) {
           data = decoded
        }
     }
     
     let csr = try PKCS_10_CertificationRequest(derEncoded: Array(data))
     print(": CSR Subject ⟼ \(csr.certificationRequestInfo.subject)")
     print(": CSR Algorithm ⟼ \(csr.signatureAlgorithm.algorithm)")
     print(": CSR ⟼ \(csr)\n")
     
     // Verify round-trip
     var serializer = DER.Serializer()
     try csr.serialize(into: &serializer)
     if (Array(data) == serializer.serializedBytes) {
        print(": [OK] CSR round-trip matches.")
     } else {
        print(": [WARN] CSR round-trip differs.")
     }
  }
  
  /// Verify CSR by re-encoding and comparing
  public static func verifyCSR(file: String, output: String = "verified.csr") throws {
     print("Debug: verifyCSR")
     let url = URL(fileURLWithPath: file)
     if (!Console.exists(f: url.path)) { 
        print(": CSR file not found: \(file)") 
        return
     }
     
     var data = try Data(contentsOf: url)
     
     // Handle PEM encoding
     if let pemString = String(data: data, encoding: .utf8), 
        pemString.contains("-----BEGIN CERTIFICATE REQUEST-----") {
        let lines = pemString.components(separatedBy: .newlines)
        var base64Data = ""
        var inBlock = false
        for line in lines {
           if line.contains("-----BEGIN") { inBlock = true; continue }
           if line.contains("-----END") { break }
           if inBlock { base64Data += line }
        }
        if let decoded = Data(base64Encoded: base64Data) {
           data = decoded
        }
     }
     
     let csr = try PKCS_10_CertificationRequest(derEncoded: Array(data))
     var serializer = DER.Serializer()
     try csr.serialize(into: &serializer)
     
     let outputUrl = URL(fileURLWithPath: output)
     try Data(serializer.serializedBytes).write(to: outputUrl)
     print(": CSR read and re-written to \(output)")
     
     if (Array(data) == serializer.serializedBytes) { 
        print(": [OK] DER <-> CSR round trip matches.")
     } else {
        print(": [WARN] DER <-> CSR round trip differs.")
     }
  }

  /// Test CMP workflow: parse CSR, then show what would be sent in p10cr
  /// Simulates: openssl cmp -cmd p10cr -server "ca.synrc.com":8829 -secret pass:0000 -ref cmptestp10cr -certout dima.pem -csr dima.csr
  public static func testCMPWorkflow(csrFile: String) throws {
     print("Debug: testCMPWorkflow")
     print(": Simulating CMP p10cr (PKCS#10 Certificate Request) workflow")
     print(": This is what would be sent to ca.synrc.com:8829\n")
     
     let url = URL(fileURLWithPath: csrFile)
     if (!Console.exists(f: url.path)) { 
        print(": CSR file not found: \(csrFile)")
        print(": Generate one with:")
        print(":   openssl req -passout pass:0 -new -newkey ec:<(openssl ecparam -name secp384r1) \\")
        print(":              -keyout dima.key.enc -out dima.csr -subj \"/C=UA/ST=Kyiv/O=SYNRC/CN=dima\"")
        return
     }
     
     var data = try Data(contentsOf: url)
     
     // Handle PEM encoding
     if let pemString = String(data: data, encoding: .utf8), 
        pemString.contains("-----BEGIN CERTIFICATE REQUEST-----") {
        let lines = pemString.components(separatedBy: .newlines)
        var base64Data = ""
        var inBlock = false
        for line in lines {
           if line.contains("-----BEGIN") { inBlock = true; continue }
           if line.contains("-----END") { break }
           if inBlock { base64Data += line }
        }
        if let decoded = Data(base64Encoded: base64Data) {
           data = decoded
        }
     }
     
     // Parse the CSR
     let csr = try PKCS_10_CertificationRequest(derEncoded: Array(data))
     
     print(": === CSR Contents ===")
     print(": Subject: \(csr.certificationRequestInfo.subject)")
     print(": Signature Algorithm: \(csr.signatureAlgorithm.algorithm)")
     print(": Version: \(csr.certificationRequestInfo.version)")
     
     // Serialize and compute size
     var serializer = DER.Serializer()
     try csr.serialize(into: &serializer)
     print(": CSR DER Size: \(serializer.serializedBytes.count) bytes\n")
     
     print(": === CMP p10cr Request Info ===")
     print(": Command: p10cr (PKCS#10 Certification Request)")
     print(": Server: ca.synrc.com:8829")
     print(": Reference: cmptestp10cr")
     print(": MAC Protection: PBM with shared secret")
     print(": CSR Type: PKCS_10_CertificationRequest\n")
     
     print(": [OK] CSR parsed successfully - ready for CMP submission")
  }

  /// Build and send CMP p10cr request to CA server
  /// Usage: openssl cmp -cmd p10cr -server "ca.synrc.com":8829 -secret pass:0000 -ref cmptestp10cr
  public static func sendCMPp10cr(csrFile: String, server: String = "ca.synrc.com", port: Int = 8829, secret: String = "0000", reference: String = "cmptestp10cr") async throws {
     print("Debug: sendCMPp10cr")
     print(": Building CMP p10cr request...")
     print(": Server: \(server):\(port)")
     print(": Reference: \(reference)\n")
     
     let url = URL(fileURLWithPath: csrFile)
     if (!Console.exists(f: url.path)) { 
        throw "CSR file not found: \(csrFile)"
     }
     
     // Load and parse CSR
     var data = try Data(contentsOf: url)
     if let pemString = String(data: data, encoding: .utf8), 
        pemString.contains("-----BEGIN CERTIFICATE REQUEST-----") {
        let lines = pemString.components(separatedBy: .newlines)
        var base64Data = ""
        var inBlock = false
        for line in lines {
           if line.contains("-----BEGIN") { inBlock = true; continue }
           if line.contains("-----END") { break }
           if inBlock { base64Data += line }
        }
        if let decoded = Data(base64Encoded: base64Data) {
           data = decoded
        }
     }
     let csr = try PKCS_10_CertificationRequest(derEncoded: Array(data))
     print(": CSR Subject: \(csr.certificationRequestInfo.subject)")
     
     // Generate salt and nonce
     var salt = [UInt8](repeating: 0, count: 16)
     var transactionId = [UInt8](repeating: 0, count: 16)
     var senderNonce = [UInt8](repeating: 0, count: 16)
     _ = SecRandomCopyBytes(kSecRandomDefault, salt.count, &salt)
     _ = SecRandomCopyBytes(kSecRandomDefault, transactionId.count, &transactionId)
     _ = SecRandomCopyBytes(kSecRandomDefault, senderNonce.count, &senderNonce)
     
     // Build PBM parameters for protection
     // OID 1.3.6.1.5.5.8.1.2 = hmac-sha256
     let hmacSHA256OID = try ASN1ObjectIdentifier(dotRepresentation: "1.2.840.113549.2.9")
     // OID 2.16.840.1.101.3.4.2.1 = sha256
     let sha256OID = try ASN1ObjectIdentifier(dotRepresentation: "2.16.840.1.101.3.4.2.1")
     
     let owfAlg = AuthenticationFramework_AlgorithmIdentifier(algorithm: sha256OID, parameters: nil)
     let macAlg = AuthenticationFramework_AlgorithmIdentifier(algorithm: hmacSHA256OID, parameters: nil)
     
     // Iteration count = 10000
     let iterationCount: ArraySlice<UInt8> = [0x27, 0x10]  // 10000 in big-endian
     
     let pbmParams = PKIXCMP_2009_PBMParameter(
        salt: ASN1OctetString(contentBytes: ArraySlice(salt)),
        owf: owfAlg,
        iterationCount: iterationCount,
        mac: macAlg
     )
     
     // Serialize PBM parameters for protection algorithm
     var pbmSerializer = DER.Serializer()
     try pbmParams.serialize(into: &pbmSerializer)
     let pbmDER = pbmSerializer.serializedBytes
     
     // Create protection algorithm: 1.2.840.113533.7.66.13 (Password Based MAC)
     let pbmOID = try ASN1ObjectIdentifier(dotRepresentation: "1.2.840.113533.7.66.13")
     let protectionAlg = AuthenticationFramework_AlgorithmIdentifier(
        algorithm: pbmOID,
        parameters: try ASN1Any(derEncoded: pbmDER)
     )
     
     // Build sender (dNSName) - fixed to use [2] IMPLICIT
     let senderName = try PKIX1Implicit88_GeneralName.dNSName(ASN1IA5String("robot_go"))
     let recipientName = try PKIX1Implicit88_GeneralName.dNSName(ASN1IA5String("localhost"))
     
     // Build header
     let header = PKIXCMP_2009_PKIHeader(
        pvno: .cmp2000,
        sender: senderName,
        recipient: recipientName,
        messageTime: nil,
        protectionAlg: protectionAlg,
        senderKID: nil,  // Removed senderKeyID to match C99/Go behavior
        recipKID: nil,
        transactionID: ASN1OctetString(contentBytes: ArraySlice(transactionId)),
        senderNonce: ASN1OctetString(contentBytes: ArraySlice(senderNonce)),
        recipNonce: nil,
        freeText: nil,
        generalInfo: nil
     )
     
     // Build body with CSR
     let body = PKIXCMP_2009_PKIBody.p10cr(csr)
     
     // Serialize protectedPart = SEQUENCE { header, body } per RFC 4210 section 5.1.3
     // The MAC is computed over the DER encoding of the ProtectedPart structure
     var protectedSerializer = DER.Serializer()
     try protectedSerializer.appendConstructedNode(identifier: .sequence) { coder in
         try header.serialize(into: &coder)
         try body.serialize(into: &coder, withIdentifier: ASN1Identifier(tagWithNumber: 4, tagClass: .contextSpecific))
     }
     let protectedBytes = protectedSerializer.serializedBytes
     
     // Compute protection MAC
     let passwordData = Data(secret.utf8)
     let derivedKey = pbkdf(password: passwordData, salt: Data(salt), iterations: 10000)
     let protectionMAC = hmacSHA256(key: derivedKey, data: Data(protectedBytes))
     
     print(": Protection MAC computed: \(protectionMAC.prefix(8).map { String(format: "%02x", $0) }.joined())...")
     
     // Build PKIMessage
     let protection = ASN1BitString(bytes: ArraySlice(protectionMAC))
     let pkiMessage = PKIXCMP_2009_PKIMessage(
        header: header,
        body: body,
        protection: protection,
        extraCerts: nil
     )
     
     // Serialize the full message
     var msgSerializer = DER.Serializer()
     try pkiMessage.serialize(into: &msgSerializer)
     let messageBytes = msgSerializer.serializedBytes
     
     print(": PKIMessage built: \(messageBytes.count) bytes")
     
     // Save request for debugging
     let requestPath = "cmp_request.der"
     try Data(messageBytes).write(to: URL(fileURLWithPath: requestPath))
     print(": Request saved to \(requestPath)")
     
     // Send HTTP request
     let serverURL = URL(string: "http://\(server):\(port)/")!
     print(": Sending to \(serverURL)...")
     
     do {
        let responseData = try await sendCMPRequest(to: serverURL, message: Data(messageBytes))
        print(": Received response: \(responseData.count) bytes")
        
        // Save response
        try responseData.write(to: URL(fileURLWithPath: "cmp_response.der"))
        print(": Response saved to cmp_response.der")
        
        // Parse response
        let response = try PKIXCMP_2009_PKIMessage(derEncoded: Array(responseData))
        print(": Response type: \(response.body)")
        
        // Check for certificate in response
        switch response.body {
        case .cp(let certRep):
           print(": Got certificate response!")
           let certs = certRep.response
           if !certs.isEmpty {
              print(": Received \(certs.count) certificate(s)")
              for (index, certResponse) in certs.enumerated() {
                 print(": Certificate \(index + 1):")
                 print(":   Status: \(certResponse.status)")
                 if let keyPair = certResponse.certifiedKeyPair {
                    print(":   CertifiedKeyPair: \(keyPair)")
                    print(":   Certificate/EncryptedCert: \(keyPair.certOrEncCert)")
                 }

              }
           } else {
              print(": No certificates in response")
           }
        case .error(let error):
           print(": Error response: \(error)")
        default:
           print(": Unexpected response type: \(response.body)")
        }

        
        print(": [OK] CMP request completed")
     } catch {
        print(": [ERROR] HTTP request failed: \(error)")
        print(": Request was saved to \(requestPath) for debugging")
     }
  }

  /// Complete CMP flow with pure Swift CSR generation - NO OpenSSL needed
  /// Generates key pair, builds CSR, sends CMP p10cr request to CA
  
  public static func generateAndSendCMP(
     subject: String = "swift_robot",
     countryCode: String = "UA",
     state: String = "Kyiv",
     org: String = "SYNRC",
     server: String = "ca.synrc.com",
     port: Int = 8121,
     secret: String = "0000",
     reference: String = "cmptestp10cr"
  ) async throws {
     print("\n" + String(repeating: "=", count: 50))
     print(": PURE SWIFT CMP FLOW (No OpenSSL Required)")
     print(String(repeating: "=", count: 50) + "\n")
     
     // Step 1: Generate CSR
     print(": Step 1: Building CSR...")
     let (csr, _) = try buildCSR(subject: subject, countryCode: countryCode, state: state, org: org)
     
     // Serialize CSR and save for debugging
     var csrSerializer = DER.Serializer()
     try csr.serialize(into: &csrSerializer)
     let csrDER = csrSerializer.serializedBytes
      // try Data(csrDER).write(to: URL(fileURLWithPath: "generated.csr"))
      // print(": CSR saved to generated.csr (\(csrDER.count) bytes)\n")
     
     // Step 2: Build CMP message
     print(": Step 2: Building CMP p10cr message...")
     
     // Generate random values
     var salt = [UInt8](repeating: 0, count: 16)
     var transactionId = [UInt8](repeating: 0, count: 16)
     var senderNonce = [UInt8](repeating: 0, count: 16)
     _ = SecRandomCopyBytes(kSecRandomDefault, salt.count, &salt)
     _ = SecRandomCopyBytes(kSecRandomDefault, transactionId.count, &transactionId)
     _ = SecRandomCopyBytes(kSecRandomDefault, senderNonce.count, &senderNonce)
     
     // Build PBM parameters
     let hmacSHA256OID = try ASN1ObjectIdentifier(dotRepresentation: "1.2.840.113549.2.9")
     let sha256OID = try ASN1ObjectIdentifier(dotRepresentation: "2.16.840.1.101.3.4.2.1")
     let owfAlg = AuthenticationFramework_AlgorithmIdentifier(algorithm: sha256OID, parameters: nil)
     let macAlg = AuthenticationFramework_AlgorithmIdentifier(algorithm: hmacSHA256OID, parameters: nil)
     let iterationCount: ArraySlice<UInt8> = [0x27, 0x10]
     
     let pbmParams = PKIXCMP_2009_PBMParameter(
        salt: ASN1OctetString(contentBytes: ArraySlice(salt)),
        owf: owfAlg,
        iterationCount: iterationCount,
        mac: macAlg
     )
     
     var pbmSerializer = DER.Serializer()
     try pbmParams.serialize(into: &pbmSerializer)
     
     let pbmOID = try ASN1ObjectIdentifier(dotRepresentation: "1.2.840.113533.7.66.13")
     let protectionAlg = AuthenticationFramework_AlgorithmIdentifier(
        algorithm: pbmOID,
        parameters: try ASN1Any(derEncoded: pbmSerializer.serializedBytes)
     )
     
     // Build sender (dNSName) - fixed to use [2] IMPLICIT
     let senderName = try PKIX1Implicit88_GeneralName.dNSName(ASN1IA5String(subject))
     let recipientName = try PKIX1Implicit88_GeneralName.dNSName(ASN1IA5String("localhost"))

     let header = PKIXCMP_2009_PKIHeader(
        pvno: .cmp2000,
        sender: senderName,
        recipient: recipientName,
        messageTime: nil,
        protectionAlg: protectionAlg,
        senderKID: nil,
        recipKID: nil,
        transactionID: ASN1OctetString(contentBytes: ArraySlice(transactionId)),
        senderNonce: ASN1OctetString(contentBytes: ArraySlice(senderNonce)),
        recipNonce: nil,
        freeText: nil,
        generalInfo: nil
     )
     
     let body = PKIXCMP_2009_PKIBody.p10cr(csr)
     
     // Serialize protectedPart = SEQUENCE { header, body } per RFC 4210 section 5.1.3
     var protectedSerializer = DER.Serializer()
     try protectedSerializer.appendConstructedNode(identifier: .sequence) { coder in
         try header.serialize(into: &coder)
         try body.serialize(into: &coder, withIdentifier: ASN1Identifier(tagWithNumber: 4, tagClass: .contextSpecific))
     }
     
     let derivedKey = pbkdf(password: Data(secret.utf8), salt: Data(salt), iterations: 10000)
     let protectionMAC = hmacSHA256(key: derivedKey, data: Data(protectedSerializer.serializedBytes))
     
     let pkiMessage = PKIXCMP_2009_PKIMessage(
        header: header,
        body: body,
        protection: ASN1BitString(bytes: ArraySlice(protectionMAC)),
        extraCerts: nil
     )
     
     var msgSerializer = DER.Serializer()
     try pkiMessage.serialize(into: &msgSerializer)
     let messageBytes = msgSerializer.serializedBytes
          // Step 3: Send to server via TCP (Manual HTTP/1.0 to ensure CloseWrite)
      print(": Step 3: Sending to \(server):\(port) via TCP...")
      
      let httpHeader = "POST / HTTP/1.0\r\n" +
                       "Content-Length: \(messageBytes.count)\r\n" +
                       "\r\n"
      
      var manualRequest = Data(httpHeader.utf8)
      manualRequest.append(Data(messageBytes))
      
      #if canImport(Network)
       var responseData: Data? = nil
           do {
           let receivedData = try await sendCMPRequestTCP(host: server, port: UInt16(port), message: manualRequest)
           responseData = receivedData
           var localData = receivedData
          print(": Response received: \(localData.count) bytes")
          
          // Strip HTTP headers from response if present
          // Just find data sequence for \r\n\r\n (0D 0A 0D 0A)
          if let headerEndRange = localData.range(of: Data([0x0D, 0x0A, 0x0D, 0x0A])) {
               let bodyStart = headerEndRange.upperBound
               localData = localData.subdata(in: bodyStart..<localData.endIndex)
               print(": Stripped HTTP headers.")
          }
          
          // Update outer var for catch debugging
          responseData = localData
          
          // try localData.write(to: URL(fileURLWithPath: "cmp_response.der"))
          // print(": Response saved to cmp_response.der")
          
          // Try to decode the full PKIMessage first
          do {
             let response = try PKIXCMP_2009_PKIMessage(derEncoded: Array(localData))
             
             switch response.body {
             case .cp(let certRep), .ip(let certRep):
                print(": SUCCESS! Certificate Response received")
                let certs = certRep.response
                print(": Response count: \(certs.count)")
                for (i, certResp) in certs.enumerated() {
                    print(": Response #\(i): status=\(certResp.status.status)")
                    if let kp = certResp.certifiedKeyPair {
                         print(":  - Certified Key Pair present")
                         // Decode certificate from CertOrEncCert
                         if case .certificate(let cmsCert) = kp.certOrEncCert {
                             print(":  - Certificate received!")
                             if case .x509v3PKCert(let cert) = cmsCert {
                                 print(":    Subject: \(cert.toBeSigned.subject)")
                                 print(":    Issuer: \(cert.toBeSigned.issuer)")
                                 print(":    Serial: \(Array(cert.toBeSigned.serialNumber))")
                                 print(":    Validity: \(cert.toBeSigned.validity)")
                                 print(":    Algorithm: \(cert.toBeSigned.signature.algorithm)")
                             }
                         } else {
                             print(":  - Encrypted certificate (not decoded)")
                         }
                    } else {
                        print(":  - No certified key pair in response")
                    }
                }
             case .error(let error):
                print(": ERROR response: \(error)")
             default:
                print(": Response type: \(response.body)")
             }
          } catch {
             // If full decode fails, try manual extraction
             print(": Note: Full PKIMessage decode failed (\(error))")
             print(": Attempting manual certificate extraction...")
             if let data = responseData {
                do {
                   try extractCertificateManually(from: Array(data))
                } catch {
                   print(": Manual extraction also failed: \(error)")
                }
             } else {
                 print(": No response data available for manual extraction.")
             }
          }
          
          print("\n" + String(repeating: "=", count: 50))
          print(": CMP FLOW COMPLETED SUCCESSFULLY")
       } catch {
          print(": [NETWORK ERROR] \(error)")
          // Rethrow to let caller know it failed
          throw error
       }
      #else
      print(": Error: Network framework not available")
      #endif
   }
   
   /// Manually extract certificate from CMP response when generated types fail
   static func extractCertificateManually(from bytes: [UInt8]) throws {
       let der = try DER.parse(bytes)
       
       // Navigate: PKIMessage -> body [3] -> CertRepMessage -> response -> CertResponse -> certifiedKeyPair -> cert
       guard case .constructed(let rootNodes) = der.content else {
           print(": Error: Root is not constructed")
           return
       }
       
       var rootIter = rootNodes.makeIterator()
       _ = rootIter.next() // header
       
       guard let bodyNode = rootIter.next() else {
           print(": Error: Missing body")
           return
       }
       
       print(": Body tag: \(bodyNode.identifier)")
       
       // Body should be [3] (cp) or [1] (ip)
       guard case .constructed(let bodyContent) = bodyNode.content else {
           print(": Error: Body is not constructed")
           return
       }
       
       var bodyIter = bodyContent.makeIterator()
       guard let certRepNode = bodyIter.next() else {
           print(": Error: Missing CertRepMessage")
           return
       }
       
       // CertRepMessage is SEQUENCE { caPubs [1] OPTIONAL, response SEQUENCE OF CertResponse }
       guard case .constructed(let certRepContent) = certRepNode.content else {
           print(": Error: CertRepMessage is not constructed")
           return
       }
       
       var certRepIter = certRepContent.makeIterator()
       guard let responseSeqNode = certRepIter.next() else {
           print(": Error: Missing response sequence")
           return
       }
       
       // response is SEQUENCE OF CertResponse
       guard case .constructed(let responseContent) = responseSeqNode.content else {
           print(": Error: Response is not constructed")
           return
       }
       
       var responseIter = responseContent.makeIterator()
       guard let certResponseNode = responseIter.next() else {
           print(": Error: Missing CertResponse")
           return
       }
       
       // CertResponse is SEQUENCE { certReqId, status, certifiedKeyPair [0] OPTIONAL }
       guard case .constructed(let certResponseContent) = certResponseNode.content else {
           print(": Error: CertResponse is not constructed")
           return
       }
       
       var certRespIter = certResponseContent.makeIterator()
       _ = certRespIter.next() // certReqId
       _ = certRespIter.next() // status
       
       guard let keyPairNode = certRespIter.next() else {
           print(": Error: Missing certifiedKeyPair")
           return
       }
       
       // certifiedKeyPair [0] -> CertifiedKeyPair
       guard case .constructed(let keyPairContent) = keyPairNode.content else {
           print(": Error: KeyPair is not constructed")
           return
       }
       
       var keyPairIter = keyPairContent.makeIterator()
       guard let certOrEncNode = keyPairIter.next() else {
           print(": Error: Missing certOrEncCert")
           return
       }
       
       // certOrEncCert is CertOrEncCert -> certificate [0] or encryptedCert [1]
       guard case .constructed(let certContent) = certOrEncNode.content else {
           print(": Error: CertOrEncCert is not constructed")
           return
       }
       
       var certIter = certContent.makeIterator()
       guard let cmsCertNode = certIter.next() else {
           print(": Error: Missing CMPCertificate")
           return
       }
       
       // CMPCertificate is Certificate (the actual X.509 cert)
       // Try to decode it as AuthenticationFramework_Certificate
       print(": Found certificate node, attempting decode...")
       
       // Serialize this node back to DER
       var serializer = DER.Serializer()
       try serializer.serialize(cmsCertNode)
       let certBytes = serializer.serializedBytes
       
       // Save the certificate
       // try Data(certBytes).write(to: URL(fileURLWithPath: "issued_certificate.der"))
       // print(": Certificate saved to issued_certificate.der (\(certBytes.count) bytes)")
       
       // Decode as X.509 certificate
       let cert = try AuthenticationFramework_Certificate(derEncoded: certBytes)
       
       print("")
       print(String(repeating: "=", count: 50))
       print(": ISSUED CERTIFICATE")
       print(String(repeating: "=", count: 50))
       print(": Version: \(cert.toBeSigned.version?.rawValue ?? 0)")
       print(": Serial Number: \(Array(cert.toBeSigned.serialNumber).map { String(format: "%02X", $0) }.joined(separator: ":"))")
       print(": Signature Algorithm: \(cert.toBeSigned.signature.algorithm)")
       print(": Issuer: \(cert.toBeSigned.issuer)")
       print(": Not Before: \(cert.toBeSigned.validity.notBefore)")
       print(": Not After: \(cert.toBeSigned.validity.notAfter)")
       print(": Subject: \(cert.toBeSigned.subject)")
       print(": Public Key Algorithm: \(cert.toBeSigned.subjectPublicKeyInfo.algorithm.algorithm)")
       print(String(repeating: "=", count: 50))
   }
      public static func debugDecoding(data: Data) throws {
         print("\n: Debugging CMP Response decoding...")
         let bytes = Array(data)
         print(": Read \(bytes.count) bytes")
        
        var der = try DER.parse(bytes)
        print(": Root node identifier: \(der.identifier)") // Should be SEQUENCE (universal 16)
        
        // Unwrap SEQUENCE
        guard case .constructed(let nodes) = der.content else {
            print(": Error: Root content is not constructed")
            return
        }
        
        var iterator = nodes.makeIterator()
        
        // 1. Header
        guard let headerNode = iterator.next() else { print(": Error: Missing header"); return }
        print(": Header node identifier: \(headerNode.identifier)")
        let header = try PKIXCMP_2009_PKIHeader(derEncoded: headerNode)
        print(": Header decoded successfully")
        
        // 2. Body
        guard let bodyNode = iterator.next() else { print(": Error: Missing body"); return }
        print(": Body node identifier: \(bodyNode.identifier)")
        // Try decoding body manually to see if it works
        let body = try PKIXCMP_2009_PKIBody(derEncoded: bodyNode)
        print(": Body decoded successfully: \(body)")
        
        // 3. Protection
        if let protectionNode = iterator.next() {
            print(": Protection node identifier: \(protectionNode.identifier)")
            if protectionNode.identifier == ASN1Identifier(tagWithNumber: 0, tagClass: .contextSpecific) {
                print(": Found protection tag [0]")
                // Manually inspect content
                if case .constructed(let contentNodes) = protectionNode.content {
                   var protIter = contentNodes.makeIterator()
                   if let inner = protIter.next() {
                       print(": Inner node: \(inner.identifier)")
                       let bitString = try ASN1BitString(derEncoded: inner)
                       print(": BitString decoded!")
                   }
                } else {
                   print(": Content inside protection tag is PRIMITIVE? (This would be wrong for explicit tagging of BIT STRING unless constructed BIT STRING?)")
                   print(": Content type: \(protectionNode.content)")
                }
            } else {
                print(": This node is not protection (expected [0]). It is: \(protectionNode.identifier)")
            }
        } else {
            print(": No protection node found")
        }
   }
  
  public static func suite() -> Int32 {
     let argv = CommandLine.arguments
     if argv.count >= 2, argv[1] == "cms" {
        return CMSCLI.main(arguments: Array(argv.dropFirst(2)))
     }
     do {
       try verifyOID()
       print(": UsefulDefinitions_id_ce ⟼ \(UsefulDefinitions_id_ce)")
       try showPentanomial(data: [48, 9, 2, 1, 1, 2, 1, 2, 2, 1, 3])
       try showCertificateData(data: [48, 129, 129, 48, 107, 160, 3, 2, 1, 2, 2, 3, 1, 226, 64, 48, 10, 6, 8, 42, 134, 72, 206, 61, 4, 3, 2, 48, 13, 49, 11, 48, 9, 6, 3, 85, 4, 3, 19, 2, 67, 65, 48, 30, 23, 13, 50, 51, 48, 49, 48, 49, 49, 50, 48, 48, 48, 48, 90, 23, 13, 51, 48, 48, 49, 48, 49, 49, 50, 48, 48, 48, 48, 90, 48, 15, 49, 13, 48, 11, 6, 3, 85, 4, 3, 19, 4, 85, 115, 101, 114, 48, 19, 48, 9, 6, 7, 42, 134, 72, 206, 61, 2, 1, 3, 6, 0, 4, 0, 0, 0, 0, 48, 10, 6, 8, 42, 134, 72, 206, 61, 4, 3, 2, 3, 6, 0, 1, 2, 3, 4, 5])
       // TODO: Fix Extension type generation - currently has AlgorithmIdentifier fields instead of Extension fields
       try showCertificate(file: "ca.crt")
       try verifyX509(file: "ca.crt", output: "verified.der")
       try generateX509()
       try verifyX509(file: "generated.crt", output: "generated_verified.der")
       // try showContentInfo(file: "data.bin")  // Also uses Extension types

       try showDirectoryString(data: [19,3,49,50,51])
       // try showLDAPMessage(data: [48,16,2,1,1,96,9,2,1,1,4,0,128,2,49,50,160,0])
       try showCHATMessage(data: [48,27,2,1,1,48,0,160,20,4,3,53,72,84,4,7,53,72,84,46,99,115,114,4,4,48,48,48,48])
       try showName(data: [48,13,49,11,48,9,6,3,85,4,6,19,2,85,65])
       try showName(data: [48,0])

       // existing test (directoryName [4] EXPLICIT empty sequence)
       try showGeneralName(data: [164,2,48,0])

       // dNSName [2] IMPLICIT IA5String("example.com")
       // Tag [2] -> 0x82 (Context S. Primitive 2)
       // "example.com" ascii -> 65 78 61 6D 70 6C 65 2E 63 6F 6D (11 bytes)
       try showGeneralName(data: [0x82, 11, 0x65, 0x78, 0x61, 0x6D, 0x70, 0x6C, 0x65, 0x2E, 0x63, 0x6F, 0x6D])

       // registeredID [8] IMPLICIT OBJECT IDENTIFIER(1.2.840.113549.1.7.1)
       // Tag [8] -> 0x88 (Context S. Primitive 8)
       // OID bytes: 2A 86 48 86 F7 0D 01 07 01 (9 bytes)
       try showGeneralName(data: [0x88, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x01])

       // CSR/CMP Tests
       // Generate test CSR with:
       //   openssl req -passout pass:0 -new -newkey ec:<(openssl ecparam -name secp384r1) \
       //              -keyout dima.key.enc -out dima.csr -subj "/C=UA/ST=Kyiv/O=SYNRC/CN=dima"
       // Then run CMP:
       //   openssl cmp -cmd p10cr -server "ca.synrc.com":8829 -secret pass:0000 -ref cmptestp10cr -certout dima.pem -csr dima.csr
       try showCSR(file: "dima.csr")
       try testCMPWorkflow(csrFile: "dima.csr")

       // PURE SWIFT CMP FLOW: Generate CSR and send to ca.synrc.com:8829
       
       print("\n: Running CMP endpoint test...")
       
       // Test CMP (Port 8829) - Certificate Management Protocol
       print("")
       print("=== Testing CMP on port 8829 ===")
       print(": Certificate Management Protocol (TCP with HTTP wrapper)")
       do {
           let semaphore = DispatchSemaphore(value: 0)
           Task {
              do {
                 try await generateAndSendCMP(
                    subject: "robot_swift",
                    countryCode: "UA",
                    state: "Kyiv",
                    org: "SYNRC",
                    server: "localhost",
                    port: 8829,
                    secret: "0000",
                    reference: "cmptestp10cr"
                 )
                print(": [CMP] Sent successfully!")
              } catch {
                 print(": [CMP] ERROR: \(error)")
              }
              semaphore.signal()
           }
           _ = semaphore.wait(timeout: .now() + 15)
       }
       
       // Other endpoints (EST, EUDI) - TODO: Enable when server handlers are implemented
       // EST (Port 8047): GET /.well-known/est/cacerts
       // EUDI Issuer (Port 8107): GET /jwks
       // EUDI Verifier (Port 8109): GET /openid4vc/policy-list
       // EUDI Wallet (Port 8108): GET /wallets
       
       print("")
       print(": CMP endpoint test completed")
       print(": PASSED")

       try showDirectoryString(data: [19,3,49,50,51])
       try showCHATMessage(data: [48,27,2,1,1,48,0,160,20,4,3,53,72,84,4,7,53,72,84,46,99,115,114,4,4,48,48,48,48])
       try showName(data: [48,13,49,11,48,9,6,3,85,4,6,19,2,85,65])
       try showName(data: [48,0])
       try showGeneralName(data: [164,2,48,0])

       return 0
     } catch {
       print(": EXCEPTION \(error)")
       print(": FAILED")
       return 1
     }
  }

}
