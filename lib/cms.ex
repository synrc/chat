defmodule CMS do

    def decodeData(:'id-aes256-CBC', data, unwrap, iv), do: CA.AES.decrypt(:aes_256_cbc, data, unwrap, iv)
    def decodeData(:'id-aes256-GCM', data, unwrap, iv), do: CA.AES.decrypt(:aes_256_gcm, data, unwrap, iv)
    def decodeData(:'id-aes256-ECB', data, unwrap, iv), do: CA.AES.decrypt(:aes_256_ecb, data, unwrap, iv)
    def eccCMS(ukm, len), do: {:'ECC-CMS-SharedInfo',
        {:'KeyWrapAlgorithm',{2,16,840,1,101,3,4,1,45},:asn1_NOVALUE}, ukm, <<len::32>>}

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

    def decrypt(cms, {schemeOID, privateKeyBin}) do
        {_,{:ContentInfo,_,{:EnvelopedData,_,_,x,y,_}}} = cms
        {:EncryptedContentInfo,_,{_,encOID,{_,<<_::16,iv::binary>>}},data} = y
        case :proplists.get_value(:kari, x, []) do
          [] -> case :proplists.get_value(:ktri,  x, []) do
          [] -> case :proplists.get_value(:kekri, x, []) do
          [] -> case :proplists.get_value(:pwri,  x, []) do
          [] -> {:error, "Unknown Other Recepient Info"}
                pwri  -> pwri(pwri,   privateKeyBin, encOID, data, iv) end
                kekri -> kekri(kekri, privateKeyBin, encOID, data, iv) end
                ktri  -> ktri(ktri,   privateKeyBin, encOID, data, iv) end
                kari  -> kari(kari,   privateKeyBin, schemeOID, encOID, data, iv)
        end
    end

end