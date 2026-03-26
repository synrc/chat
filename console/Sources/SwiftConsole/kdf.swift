import Foundation
import Crypto

public class KDF {

  public static func ceil(x: Int, y: Int) -> Int {
      if (x % y == 0) { return x / y } else { return x / y + 1 }
  }

  public static func keysize(alg: String) -> Int {
      switch (alg) {
          case "md5":    return 16
          case "sha1":   return 20
          case "sha224": return 28
          case "sha256": return 32
          case "sha384": return 48
          case "sha512": return 64
          default: return -1
      }
  }
/*
  public static func hash(alg: String, bin: Data) -> Data {
      switch (alg) {
          case "md5": return Data(Insecure.MD5.hash(data: bin).makeIterator())
          case "sha1": return Data(Insecure.SHA1.hash(data: bin).makeIterator())
          case "sha256": return Data(SHA256.hash(data: bin).makeIterator())
          case "sha384": return Data(SHA384.hash(data: bin).makeIterator())
          case "sha512": return Data(SHA512.hash(data: bin).makeIterator())
          default: return Data([])
      }
  }

  public static func derive(alg: String, key: Data, len: Int, data: Data) -> Data {
      let ceil = ceil(x: len, y: keysize(alg: alg))
      let seq = stride(from: ceil, to: 0, by: -1).map { $0 }
      var res = Data([])
      for item in seq {
          var iter = Data()
          iter.append(contentsOf: key)
          iter.append(contentsOf: Data([0,0,0,UInt8(item)]))
          iter.append(contentsOf: data)
          var kdf = KDF.hash(alg: alg, bin: iter)
          kdf.append(contentsOf: res)
          res = kdf
      }
      return res.subdata(in: 0 ..< len)
  }
*/

}
