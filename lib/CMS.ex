defmodule CMS do

#   S/MIME Working Group: https://datatracker.ietf.org/wg/smime/documents/

#   Implementations MUST support key transport, key agreement, and
#   previously distributed symmetric key-encryption keys, as represented
#   by ktri, kari, and kekri, respectively.

#   Implementations MAY support the password-based key management as represented by pwri.
#   Implementations MAY support any other key management technique
#   such as Boneh-Franklin and Boneh-Boyen Identity-Based Encryption (RFC 5409)
#   or other SYNRC encryption techniques.

#   IETF: 5990, 5911, 5750--5754, 5652, 5408, 5409, 5275, 5126,
#   5035, 4853, 4490, 4262, 4134, 4056, 4010, 3850, 3851, 3852,
#   3854, 3855, 3657, 3560, 3565, 3537, 3394, 3369, 3370, 3274,
#   3114, 3278, 3218, 3211, 3217, 3183, 3185, 3125--3126, 3058,
#   2984, 2876, 2785, 2630, 2631, 2632, 2633, 5083, 5084, 2634.

    # ECC openssl cms support
    # openssl cms -decrypt -in encrypted.txt -inkey client.key -recip client.pem
    # openssl cms -encrypt -aes256 -in message.txt -out encrypted.txt \
    #                      -recip client.pem -keyopt ecdh_kdf_md:sha256

    # RSA GnuPG S/MIME support
    # gpgsm --list-keys
    # gpgsm --list-secret-keys
    # gpgsm -r 0xD3C8F78A -e CNAME > cms.bin
    # gpgsm -u 0xD3C8F78A -d cms.bin
    # gpgsm --export-secret-key-p12 0xD3C8F78A > key.bin
    # openssl pkcs12 -in key.bin -nokeys -out public.pem
    # openssl pkcs12 -in key.bin -nocerts -nodes -out private.pem

    # KEK openssl cms support
    # openssl cms -encrypt -secretkeyid 07 -secretkey 0123456789ABCDEF0123456789ABCDEF \
    #             -aes256 -in message.txt -out encrypted2.txt
    # openssl cms -decrypt -secretkeyid 07 -secretkey 0123456789ABCDEF0123456789ABCDEF \
    #             -in encrypted2.txt

    def e(x,y),           do: :erlang.element(x,y)
    def pem(name),    do: hd(:public_key.pem_decode(e(2,:file.read_file(name))))
    def eccCMS(ukm, len), do: {:'ECC-CMS-SharedInfo',
        {:'KeyWrapAlgorithm',{2,16,840,1,101,3,4,1,45},:asn1_NOVALUE}, ukm, <<len::32>>}

    def decodeData(enc, data, unwrap, iv) do
        case enc do
           :'id-aes256-CBC' -> CA.AES.decrypt(:aes_256_cbc, data, unwrap, iv)
           :'id-aes256-GCM' -> CA.AES.decrypt(:aes_256_gcm, data, unwrap, iv)
           :'id-aes256-ECB' -> CA.AES.decrypt(:aes_256_ecb, data, unwrap, iv)
        end
    end

    # CMS Codec KARI: ECC+KDF/ECB+AES/KW+256/CBC

    def kari(kari, privateKeyBin, schemeOID, encOID, data, iv) do
        {:'KeyAgreeRecipientInfo',:v3,{_,{_,_,publicKey}},ukm,{_,kdfOID,_},[{_,_,encryptedKey}]} = kari
        {scheme,_}  = CA.ALG.lookup(schemeOID)
        {kdf,_}     = CA.ALG.lookup(kdfOID)
        {enc,_}     = CA.ALG.lookup(encOID)
        sharedKey   = :crypto.compute_key(:ecdh,publicKey,privateKeyBin,scheme)
        {_,payload} =  :'CMSECCAlgs-2009-02'.encode(:'ECC-CMS-SharedInfo', eccCMS(ukm,256))
        derivedKDF  = case kdf do
           :'dhSinglePass-stdDH-sha512kdf-scheme' -> KDF.derive(:sha512, sharedKey, 32, payload)
           :'dhSinglePass-stdDH-sha384kdf-scheme' -> KDF.derive(:sha384, sharedKey, 32, payload)
           :'dhSinglePass-stdDH-sha256kdf-scheme' -> KDF.derive(:sha256, sharedKey, 32, payload)
        end
        unwrap = :aes_kw.unwrap(encryptedKey, derivedKDF)
        res = decodeData(enc, data, unwrap, iv)
        {:ok, res}
    end

    # CMS Codec KTRI: RSA+RSAES-OAEP

    def ktri(ktri, privateKeyBin, encOID, data, iv) do
        {:'KeyTransRecipientInfo',_vsn,_,{_,schemeOID,_},key} = ktri
        {:rsaEncryption,_} = CA.ALG.lookup schemeOID
        {enc,_} = CA.ALG.lookup(encOID)
        sessionKey = :public_key.decrypt_private(key, privateKeyBin)
        res = decodeData(enc, data, sessionKey, iv)
        {:ok, res}
    end

    # CMS Codec KEKRI: KEK+AES-KW+CBC

    def kekri(kekri, privateKeyBin, encOID, data, iv) do
        {:'KEKRecipientInfo',_vsn,_,{_,kea,_},encryptedKey} = kekri
        _ = CA.ALG.lookup(kea)
        {enc,_} = CA.ALG.lookup(encOID)
        unwrap = :aes_kw.unwrap(encryptedKey,privateKeyBin)
        res = decodeData(enc, data, unwrap, iv)
        {:ok, res}
    end

    def pwri(pwri, privateKeyBin, encOID, data, iv) do
        {:error, ["PWRI not implemented",pwri, privateKeyBin, encOID, data, iv]}
    end

    def decryptCMS(cms, {schemeOID, privateKeyBin}) do
        {_,{:ContentInfo,_,{:EnvelopedData,_,_,x,y,_}}} = cms
        {:EncryptedContentInfo,_,{_,encOID,{_,<<_::16,iv::binary>>}},data} = y
        kari  = :proplists.get_value(:kari,  x, [])
        ktri  = :proplists.get_value(:ktri,  x, [])
        kekri = :proplists.get_value(:kekri, x, [])
        pwri  = :proplists.get_value(:pwri,  x, [])
        case kari do
             [] -> case ktri do
                     [] -> case kekri do
                             [] -> case pwri do
                                      [] -> {:error, "Unknown Other Recepient Info"}
                                      _ -> pwri(pwri, privateKeyBin, encOID, data, iv)
                                   end
                              _ -> kekri(kekri, privateKeyBin, encOID, data, iv)
                           end
                     _ -> ktri(ktri, privateKeyBin, encOID, data, iv)
                   end
              _ -> kari(kari, privateKeyBin, schemeOID, encOID, data, iv)
        end
    end

    def testDecryptECC(), do: decryptCMS(testECC(), testPrivateKeyECC())
    def testDecryptKEK(), do: decryptCMS(testKEK(), testPrivateKeyKEK())
    def testDecryptRSA(), do: decryptCMS(testRSA(), testPrivateKeyRSA())
    def test(),           do:
       [
          testDecryptECC(),
          testDecryptKEK(),
          testDecryptRSA(),
          testCMS(),
       ]

    def testPrivateKeyECC() do
        privateKey = :public_key.pem_entry_decode(pem("priv/certs/client.key"))
        {:'ECPrivateKey',_,privateKeyBin,{:namedCurve,schemeOID},_,_} = privateKey
        {schemeOID,privateKeyBin}
    end

    def testPrivateKeyKEK() do
        {:kek, :binary.decode_hex("0123456789ABCDEF0123456789ABCDEF")}
    end

    def testPrivateKeyRSA() do
        {:ok,bin} = :file.read_file("priv/rsa-cms.key")
        pki = :public_key.pem_decode(bin)
        [{:PrivateKeyInfo,_,_}] = pki
        rsa = :public_key.pem_entry_decode(hd(pki))
        {:'RSAPrivateKey',:'two-prime',_n,_e,_d,_,_,_,_,_,_} = rsa
        {:rsaEncryption,rsa}
    end

    def testECC() do
        {:ok,base} = :file.read_file "priv/certs/encrypted.txt"
        [_,s] = :string.split base, "\n\n"
        x = :base64.decode s
        :'CryptographicMessageSyntax-2010'.decode(:ContentInfo, x)
    end

    def testKEK() do
        {:ok,base} = :file.read_file "priv/certs/encrypted2.txt"
        [_,s] = :string.split base, "\n\n"
        x = :base64.decode s
        :'CryptographicMessageSyntax-2010'.decode(:ContentInfo, x)
    end

    def testRSA() do
        {:ok,x} = :file.read_file "priv/rsa-cms.bin"
        :'CryptographicMessageSyntax-2010'.decode(:ContentInfo, x)
    end

    def testCMS() do
        privateKey = e(3,:public_key.pem_entry_decode(pem("priv/certs/client.key")))
        scheme = :secp384r1
        {_,{:ContentInfo,_,{:EnvelopedData,_,_,x,{_,_,{_,_,{_,<<_::16,iv::binary>>}},data},_}}} = testECC()
        [{:kari,{_,:v3,{_,{_,_,publicKey}},ukm,_,[{_,_,encryptedKey}]}}|_] = x
        sharedKey   = :crypto.compute_key(:ecdh,publicKey,privateKey,scheme)
        {_,content}  =  :'CMSECCAlgs-2009-02'.encode(:'ECC-CMS-SharedInfo', eccCMS(ukm,256))
        kdf          = KDF.derive(:sha256, sharedKey, 32, content)
        unwrap       = :aes_kw.unwrap(encryptedKey, kdf)
        CA.AES.decrypt(:aes_256_cbc, data, unwrap, iv)
    end

end