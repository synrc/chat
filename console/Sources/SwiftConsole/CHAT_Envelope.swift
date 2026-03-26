import SwiftASN1
import Foundation

@usableFromInline struct CHAT_Envelope: DERImplicitlyTaggable, Sendable {
    @inlinable static var defaultIdentifier: ASN1Identifier { .sequence }
    @usableFromInline var no: ArraySlice<UInt8>
    @usableFromInline var headers: [ASN1OctetString]
    @usableFromInline var body: CHAT_Protocol
    @inlinable init(no: ArraySlice<UInt8>, headers: [ASN1OctetString], body: CHAT_Protocol) {
        self.no = no
        self.headers = headers
        self.body = body

    }
    @inlinable init(derEncoded root: ASN1Node,
        withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(root, identifier: identifier) { nodes in
            let no: ArraySlice<UInt8> = try ArraySlice<UInt8>(derEncoded: &nodes)
            let headers: [ASN1OctetString] = try DER.sequence(of: ASN1OctetString.self, identifier: .sequence, nodes: &nodes)
            let body: CHAT_Protocol = try CHAT_Protocol(derEncoded: &nodes)

            return CHAT_Envelope(no: no, headers: headers, body: body)
        }
    }
    @inlinable func serialize(into coder: inout DER.Serializer,
        withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            try coder.serialize(no)
            try coder.serializeSequenceOf(headers)
            try coder.serialize(body)

        }
    }
}
