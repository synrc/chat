defmodule CHAT.CRYPTO do

    def decrypt(cipher, secret) do
        key = :binary.part(secret, 0, 32)
        <<iv::binary-16, tag::binary-16, bin::binary>> = cipher
        :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, bin, "AES256GCM", tag, false)
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