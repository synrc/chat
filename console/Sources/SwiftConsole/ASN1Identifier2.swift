import SwiftASN1

public struct ASN1Identifier2 {
//    public static let boolean            = ASN1Identifier(tagWithNumber: 0x01, tagClass: TagClass(topByteInWireFormat: 0x01))
//    public static let integer            = ASN1Identifier(tagWithNumber: 0x02, tagClass: TagClass(topByteInWireFormat: 0x02))
//    public static let bitString          = ASN1Identifier(tagWithNumber: 0x03, tagClass: TagClass(topByteInWireFormat: 0x03))
//    public static let octetString        = ASN1Identifier(tagWithNumber: 0x04, tagClass: TagClass(topByteInWireFormat: 0x04))
//    public static let null               = ASN1Identifier(tagWithNumber: 0x05, tagClass: TagClass(topByteInWireFormat: 0x05))
    public static let sequenceOf         = ASN1Identifier(tagWithNumber: 16, tagClass: ASN1Identifier.TagClass.universal)
    public static let setOf              = ASN1Identifier(tagWithNumber: 17, tagClass: ASN1Identifier.TagClass.universal)
//    public static let sequence           = ASN1Identifier(tagWithNumber: 0x30, tagClass: TagClass(topByteInWireFormat: 0x30))
//    public static let set                = ASN1Identifier(tagWithNumber: 0x31, tagClass: TagClass(topByteInWireFormat: 0x31))
}
