defmodule CHAT.ASN1 do

  def parse(file \\ "priv/proto/CHAT.asn1") do
      tokens = :asn1ct_tok.file "priv/proto/CHAT.asn1"
      :asn1ct_parser2.parse "priv/proto/CHAT.asn1", tokens
  end

end
