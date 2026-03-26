import Foundation
import SwiftASN1

enum CMSCLI {
    static func main(arguments: [String]) -> Int32 {
        do {
            return try run(arguments: arguments)
        } catch {
            FileHandle.standardError.write(Data(String(describing: error).utf8))
            FileHandle.standardError.write(Data("\n".utf8))
            return 1
        }
    }

    private static func run(arguments: [String]) throws -> Int32 {
        guard !arguments.isEmpty else {
            throw "usage: cms unpack <cms.der|cms.pem> [--extract <out.bin>] [--rewrite <out.der>] | cms pack-data <payload.bin> <out.cms.der> | cms aes-encrypt -in <in.bin> -key <hex16bytes> -iv <hex16bytes> -out <encrypted.bin> | cms aes-decrypt -in <encrypted.bin> -key <hex16bytes> -iv <hex16bytes> -out <out.bin>"
        }

        let subcommand: String
        let args: [String]
        if arguments.first == "unpack" || arguments.first == "pack-data" || arguments.first == "aes-encrypt" || arguments.first == "aes-decrypt" {
            subcommand = arguments[0]
            args = Array(arguments.dropFirst())
        } else {
            subcommand = "unpack"
            args = arguments
        }

        switch subcommand {
        case "unpack":
            return try runUnpack(arguments: args)
        case "pack-data":
            return try runPackData(arguments: args)
        case "aes-encrypt":
            return try runAESEncrypt(arguments: args)
        case "aes-decrypt":
            return try runAESDecrypt(arguments: args)
        default:
            throw "unknown subcommand: \(subcommand)"
        }
    }

    private static func runAESEncrypt(arguments: [String]) throws -> Int32 {
        var inPath: String?
        var keyHex: String?
        var ivHex: String?
        var outPath: String?

        var idx = 0
        while idx < arguments.count {
            let arg = arguments[idx]
            switch arg {
            case "-in":
                idx += 1
                guard idx < arguments.count else { throw "-in requires a path" }
                inPath = arguments[idx]
            case "-key":
                idx += 1
                guard idx < arguments.count else { throw "-key requires hex" }
                keyHex = arguments[idx]
            case "-iv":
                idx += 1
                guard idx < arguments.count else { throw "-iv requires hex" }
                ivHex = arguments[idx]
            case "-out":
                idx += 1
                guard idx < arguments.count else { throw "-out requires a path" }
                outPath = arguments[idx]
            default:
                throw "unexpected argument: \(arg)"
            }
            idx += 1
        }

        guard let inPath, let keyHex, let ivHex, let outPath else {
            throw "usage: cms aes-encrypt -in <in.bin> -key <hex16bytes> -iv <hex16bytes> -out <encrypted.bin>"
        }

        let key = try parseHex(keyHex)
        let iv = try parseHex(ivHex)
        guard key.count == 16 else { throw "-key must be 16 bytes (32 hex chars)" }
        guard iv.count == 16 else { throw "-iv must be 16 bytes (32 hex chars)" }

        let plaintext = try Data(contentsOf: URL(fileURLWithPath: inPath))
        let ciphertext = try AES128CBC.encrypt(plaintext: plaintext, key: key, iv: iv)
        try ciphertext.write(to: URL(fileURLWithPath: outPath))
        print("wrote: \(outPath)")
        return 0
    }

    private static func runAESDecrypt(arguments: [String]) throws -> Int32 {
        var inPath: String?
        var keyHex: String?
        var ivHex: String?
        var outPath: String?

        var idx = 0
        while idx < arguments.count {
            let arg = arguments[idx]
            switch arg {
            case "-in":
                idx += 1
                guard idx < arguments.count else { throw "-in requires a path" }
                inPath = arguments[idx]
            case "-key":
                idx += 1
                guard idx < arguments.count else { throw "-key requires hex" }
                keyHex = arguments[idx]
            case "-iv":
                idx += 1
                guard idx < arguments.count else { throw "-iv requires hex" }
                ivHex = arguments[idx]
            case "-out":
                idx += 1
                guard idx < arguments.count else { throw "-out requires a path" }
                outPath = arguments[idx]
            default:
                throw "unexpected argument: \(arg)"
            }
            idx += 1
        }

        guard let inPath, let keyHex, let ivHex, let outPath else {
            throw "usage: cms aes-decrypt -in <encrypted.bin> -key <hex16bytes> -iv <hex16bytes> -out <out.bin>"
        }

        let key = try parseHex(keyHex)
        let iv = try parseHex(ivHex)
        guard key.count == 16 else { throw "-key must be 16 bytes (32 hex chars)" }
        guard iv.count == 16 else { throw "-iv must be 16 bytes (32 hex chars)" }

        let ciphertext = try Data(contentsOf: URL(fileURLWithPath: inPath))
        let plaintext = try AES128CBC.decrypt(ciphertext: ciphertext, key: key, iv: iv)
        try plaintext.write(to: URL(fileURLWithPath: outPath))
        print("wrote: \(outPath)")
        return 0
    }

