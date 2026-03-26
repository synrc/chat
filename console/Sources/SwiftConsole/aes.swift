import Foundation
import Crypto
/*
public struct wrapVector {
    let kek: SymmetricKey
    let key: SymmetricKey
    let wrap: Data
}
*/
extension Data {
    init?(hex: String) {
        var bytes = [UInt8]()
        var index = hex.startIndex
        while index < hex.endIndex {
            let string = hex[index..<hex.index(index, offsetBy: 2)]
            if let byte = UInt8(string, radix: 16)
                 { bytes.append(byte) } else { return nil }
            index = hex.index(index, offsetBy: 2)
        }
        self.init(bytes)
    }
}

public class Block {
    public static var IV: UInt64 = 0xA6A6A6A6A6A6A6A6
/*
    public static var vector: [wrapVector] = [
       wrapVector(
           kek: SymmetricKey(data: Data(hex: "f59782f1dceb0544a8da06b34969b9212b55ce6dcbdd0975a33f4b3f88b538da")!),
           key: SymmetricKey(data: Data(hex: "73d33060b5f9f2eb5785c0703ddfa704")!),
           wrap: Data(hex: "2e63946ea3c090902fa1558375fdb2907742ac74e39403fc")!), ]
    public static func testKeyWrap() throws {
       try vector.forEach { e in
           let kek = SymmetricKey(data: e.kek)
           let wrapped = try AES.KeyWrap.wrap(e.key, using: kek) // = e.wrap
           let unwrapped = try AES.KeyWrap.unwrap(wrapped, using: kek) // e.key
           print(": KEK \(e.kek)")
           print(": KEY \(e.key)")
           print(": WRAP \(Array(e.wrap))")
           print(": Wrapped \(Array(wrapped))")
           print(": Unwrapped \(unwrapped)")
       }
    }
*/
}

