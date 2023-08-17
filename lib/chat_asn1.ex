defmodule CHAT.ASN1 do

  def dir(), do: :application.get_env(:ca, :bundle, "priv/apple/")

  def emitSequenceDecoder(body), do:
    """
    @inlinable
    init(derEncoded root: ASN1Node, withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(root, identifier: identifier) { nodes in
            #{body}
        }
    }
    """

  def emitSequenceEncoder(body), do:
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
      :logger.info 'type ~p', [type]
      :logger.info 'type name: ~p', [name]
      :logger.info 'type pos: ~p', [pos]
  end

  def dumpValue(pos, name, type, value, mod) do
      :logger.info 'value ~p', [type]
      :logger.info 'value name: ~p', [name]
      :logger.info 'value value: ~p', [value]
      :logger.info 'value mod: ~p', [mod]
      :logger.info 'value pos: ~p', [pos]
  end

  def dumpClass(pos, name, mod, type) do
      :logger.info 'class ~p', [type]
      :logger.info 'class name: ~p', [name]
      :logger.info 'class mod: ~p', [mod]
      :logger.info 'class pos: ~p', [pos]
  end

  def dumpPType(pos, name, args, type) do
      :logger.info 'ptype ~p', [type]
      :logger.info 'ptype name: ~p', [name]
      :logger.info 'ptype args: ~p', [args]
      :logger.info 'ptype pos: ~p', [pos]
  end

  def dumpModule(pos, name, defid, tagdefault, exports, imports) do
      :logger.info 'module pos: ~p', [pos]
      :logger.info 'module name: ~p', [name]
      :logger.info 'module defid: ~p', [defid]
      :logger.info 'module tagdefault: ~p', [tagdefault]
      :logger.info 'module exports: ~p', [exports]
      :logger.info 'module imports: ~p', [imports]
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