    private static func parseHex(_ s: String) throws -> Data {
        let bytes = Array(s.utf8)
        guard bytes.count % 2 == 0 else {
            throw "hex string must have even length"
        }

        func nibble(_ c: UInt8) throws -> UInt8 {
            switch c {
            case UInt8(ascii: "0")...UInt8(ascii: "9"):
                return c - UInt8(ascii: "0")
            case UInt8(ascii: "a")...UInt8(ascii: "f"):
                return 10 + (c - UInt8(ascii: "a"))
            case UInt8(ascii: "A")...UInt8(ascii: "F"):
                return 10 + (c - UInt8(ascii: "A"))
            default:
                throw "invalid hex character"
            }
        }

        var out = Data()
        out.reserveCapacity(bytes.count / 2)
        var i = 0
        while i < bytes.count {
            let hi = try nibble(bytes[i])
            let lo = try nibble(bytes[i + 1])
            out.append((hi << 4) | lo)
            i += 2
        }
        return out
    }

    private struct AES128CBC {
        static func encrypt(plaintext: Data, key: Data, iv: Data) throws -> Data {
            guard key.count == 16 else {
                throw "AES-128 key must be 16 bytes"
            }
            guard iv.count == 16 else {
                throw "IV must be 16 bytes"
            }

            let aes = try AES128(key: key)

            let padded = pkcs7Pad(plaintext, blockSize: 16)
            var prev = [UInt8](iv)
            var out = [UInt8]()
            out.reserveCapacity(padded.count)

            let pt = [UInt8](padded)
            var offset = 0
            while offset < pt.count {
                var block = Array(pt[offset..<(offset + 16)])
                for i in 0..<16 {
                    block[i] ^= prev[i]
                }
                let ct = aes.encryptBlock(block)
                out.append(contentsOf: ct)
                prev = ct
                offset += 16
            }
            return Data(out)
        }

        static func decrypt(ciphertext: Data, key: Data, iv: Data) throws -> Data {
            guard ciphertext.count % 16 == 0 else {
                throw "ciphertext length must be multiple of 16"
            }
            guard key.count == 16 else {
                throw "AES-128 key must be 16 bytes"
            }
            guard iv.count == 16 else {
                throw "IV must be 16 bytes"
            }

            let aes = try AES128(key: key)

            var prev = [UInt8](iv)
            var out = [UInt8]()
            out.reserveCapacity(ciphertext.count)

            let ct = [UInt8](ciphertext)
            var offset = 0
            while offset < ct.count {
                let block = Array(ct[offset..<(offset + 16)])
                var plain = aes.decryptBlock(block)
                for i in 0..<16 {
                    plain[i] ^= prev[i]
                }
                out.append(contentsOf: plain)
                prev = block
                offset += 16
            }

            return try pkcs7Unpad(Data(out), blockSize: 16)
        }
    }

    private struct AES128 {
        private let roundKeys: [[UInt8]]

        init(key: Data) throws {
            guard key.count == 16 else {
                throw "AES-128 key must be 16 bytes"
            }
            self.roundKeys = AES128.expandKey([UInt8](key))
        }

        func decryptBlock(_ input: [UInt8]) -> [UInt8] {
            var state = input
            AES128.addRoundKey(&state, roundKeys[10])
            var round = 9
            while round >= 1 {
                AES128.invShiftRows(&state)
                AES128.invSubBytes(&state)
                AES128.addRoundKey(&state, roundKeys[round])
                AES128.invMixColumns(&state)
                round -= 1
            }
            AES128.invShiftRows(&state)
            AES128.invSubBytes(&state)
            AES128.addRoundKey(&state, roundKeys[0])
            return state
        }

