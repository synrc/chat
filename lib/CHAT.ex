defmodule CHAT.CRYPTO do

    def public(name) do
        prefix = "priv/mosquitto/"
        pub = :public_key.pem_entry_decode(:erlang.hd(:public_key.pem_decode(:erlang.element(2, :file.read_file(prefix <> name <> ".pem")))))
        :erlang.element(3,:erlang.element(8, :erlang.element(2, pub)))
    end

    def privat(name) do
        prefix = "priv/mosquitto/"
        key = :public_key.pem_entry_decode(:erlang.hd(:public_key.pem_decode(:erlang.element(2, :file.read_file(prefix <> name <> ".key")))))
        {_,_,keyBin,_,_,_} = key
        keyBin
    end

    def shared(pub, key, scheme), do: :crypto.compute_key(:ecdh, pub, key, scheme)

    def checkSECP384R1() do # read from PEM files
        scheme = :secp384r1
        aliceP = public "client"
        aliceK = privat "client"
        maximP = public "server"
        maximK = privat "server"
        maximS = shared(aliceP,maximK,scheme)
        aliceS = shared(maximP,aliceK,scheme)
        maximS == aliceS
    end

    def checkED25519() do # generate on-fly
        scheme = :x25519
        {aliceP,aliceK} = :crypto.generate_key(:ecdh, scheme)
        {maximP,maximK} = :crypto.generate_key(:ecdh, scheme)
        maximS = shared(aliceP,maximK,scheme)
        aliceS = shared(maximP,aliceK,scheme)
        maximS == aliceS
    end

end