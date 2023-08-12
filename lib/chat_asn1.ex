defmodule CHAT.ASN1 do

  def dir(), do: :application.get_env(:ca, :bundle, "priv/apple/")

  def emitDecoder(body), do:
    """
    @inlinable
    init(derEncoded root: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(root, identifier: identifier) { nodes in
            #{body}
        }
    }
    """

  def emitEncoder(body), do:
    """
    @inlinable
    func serialize(into coder: inout DER.Serializer, withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in
            #{body}
        }
    }
    """


  def emitCtor(params, body), do:
    """
    @inlinable
    init(#{params}) {
         #{body}
    }
    """

  def compile_all() do
      {:ok, files} = :file.list_dir dir()
      :lists.map(fn file ->
         :logger.info 'file: ~p~n', [file]
         parse(dir() <> :erlang.list_to_binary(file))
      end, files)
      :ok
  end

  def dumpType(pos, name, type) do
      :logger.info '~p~n', [type]
      :logger.info 'name: ~p~n', [name]
      :logger.info 'pos: ~p~n', [pos]
  end

  def dumpValue(pos, name, type, value, mod) do
      :logger.info '~p~n', [type]
      :logger.info 'name: ~p~n', [name]
      :logger.info 'value: ~p~n', [value]
      :logger.info 'mod: ~p~n', [mod]
      :logger.info 'pos: ~p~n', [pos]
  end

  def dumpClass(pos, name, mod, type) do
      :logger.info '~p~n', [type]
      :logger.info 'name: ~p~n', [name]
      :logger.info 'mod: ~p~n', [mod]
      :logger.info 'pos: ~p~n', [pos]
  end

  def dumpPType(pos, name, args, type) do
      :logger.info '~p~n', [type]
      :logger.info 'name: ~p~n', [name]
      :logger.info 'args: ~p~n', [args]
      :logger.info 'pos: ~p~n', [pos]
  end

  def dumpModule(pos, name, defid, tagdefault, exports, imports) do
      :logger.info 'pos: ~p~n', [pos]
      :logger.info 'name: ~p~n', [name]
      :logger.info 'defid: ~p~n', [defid]
      :logger.info 'tagdefault: ~p~n', [tagdefault]
      :logger.info 'exports: ~p~n', [exports]
      :logger.info 'imports: ~p~n', [imports]
  end

  def parse(file \\ "priv/proto/CHAT.asn1") do
      tokens = :asn1ct_tok.file file
      {:ok, mod} = :asn1ct_parser2.parse file, tokens
      {:module, pos, name, defid, tagdefault, exports, imports, _, typeorval} = mod
      :lists.map(fn
         {:typedef,  _, pos, name, type} -> dumpType(pos, name, type)
         {:valuedef, _, pos, name, type, value, mod} -> dumpValue(pos, name, type, value, mod)
         {:classdef, _, pos, name, mod, type} -> dumpClass(pos, name, mod, type)
         {:ptypedef, _, pos, name, args, type} -> dumpPType(pos, name, args, type)
      end, typeorval)
      dumpModule(pos, name, defid, tagdefault, exports, imports)
  end

end