        func encryptBlock(_ input: [UInt8]) -> [UInt8] {
            var state = input
            AES128.addRoundKey(&state, roundKeys[0])
            var round = 1
            while round <= 9 {
                AES128.subBytes(&state)
                AES128.shiftRows(&state)
                AES128.mixColumns(&state)
                AES128.addRoundKey(&state, roundKeys[round])
                round += 1
            }
            AES128.subBytes(&state)
            AES128.shiftRows(&state)
            AES128.addRoundKey(&state, roundKeys[10])
            return state
        }

        private static func expandKey(_ key: [UInt8]) -> [[UInt8]] {
            var w = [UInt8](repeating: 0, count: 176)
            for i in 0..<16 { w[i] = key[i] }

            var bytesGenerated = 16
            var rconIter = 1
            var temp = [UInt8](repeating: 0, count: 4)

            while bytesGenerated < 176 {
                for i in 0..<4 {
                    temp[i] = w[bytesGenerated - 4 + i]
                }

                if bytesGenerated % 16 == 0 {
                    temp = rotWord(temp)
                    temp = subWord(temp)
                    temp[0] ^= rcon[rconIter]
                    rconIter += 1
                }

                for i in 0..<4 {
                    w[bytesGenerated] = w[bytesGenerated - 16] ^ temp[i]
                    bytesGenerated += 1
                }
            }

            var roundKeys = [[UInt8]]()
            roundKeys.reserveCapacity(11)
            var i = 0
            while i < 176 {
                roundKeys.append(Array(w[i..<(i + 16)]))
                i += 16
            }
            return roundKeys
        }

        private static func rotWord(_ w: [UInt8]) -> [UInt8] {
            [w[1], w[2], w[3], w[0]]
        }

        private static func subWord(_ w: [UInt8]) -> [UInt8] {
            [sbox[Int(w[0])], sbox[Int(w[1])], sbox[Int(w[2])], sbox[Int(w[3])]]
        }

        private static func addRoundKey(_ state: inout [UInt8], _ roundKey: [UInt8]) {
            for i in 0..<16 {
                state[i] ^= roundKey[i]
            }
        }

        private static func subBytes(_ state: inout [UInt8]) {
            for i in 0..<16 {
                state[i] = sbox[Int(state[i])]
            }
        }

        private static func shiftRows(_ state: inout [UInt8]) {
            var tmp = state
            tmp[0] = state[0]
            tmp[4] = state[4]
            tmp[8] = state[8]
            tmp[12] = state[12]

            tmp[1] = state[5]
            tmp[5] = state[9]
            tmp[9] = state[13]
            tmp[13] = state[1]

            tmp[2] = state[10]
            tmp[6] = state[14]
            tmp[10] = state[2]
            tmp[14] = state[6]

            tmp[3] = state[15]
            tmp[7] = state[3]
            tmp[11] = state[7]
            tmp[15] = state[11]
            state = tmp
        }

        private static func mixColumns(_ state: inout [UInt8]) {
            for c in 0..<4 {
                let i = c * 4
                let a0 = state[i]
                let a1 = state[i + 1]
                let a2 = state[i + 2]
                let a3 = state[i + 3]
                state[i] = gmulEnc(0x02, a0) ^ gmulEnc(0x03, a1) ^ a2 ^ a3
                state[i + 1] = a0 ^ gmulEnc(0x02, a1) ^ gmulEnc(0x03, a2) ^ a3
                state[i + 2] = a0 ^ a1 ^ gmulEnc(0x02, a2) ^ gmulEnc(0x03, a3)
                state[i + 3] = gmulEnc(0x03, a0) ^ a1 ^ a2 ^ gmulEnc(0x02, a3)
            }
        }

        private static func invSubBytes(_ state: inout [UInt8]) {
            for i in 0..<16 {
                state[i] = invSbox[Int(state[i])]
            }
        }

        private static func invShiftRows(_ state: inout [UInt8]) {
            var tmp = state
            tmp[0] = state[0]
            tmp[4] = state[4]
            tmp[8] = state[8]
            tmp[12] = state[12]

            tmp[1] = state[13]
            tmp[5] = state[1]
            tmp[9] = state[5]
            tmp[13] = state[9]

            tmp[2] = state[10]
            tmp[6] = state[14]
            tmp[10] = state[2]
            tmp[14] = state[6]

            tmp[3] = state[7]
            tmp[7] = state[11]
            tmp[11] = state[15]
            tmp[15] = state[3]
            state = tmp
        }

