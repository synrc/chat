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

    def shared(pub, key), do: shared(pub, key, :secp384r1)
    def shared(pub, key, scheme) do
        case scheme do
             :secp384r1 -> {:ok, :crypto.compute_key(:ecdh, pub, key, :secp384r1)}
             _ -> {:error, :no_scheme}
        end
    end

    def checkSECP384R1() do
        aliceP = public "client"
        aliceK = privat "client"
        maximP = public "server"
        maximK = privat "server"
        maximS = shared(aliceP,maximK)
        aliceS = shared(maximP,aliceK)
        maximS == aliceS
    end

end