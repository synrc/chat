defmodule CHAT.CRYPTO do

    # RSA GnuPG S/MIME support
    # gpgsm --list-keys
    # gpgsm --list-secret-keys
    # gpgsm -r 0xD3C8F78A -e CNAME > cms.bin
    # gpgsm -u 0xD3C8F78A -d cms.bin
    # gpgsm --export-secret-key-p12 0xD3C8F78A > pfx-p12.bin
    # openssl pkcs12 -in pfx-p12.bin -nokeys -out public.pem
    # openssl pkcs12 -in pfx-p12.bin -nocerts -nodes -out private.pem

    # ECC openssl cms support
    # openssl cms -decrypt -in encrypted.txt -inkey client.key -recip client.pem
    # openssl cms -encrypt -aes256 -in message.txt -out encrypted.txt \
    #                      -recip client.pem -keyopt ecdh_kdf_md:sha256

    def e(x,y),       do: :erlang.element(x,y)
    def privat(name), do: e(3,:public_key.pem_entry_decode(readPEM("priv/certs/",name)))
    def public(name), do: e(3,e(8, e(2, :public_key.pem_entry_decode(readPEM("priv/certs/",name)))))
    def readPEM(folder, name),     do: hd(:public_key.pem_decode(e(2, :file.read_file(folder <> name))))
    def shared(pub, key, scheme),  do: :crypto.compute_key(:ecdh, pub, key, scheme)
    def eccCMS(ukm, len), do: {:'ECC-CMS-SharedInfo',
        {:'KeyWrapAlgorithm',{2,16,840,1,101,3,4,1,45},:asn1_NOVALUE}, ukm, <<len::32>>}

    def testDecryptCMS() do
        cms = testSMIME()
        :io.format 'CMS: ~p~n', [cms]
        {privateKey,_} = testPrivateKey()
        {:'ECPrivateKey',_,privateKeyBin,{:namedCurve,schemeOID},_,_} = privateKey
        decryptCMS(cms, privateKeyBin, schemeOID)
    end

    def testDecryptRSA() do
        cms = testRSA()
        :io.format 'CMS: ~p~n', [cms]
        {schemeOID,privateKeyBin} = testPrivateKeyRSA()
        decryptCMS(cms, privateKeyBin, schemeOID)
    end

    def decodeData(enc, data, unwrap, iv) do
        case enc do
           :'id-aes256-CBC' -> CA.AES.decrypt(:aes_256_cbc, data, unwrap, iv)
           :'id-aes256-GCM' -> CA.AES.decrypt(:aes_256_gcm, data, unwrap, iv)
           :'id-aes256-ECB' -> CA.AES.decrypt(:aes_256_ecb, data, unwrap, iv)
        end
    end

    # ECC KDF AES-KW

    def kari(kari, privateKeyBin, schemeOID, encOID, data, iv) do
        {:'KeyAgreeRecipientInfo',:v3,{_,{_,_,publicKey}},ukm,{_,kdfOID,_},[{_,_,encryptedKey}]} = kari
        {scheme,_}  = CA.ALG.lookup(schemeOID)
        {kdf,_}     = CA.ALG.lookup(kdfOID)
        {enc,_}     = CA.ALG.lookup(encOID)
        sharedKey   = shared(publicKey,privateKeyBin,scheme)
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

    # RSA

    def ktri(ktri, privateKeyBin, encOID, data, iv) do
        {:'KeyTransRecipientInfo',_vsn,_,{_,schemeOID,_},key} = ktri
        {:rsaEncryption,_} = CA.ALG.lookup schemeOID
        {enc,_} = CA.ALG.lookup(encOID)
        sessionKey = :public_key.decrypt_private(key, privateKeyBin)
        res = decodeData(enc, data, sessionKey, iv)
        {:ok, res}
    end

    def kekri(kekri, privateKeyBin, encOID, data, iv) do
        {:error, ["KEKRI not implemented",kekri, privateKeyBin, encOID, data, iv]}
    end

    def pwri(pwri, privateKeyBin, encOID, data, iv) do
        {:error, ["PWRI not implemented",pwri, privateKeyBin, encOID, data, iv]}
    end

    def decryptCMS(cms, privateKeyBin, schemeOID) do
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
                                      _ -> pwri(kekri, privateKeyBin, encOID, data, iv)
                                   end
                              _ -> kekri(kekri, privateKeyBin, encOID, data, iv)
                           end
                     _ -> ktri(ktri, privateKeyBin, encOID, data, iv)
                   end
              _ -> kari(kari, privateKeyBin, schemeOID, encOID, data, iv)
        end
    end

    def testPrivateKey() do
        privateKey = :public_key.pem_entry_decode(readPEM("priv/certs/","client.key"))
        privateKeyBin = e(3, privateKey)
        {privateKey,privateKeyBin}
    end

    def testPrivateKeyRSA() do
        {:ok,bin} = :file.read_file("priv/rsa-cms.key")
        pki = :public_key.pem_decode(bin)
        [{:PrivateKeyInfo,_,_}] = pki
        rsa = :public_key.pem_entry_decode(hd(pki))
        {:RSAPrivateKey,:'two-prime',_n,_e,_d,_,_,_,_,_,_} = rsa
        {rsa,rsa}
    end

    def testSMIME() do
        {:ok,base} = :file.read_file "priv/certs/encrypted.txt" ; [_,s] = :string.split base, "\n\n"
        x = :base64.decode s
        :'CryptographicMessageSyntax-2010'.decode(:ContentInfo, x)
    end

    def testRSA() do
        {:ok,x} = :file.read_file "priv/rsa-cms.bin"
        :'CryptographicMessageSyntax-2010'.decode(:ContentInfo, x)
    end

    def testCMS() do
        privateKey = privat "client.key"
        :io.format '~p~n', [:public_key.pem_entry_decode(readPEM("priv/certs/","client.key"))]
        scheme = :secp384r1
        {_,{:ContentInfo,_,{:EnvelopedData,_,_,x,{:EncryptedContentInfo,_,{_,_,{_,iv}},data},_}}} = testSMIME()
        [{:kari,{_,:v3,{_,{_,_,publicKey}},ukm,_,[{_,_,encryptedKey}]}}|_] = x
        sharedKey    = shared(publicKey,privateKey,scheme)
        {_,content}  =  :'CMSECCAlgs-2009-02'.encode(:'ECC-CMS-SharedInfo', eccCMS(ukm,256))
        kdf          = KDF.derive(:sha256, sharedKey, 32, content)
        unwrap       = :aes_kw.unwrap(encryptedKey, kdf)
        CA.AES.decrypt(:aes_256_cbc, data, unwrap, :binary.part(iv,2,16))
    end

end