        private static func invMixColumns(_ state: inout [UInt8]) {
            for c in 0..<4 {
                let i = c * 4
                let a0 = state[i]
                let a1 = state[i + 1]
                let a2 = state[i + 2]
                let a3 = state[i + 3]
                state[i] = gmul(0x0e, a0) ^ gmul(0x0b, a1) ^ gmul(0x0d, a2) ^ gmul(0x09, a3)
                state[i + 1] = gmul(0x09, a0) ^ gmul(0x0e, a1) ^ gmul(0x0b, a2) ^ gmul(0x0d, a3)
                state[i + 2] = gmul(0x0d, a0) ^ gmul(0x09, a1) ^ gmul(0x0e, a2) ^ gmul(0x0b, a3)
                state[i + 3] = gmul(0x0b, a0) ^ gmul(0x0d, a1) ^ gmul(0x09, a2) ^ gmul(0x0e, a3)
            }
        }

        private static func gmul(_ a: UInt8, _ b: UInt8) -> UInt8 {
            var aa = a
            var bb = b
            var p: UInt8 = 0
            for _ in 0..<8 {
                if (aa & 1) != 0 { p ^= bb }
                let hi = bb & 0x80
                bb <<= 1
                if hi != 0 { bb ^= 0x1b }
                aa >>= 1
            }
            return p
        }

        private static func gmulEnc(_ a: UInt8, _ b: UInt8) -> UInt8 {
            var aa = a
            var bb = b
            var p: UInt8 = 0
            for _ in 0..<8 {
                if (bb & 1) != 0 { p ^= aa }
                let hi = aa & 0x80
                aa <<= 1
                if hi != 0 { aa ^= 0x1b }
                bb >>= 1
            }
            return p
        }

        private static let rcon: [UInt8] = [
            0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36,
        ]

        private static let sbox: [UInt8] = [
            0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
            0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
            0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
            0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
            0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
            0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
            0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
            0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
            0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
            0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
            0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
            0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
            0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
            0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
            0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
            0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16,
        ]

        private static let invSbox: [UInt8] = [
            0x52,0x09,0x6a,0xd5,0x30,0x36,0xa5,0x38,0xbf,0x40,0xa3,0x9e,0x81,0xf3,0xd7,0xfb,
            0x7c,0xe3,0x39,0x82,0x9b,0x2f,0xff,0x87,0x34,0x8e,0x43,0x44,0xc4,0xde,0xe9,0xcb,
            0x54,0x7b,0x94,0x32,0xa6,0xc2,0x23,0x3d,0xee,0x4c,0x95,0x0b,0x42,0xfa,0xc3,0x4e,
            0x08,0x2e,0xa1,0x66,0x28,0xd9,0x24,0xb2,0x76,0x5b,0xa2,0x49,0x6d,0x8b,0xd1,0x25,
            0x72,0xf8,0xf6,0x64,0x86,0x68,0x98,0x16,0xd4,0xa4,0x5c,0xcc,0x5d,0x65,0xb6,0x92,
            0x6c,0x70,0x48,0x50,0xfd,0xed,0xb9,0xda,0x5e,0x15,0x46,0x57,0xa7,0x8d,0x9d,0x84,
            0x90,0xd8,0xab,0x00,0x8c,0xbc,0xd3,0x0a,0xf7,0xe4,0x58,0x05,0xb8,0xb3,0x45,0x06,
            0xd0,0x2c,0x1e,0x8f,0xca,0x3f,0x0f,0x02,0xc1,0xaf,0xbd,0x03,0x01,0x13,0x8a,0x6b,
            0x3a,0x91,0x11,0x41,0x4f,0x67,0xdc,0xea,0x97,0xf2,0xcf,0xce,0xf0,0xb4,0xe6,0x73,
            0x96,0xac,0x74,0x22,0xe7,0xad,0x35,0x85,0xe2,0xf9,0x37,0xe8,0x1c,0x75,0xdf,0x6e,
            0x47,0xf1,0x1a,0x71,0x1d,0x29,0xc5,0x89,0x6f,0xb7,0x62,0x0e,0xaa,0x18,0xbe,0x1b,
            0xfc,0x56,0x3e,0x4b,0xc6,0xd2,0x79,0x20,0x9a,0xdb,0xc0,0xfe,0x78,0xcd,0x5a,0xf4,
            0x1f,0xdd,0xa8,0x33,0x88,0x07,0xc7,0x31,0xb1,0x12,0x10,0x59,0x27,0x80,0xec,0x5f,
            0x60,0x51,0x7f,0xa9,0x19,0xb5,0x4a,0x0d,0x2d,0xe5,0x7a,0x9f,0x93,0xc9,0x9c,0xef,
            0xa0,0xe0,0x3b,0x4d,0xae,0x2a,0xf5,0xb0,0xc8,0xeb,0xbb,0x3c,0x83,0x53,0x99,0x61,
            0x17,0x2b,0x04,0x7e,0xba,0x77,0xd6,0x26,0xe1,0x69,0x14,0x63,0x55,0x21,0x0c,0x7d,
        ]
    }

