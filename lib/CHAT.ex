defmodule CHAT.CRYPTO do

    def filterSYNRCapps() do
        f = fn {x,_,_} when x == :n2o or x == :chat or x == :bpe or x== :ca or x == :ns or x == :kvs or x == :ldap or
                            x == :inets or x == :compiler or x == :stdlib or x == :kernel or x == :mnesia or x == :crypto  -> true
                          _ -> false end
        :lists.filter(f, :application.which_applications)
    end

    def testCMSX509() do
        {_,base} = :file.read_file "priv/mosquitto/encrypted.txt"
        bin = :base64.decode base
        :file.write_file "priv/mosquitto/encrypted.bin", bin
        :'CryptographicMessageSyntax-2009'.decode(:ContentInfo, bin)
    end

    def test() do
        key = privat "client"
        public = public "client"
        t = testCMSX509
        {_,{:ContentInfo,_,{:EnvelopedData,_,_,x,{:EncryptedContentInfo,_,{_,params},cipher},_}}} = t
        [kari: {_,:v3,{_,{_,_,pub}},_,_,[{_,_,data}]}] = x
        {pub,public,data,key,cipher,t}
        data
    end

    def decrypt(cipher, secret) do
        key = :binary.part(secret, 0, 32)
        <<iv::binary-16, tag::binary-16, bin::binary>> = cipher
        :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, bin, "AES256GCM", tag, false)
    end

    def decrypt2(cipher, secret, iv) do
        secret = :binary.part(secret, 0, 32)
        :crypto.crypto_one_time(:aes_256_cbc,secret,iv,cipher,[{:encrypt,false}])
    end

    def encrypt(plaintext, secret) do
        key = :binary.part(secret, 0, 32)
        iv = :crypto.strong_rand_bytes(16)
        {cipher, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, "AES256GCM", true)
        iv <> tag <> cipher
    end

    def public(name) do
        prefix = "priv/mosquitto/"
        pub = :public_key.pem_entry_decode(:erlang.hd(:public_key.pem_decode(:erlang.element(2, :file.read_file(prefix <> name <> ".pem")))))
        x = :erlang.element(3,:erlang.element(8, :erlang.element(2, pub)))
        {pub,x}
    end

    def privat(name) do
        prefix = "priv/mosquitto/"
        key = :public_key.pem_entry_decode(:erlang.hd(:public_key.pem_decode(:erlang.element(2, :file.read_file(prefix <> name <> ".key")))))
        {_,_,keyBin,_,_,_} = key
        {key,keyBin}
    end

    def shared(pub, key, scheme), do: :crypto.compute_key(:ecdh, pub, key, scheme)

    def testSECP384R1() do # SECP384r1
        scheme = :secp384r1
        {_,aliceP} = public "client"
        {_,aliceK} = privat "client"
        {_,maximP} = public "server"
        {_,maximK} = privat "server"
        cms = testCMSX509
        {_,{:ContentInfo,_,{:EnvelopedData,_,_,x,{:EncryptedContentInfo,_,{_,_,{_,msg}},iv},_}}} = cms
        [kari: {_,:v3,{_,{_,_,publicKey}},_,_,[{_,_,encryptedKey}]}] = x
        maximS = shared(aliceP,maximK,scheme)
        aliceS = shared(maximP,aliceK,scheme)
        key = decrypt2(encryptedKey, aliceS, :binary.part(iv,0,16))
        :io.format('Public Key: ~tp~n',[publicKey])
        :io.format('Encryption Key: ~tp~n',[key])
        text = decrypt2(msg, key, iv)
        :io.format('Decoded Message: ~ts~n',[text])
       cms
    end

    def checkSECP384R1() do # SECP384r1
        scheme = :secp384r1
        {_,aliceP} = public "client"
        {_,aliceK} = privat "client"
        {_,maximP} = public "server"
        {_,maximK} = privat "server"
        maximS = shared(aliceP,maximK,scheme)
        aliceS = shared(maximP,aliceK,scheme)
        x = encrypt("Success!", maximS)
        "Success!" == decrypt(x, aliceS)
    end


    def checkX25519() do # X25519
        scheme = :x25519
        {aliceP,aliceK} = :crypto.generate_key(:ecdh, scheme)
        {maximP,maximK} = :crypto.generate_key(:ecdh, scheme)
        maximS = shared(aliceP,maximK,scheme)
        aliceS = shared(maximP,aliceK,scheme)
        x = encrypt("Success!", maximS)
        "Success!" == decrypt(x, aliceS)
    end

    def checkX448() do # X488
        scheme = :x448
        {aliceP,aliceK} = :crypto.generate_key(:ecdh, scheme)
        {maximP,maximK} = :crypto.generate_key(:ecdh, scheme)
        maximS = shared(aliceP,maximK,scheme)
        aliceS = shared(maximP,aliceK,scheme)
        x = encrypt("Success!", maximS)
        "Success!" == decrypt(x, aliceS)
    end

end