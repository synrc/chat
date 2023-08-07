defmodule CHAT.ASN1 do

  def dir(), do: :application.get_env(:ca, :bundle, "priv/apple/")

  def compile_all() do
      {:ok, files} = :file.list_dir dir()
      :lists.map(fn file ->
         :io.format 'file: ~p~n', [file]
         parse(dir() <> :erlang.list_to_binary(file))
      end, files)
      :ok
  end

  def dumpType(pos, name, type) do
      :io.format '~p~n', [type]
      :io.format 'name: ~p~n', [name]
      :io.format 'pos: ~p~n', [pos]
  end

  def dumpValue(pos, name, type, value, mod) do
      :io.format '~p~n', [type]
      :io.format 'name: ~p~n', [name]
      :io.format 'value: ~p~n', [value]
      :io.format 'mod: ~p~n', [mod]
      :io.format 'pos: ~p~n', [pos]
  end

  def dumpClass(pos, name, mod, type) do
      :io.format '~p~n', [type]
      :io.format 'name: ~p~n', [name]
      :io.format 'mod: ~p~n', [mod]
      :io.format 'pos: ~p~n', [pos]
  end

  def dumpPType(pos, name, args, type) do
      :io.format '~p~n', [type]
      :io.format 'name: ~p~n', [name]
      :io.format 'args: ~p~n', [args]
      :io.format 'pos: ~p~n', [pos]
  end

  def dumpModule(pos, name, defid, tagdefault, exports, imports) do
      :io.format 'pos: ~p~n', [pos]
      :io.format 'name: ~p~n', [name]
      :io.format 'defid: ~p~n', [defid]
      :io.format 'tagdefault: ~p~n', [tagdefault]
      :io.format 'exports: ~p~n', [exports]
      :io.format 'imports: ~p~n', [imports]
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