    private static func pkcs7Unpad(_ data: Data, blockSize: Int) throws -> Data {
        guard !data.isEmpty else {
            throw "invalid padding"
        }
        guard blockSize > 0 && blockSize <= 255 else {
            throw "invalid block size"
        }
        let bytes = [UInt8](data)
        let padLen = Int(bytes[bytes.count - 1])
        guard padLen > 0 && padLen <= blockSize else {
            throw "invalid padding"
        }
        guard bytes.count >= padLen else {
            throw "invalid padding"
        }
        for i in 0..<padLen {
            if bytes[bytes.count - 1 - i] != UInt8(padLen) {
                throw "invalid padding"
            }
        }
        return data.prefix(data.count - padLen)
    }

    private static func pkcs7Pad(_ data: Data, blockSize: Int) -> Data {
        precondition(blockSize > 0 && blockSize <= 255)
        let padLen = blockSize - (data.count % blockSize)
        var out = data
        out.append(contentsOf: Array(repeating: UInt8(padLen), count: padLen))
        return out
    }

    private static func runUnpack(arguments: [String]) throws -> Int32 {
        var inputPath: String?
        var rewritePath: String?
        var extractPath: String?

        var idx = 0
        while idx < arguments.count {
            let arg = arguments[idx]
            if arg == "--rewrite" {
                idx += 1
                guard idx < arguments.count else {
                    throw "--rewrite requires a path"
                }
                rewritePath = arguments[idx]
            } else if arg == "--extract" {
                idx += 1
                guard idx < arguments.count else {
                    throw "--extract requires a path"
                }
                extractPath = arguments[idx]
            } else if inputPath == nil {
                inputPath = arg
            } else {
                throw "unexpected argument: \(arg)"
            }
            idx += 1
        }

        guard let inputPath else {
            throw "missing input file"
        }

        let url = URL(fileURLWithPath: inputPath)
        let raw = try Data(contentsOf: url)
        let der = try decodeMaybePEM(raw)

        if let ci = try? CryptographicMessageSyntax_2010_ContentInfo(derEncoded: Array(der)) {
            try handleCMS2010(contentInfo: ci, rewritePath: rewritePath, extractPath: extractPath)
            return 0
        }

        if let ci = try? CryptographicMessageSyntax_2009_ContentInfo(derEncoded: Array(der)) {
            try handleCMS2009(contentInfo: ci, rewritePath: rewritePath, extractPath: extractPath)
            return 0
        }

        throw "failed to decode CMS ContentInfo as 2010 or 2009"
    }

    private static func runPackData(arguments: [String]) throws -> Int32 {
        guard arguments.count == 2 else {
            throw "usage: cms pack-data <payload.bin> <out.cms.der>"
        }

        let payloadPath = arguments[0]
        let outPath = arguments[1]

        let payload = try Data(contentsOf: URL(fileURLWithPath: payloadPath))
        let payloadOctets = ASN1OctetString(contentBytes: ArraySlice(payload))

        var payloadSerializer = DER.Serializer()
        try payloadOctets.serialize(into: &payloadSerializer)

        let innerAny = try ASN1Any(derEncoded: payloadSerializer.serializedBytes)
        let contentType = try ASN1ObjectIdentifier(dotRepresentation: "1.2.840.113549.1.7.1")
        let contentInfo = CryptographicMessageSyntax_2010_ContentInfo(contentType: contentType, content: innerAny)

        var serializer = DER.Serializer()
        try contentInfo.serialize(into: &serializer)
        try Data(serializer.serializedBytes).write(to: URL(fileURLWithPath: outPath))
        print("wrote: \(outPath)")
        return 0
    }

    private static func handleCMS2010(contentInfo: CryptographicMessageSyntax_2010_ContentInfo, rewritePath: String?, extractPath: String?) throws {
        print("contentType: \(contentInfo.contentType)")

        let dataOID = try ASN1ObjectIdentifier(dotRepresentation: "1.2.840.113549.1.7.1")
        let signedDataOID = try ASN1ObjectIdentifier(dotRepresentation: "1.2.840.113549.1.7.2")
        if contentInfo.contentType == signedDataOID {
            let payloadDER = try serialize(any: contentInfo.content)
            let signedData = try CryptographicMessageSyntax_2010_SignedData(derEncoded: payloadDER)
            print("SignedData.version: \(signedData.version)")
            if let eContent = signedData.encapContentInfo.eContent {
                let bytes = Array(eContent.bytes)
                print("encapContentInfo.eContentType: \(signedData.encapContentInfo.eContentType)")
                print("encapContentInfo.eContent: \(bytes.count) bytes")
                if let s = String(bytes: bytes, encoding: .utf8) {
                    print("encapContentInfo.eContent(utf8): \(s)")
                }
                if let extractPath {
                    try Data(bytes).write(to: URL(fileURLWithPath: extractPath))
                    print("extracted: \(extractPath)")
                }
            }
        } else if contentInfo.contentType == dataOID {
            let payloadDER = try serialize(any: contentInfo.content)
            let data = try ASN1OctetString(derEncoded: payloadDER)
            let bytes = Array(data.bytes)
            print("data: \(bytes.count) bytes")
            if let extractPath {
                try Data(bytes).write(to: URL(fileURLWithPath: extractPath))
                print("extracted: \(extractPath)")
            }
        }

        if let rewritePath {
            var serializer = DER.Serializer()
            try contentInfo.serialize(into: &serializer)
            try Data(serializer.serializedBytes).write(to: URL(fileURLWithPath: rewritePath))
            print("rewrote: \(rewritePath)")
        }
    }

    private static func handleCMS2009(contentInfo: CryptographicMessageSyntax_2009_ContentInfo, rewritePath: String?, extractPath: String?) throws {
        print("contentType: \(contentInfo.contentType)")

        let dataOID = try ASN1ObjectIdentifier(dotRepresentation: "1.2.840.113549.1.7.1")
        let signedDataOID = try ASN1ObjectIdentifier(dotRepresentation: "1.2.840.113549.1.7.2")
        if contentInfo.contentType == signedDataOID {
            let payloadDER = try serialize(any: contentInfo.content)
            let signedData = try CryptographicMessageSyntax_2009_SignedData(derEncoded: payloadDER)
            print("SignedData.version: \(signedData.version)")
            if let eContent = signedData.encapContentInfo.eContent {
                let bytes = Array(eContent.bytes)
                print("encapContentInfo.eContentType: \(signedData.encapContentInfo.eContentType)")
                print("encapContentInfo.eContent: \(bytes.count) bytes")
                if let s = String(bytes: bytes, encoding: .utf8) {
                    print("encapContentInfo.eContent(utf8): \(s)")
                }
                if let extractPath {
                    try Data(bytes).write(to: URL(fileURLWithPath: extractPath))
                    print("extracted: \(extractPath)")
                }
            }
        } else if contentInfo.contentType == dataOID {
            let payloadDER = try serialize(any: contentInfo.content)
            let data = try ASN1OctetString(derEncoded: payloadDER)
            let bytes = Array(data.bytes)
            print("data: \(bytes.count) bytes")
            if let extractPath {
                try Data(bytes).write(to: URL(fileURLWithPath: extractPath))
                print("extracted: \(extractPath)")
            }
        }

        if let rewritePath {
            var serializer = DER.Serializer()
            try contentInfo.serialize(into: &serializer)
            try Data(serializer.serializedBytes).write(to: URL(fileURLWithPath: rewritePath))
            print("rewrote: \(rewritePath)")
        }
    }

    private static func serialize(any: ASN1Any) throws -> [UInt8] {
        var serializer = DER.Serializer()
        try any.serialize(into: &serializer)
        return serializer.serializedBytes
    }

    private static func decodeMaybePEM(_ data: Data) throws -> Data {
        guard let s = String(data: data, encoding: .utf8), s.contains("-----BEGIN") else {
            return data
        }

        let lines = s.split(whereSeparator: \.isNewline)
        var base64 = ""
        var inBlock = false
        for line in lines {
            if line.hasPrefix("-----BEGIN") {
                inBlock = true
                continue
            }
            if line.hasPrefix("-----END") {
                break
            }
            if inBlock {
                base64 += line
            }
        }

        guard let decoded = Data(base64Encoded: base64) else {
            throw "failed to decode PEM"
        }
        return decoded
    }
}
