defmodule CHAT.ASN1 do

  def dir(), do: :application.get_env(:ca, :bundle, "priv/apple/")

  def fieldName({:contentType, {:Externaltypereference,_,_mod, name}}), do: normalizeName("#{name}")
  def fieldName(name), do: normalizeName("#{name}")

  def fieldType(name,field,{:ComponentType,_,_,{:type,_,oc,_,[],:no},_opt,_,_}), do: fieldType(name, field, oc)
  def fieldType(name,field,{:SEQUENCE, _, _, _, _}), do: bin(name) <> "_" <> bin(field) <> "_Sequence"
  def fieldType(name,field,{:CHOICE,_}), do: bin(name) <> "_" <> bin(field) <> "_Choice"
  def fieldType(_,_,{:pt, {_,_,_,type}, _}) when is_atom(type), do: "#{type}"
  def fieldType(_,_,{:ANY_DEFINED_BY, type}) when is_atom(type), do: "ASN1Any"
  def fieldType(_,_,{:contentType, {:Externaltypereference,_,_,type}}), do: "#{type}"
  def fieldType(_,_,{:Externaltypereference,_,_,type}), do: "#{type}"
  def fieldType(_,_,{:ObjectClassFieldType,_,_,[{_,type}],_}), do: "#{type}"
  def fieldType(_,_,{:"BIT STRING", _}), do: "ASN1BitString"
  def fieldType(_,_,{:"SEQUENCE OF", _}), do: "ASN1SequenceOf"
  def fieldType(name,field,{:"SET OF",{:type,_,{:"SEQUENCE", _, _, _,types},_,_,_}}), do: 
      Enum.join(:lists.map(fn x -> fieldType(name, field, x) end, types), "->")
  def fieldType(name,field,{:"SET OF",{:type,_,external,_,_,_}}), do: fieldType(name, field, external)
  def fieldType(_,_,type) when is_atom(type), do: "#{type}"
  def fieldType(name,_,_), do: "#{name}"

  def substituteType("INTEGER"),      do: "ArraySlice<UInt8>"
  def substituteType("OCTET STRING"), do: "ASN1OctetString"
  def substituteType("BIT STRING"),   do: "ASN1BitString"
  def substituteType("BOOLEAN"),      do: "Bool"
  def substituteType("NULL"),         do: "ASN1Null"
  def substituteType(t),              do: t

  def emitArg(name), do: "#{name}: #{name}"
  def emitCtorBodyElement(name), do: "self.#{name} = #{name}"
  def emitCtorParam(name, type), do: "#{name}: #{type}"
  def emitSequenceElement(name, type), do: "@usableFromInline var #{name}: #{type}\n"
  def emitSequenceEncoderBodyElement(name), do: "try coder.serialize(self.#{name})"
  def emitSequenceDecoderBodyElement(name, type), do: "let #{name} = try #{type}(derEncoded: &nodes)"
  def emitChoiceElement(name, type), do: "case #{name}(#{type})\n"
  def emitChoiceEncoderBodyElement(pad, name), do: String.duplicate(" ", pad) <> "case .#{name}(let #{name}): try coder.serialize(#{name})"
  def emitChoiceEncoderBodyElement(pad, no, name), do:
      String.duplicate(" ", pad) <> "case .#{name}(let #{name}):\n" <>
      String.duplicate(" ", pad+4) <> "try coder.appendConstructedNode(\n" <>
      String.duplicate(" ", pad+4) <> "identifier: ASN1Identifier(tagWithNumber: #{no}, tagClass: .contextSpecific),\n" <>
      String.duplicate(" ", pad+4) <> "{ coder in try coder.serialize(#{name}) })"
  def emitChoiceDecoderBodyElement(pad, name, type), do:
      String.duplicate(" ", pad) <> "case #{type}.defaultIdentifier:\n" <>
      String.duplicate(" ", pad+4) <> "self = .#{name}(try #{type}(derEncoded: rootNode))"

  def emitCases(name, pad, cases) when is_list(cases) do
      Enum.join(:lists.map(fn 
        {:ComponentType,_,fieldName,{:type,_,fieldType,_elementSet,[],:no},_optional,_,_} ->
           field = fieldType(name, fieldName, fieldType)
           String.duplicate(" ", pad) <> emitChoiceElement(fieldName(fieldName), substituteType(lookup(field)))
         _ -> ""
      end, cases), "")
  end

  def emitFields(name, pad, fields) when is_list(fields) do
      Enum.join(:lists.map(fn 
        {:ComponentType,_,fieldName,{:type,_,fieldType,_elementSet,[],:no},_optional,_,_} ->
           field = fieldType(name, fieldName, fieldType)
           case fieldType do
              {:SEQUENCE, _, _, _, fields} -> sequence(fieldType(name,fieldName,fieldType), fields, true)
              {:CHOICE, cases} -> choice(fieldType(name,fieldName,fieldType), cases, true)
              _ -> :skip
           end
           String.duplicate(" ", pad) <> emitSequenceElement(fieldName(fieldName), substituteType(lookup(field)))
        {:ComponentType,_,fieldName,fieldType,_optional,_,_} when is_binary(fieldType) or is_atom(fieldType) ->
           field = fieldType(name, fieldName, bin(fieldType))
           String.duplicate(" ", pad) <> emitSequenceElement(fieldName(fieldName), substituteType(lookup(field)))
         _ -> ""
      end, fields), "")
  end

  def emitCtorBody(fields), do:
      Enum.join(:lists.map(fn 
        {:ComponentType,_,fieldName,{:type,_,_type,_elementSet,[],:no},_optional,_,_} ->
           String.duplicate(" ", 8) <> emitCtorBodyElement(fieldName(fieldName))
         _ -> ""
      end, fields), "\n")

  def emitChoiceEncoderBody(cases), do:
      Enum.join(:lists.map(fn 
        {:ComponentType,_,fieldName,{:type,tag,_type,_elementSet,[],:no},_optional,_,_} ->
           case tag do
                [] -> emitChoiceEncoderBodyElement(12, fieldName(fieldName))
                [{:tag,:CONTEXT,no,_explicit,_}] -> emitChoiceEncoderBodyElement(12, no, fieldName(fieldName))
           end
         _ -> ""
      end, cases), "\n")

  def emitChoiceDecoderBody(cases), do:
      Enum.join(:lists.map(fn 
        {:ComponentType,_,fieldName,{:type,_,type,_elementSet,[],:no},_optional,_,_} ->
           emitChoiceDecoderBodyElement(12, fieldName(fieldName), substituteType(fieldType("", fieldName, type)))
         _ -> ""
      end, cases), "\n")

  def emitSequenceEncoderBody(fields), do:
      Enum.join(:lists.map(fn 
        {:ComponentType,_,fieldName,{:type,_,_type,_elementSet,[],:no},_optional,_,_} ->
           String.duplicate(" ", 12) <> emitSequenceEncoderBodyElement(fieldName(fieldName))
         _ -> ""
      end, fields), "\n")

  def emitSequenceDecoderBody(name,fields), do:
      Enum.join(:lists.map(fn 
        {:ComponentType,_,fieldName,{:type,_,type,_elementSet,[],:no},_optional,_,_} ->
           String.duplicate(" ", 12) <>
           emitSequenceDecoderBodyElement(fieldName(fieldName),
              substituteType(lookup(fieldType(name,fieldName,type))))
         _ -> ""
      end, fields), "\n")

  def emitParams(name,fields) when is_list(fields) do
      Enum.join(:lists.map(fn 
        {:ComponentType,_,fieldName,{:type,_,type,_elementSet,[],:no},_optional,_,_} ->
           emitCtorParam(fieldName(fieldName),
              substituteType(lookup(fieldType(name,fieldName,type))))
         _ -> ""
      end, fields), ", ")
  end

  def emitArgs(fields) when is_list(fields) do
      Enum.join(:lists.map(fn 
        {:ComponentType,_,fieldName,{:type,_,_type,_elementSet,[],:no},_optional,_,_} ->
           emitArg(fieldName(fieldName))
         _ ->  ""
      end, fields), ", ")
  end

  def emitChoiceDefinition(name,cases,decoder,encoder), do:
"""
// This file is autogenerated. Do not edit.

import SwiftASN1
import Crypto
import Foundation

@usableFromInline indirect enum #{name}: DERParseable, DERSerializable, Hashable, Sendable {
#{cases}#{decoder}#{encoder}
}
"""

  def emitChoiceDecoder(cases), do:
"""
    @inlinable init(derEncoded rootNode: ASN1Node) throws {
        switch rootNode.identifier {\n#{cases}
            default: throw ASN1Error.unexpectedFieldType(rootNode.identifier)
        }
    }
"""

  def emitChoiceEncoder(cases), do:
"""
    @inlinable func serialize(into coder: inout DER.Serializer) throws {
        switch self {\n#{cases}
        }
    }
"""

  def emitSequenceDefinition(name,fields,ctor,decoder,encoder), do:
"""
// This file is autogenerated. Do not edit.

import SwiftASN1
import Crypto
import Foundation

@usableFromInline struct #{name}: DERImplicitlyTaggable, Hashable, Sendable {
    @inlinable static var defaultIdentifier: ASN1Identifier { .sequence }\n#{fields}#{ctor}#{decoder}#{encoder}}
"""

  def emitSequenceDecoder(fields, name, args), do:
"""
    @inlinable init(derEncoded root: ASN1Node,
        withIdentifier identifier: ASN1Identifier) throws {
        self = try DER.sequence(root, identifier: identifier) { nodes in\n#{fields}
            return #{normalizeName(name)}(#{args})
        }
    }
"""

  def emitSequenceEncoder(fields), do:
"""
    @inlinable func serialize(into coder: inout DER.Serializer,
        withIdentifier identifier: ASN1Identifier) throws {
        try coder.appendConstructedNode(identifier: identifier) { coder in\n#{fields}
        }
    }
"""

  def emitCtor(params,fields), do: "    @inlinable init(#{params}) {\n#{fields}\n    }\n"

  def compile_all() do # 2-passes for name resolving
      {:ok, files} = :file.list_dir dir()
      :lists.map(fn file -> compile(false, dir() <> :erlang.list_to_binary(file))  end, files)
      :lists.map(fn file -> compile(true,  dir() <> :erlang.list_to_binary(file))  end, files)
      :ok
  end

  def save(true, name, res), do: [:logger.info('write: ~p', [name]),:file.write_file(normalizeName(name) <> ".swift",res)]
  def save(_, _, _), do: []

  def sequence(name, fields, saveFlag) do
      save(saveFlag, name, emitSequenceDefinition(normalizeName(name),
          emitFields(name, 4, fields), emitCtor(emitParams(name,fields), emitCtorBody(fields)),
          emitSequenceDecoder(emitSequenceDecoderBody(name, fields), name, emitArgs(fields)),
          emitSequenceEncoder(emitSequenceEncoderBody(fields))))
  end

  def choice(name, cases, saveFlag) do
      save(saveFlag, name, emitChoiceDefinition(normalizeName(name),
          emitCases(name, 4, cases),
          emitChoiceDecoder(emitChoiceDecoderBody(cases)),
          emitChoiceEncoder(emitChoiceEncoderBody(cases))))
  end

  def compileType(_pos, name, typeDefinition, save \\ true) do
      res = case typeDefinition do
          {:type, _, {:SEQUENCE, _, _, _, fields}, _, _, :no} -> sequence(name, fields, save)
          {:type, _, {:CHOICE, cases}, [], [], :no} -> choice(name, cases, save)
          {:type, _, {:ENUMERATED, _type}, [], [], :no} -> :skip
          {:type, _, :INTEGER, [], [], :no} -> :application.set_env(:asn1scg, bin(name), "INTEGER")
          {:type, _, {:INTEGER, _file}, [], [], :no} -> :skip
          {:type, _, {:"SEQUENCE OF", _type}, [], [], :no} -> :skip
          {:type, _, :"OCTET STRING", [], [], :no} -> :application.set_env(:asn1scg, bin(name), "OCTET STRING")
          {:type, _, :"BIT STRING", [], [], :no} -> :application.set_env(:asn1scg, bin(name), "BIT STRING")
          {:type, _, {:"BIT STRING",_}, [], [], :no} -> :application.set_env(:asn1scg, bin(name), "BIT STRING")
          {:type, _, {:"SET OF", _type}, _elementSet, [], :no} -> :skip
          {:type, _, :"OBJECT IDENTIFIER", _, _, :no} -> :skip
          {:type, _, {:ObjectClassFieldType, _, _, _, _fields}, _, _, :no} -> :skip
          {:type, _, {:Externaltypereference, _, _, _name}, [], [], _} -> :skip
          {:type, _, {:pt, _, _}, [], [], _} -> :skip
          {:ObjectSet, _, _, _, _elementSet} -> :skip
          {:Object, _, _val} -> :skip
          {:Object, _, _, _} -> :skip
          _ -> :skip
      end
      case res do
          :skip -> :logger.info 'Unhandled type definition ~p: ~p', [name, typeDefinition]
              _ -> :skip
      end 
  end

  def normalizeName(name), do: Enum.join(String.split("#{name}", "-"), "_")
  def lookup(name), do: bin(:application.get_env(:asn1scg, bin(name), bin(name)))
  def bin(x) when is_atom(x), do: :erlang.atom_to_binary x
  def bin(x) when is_list(x), do: :erlang.list_to_binary x
  def bin(x), do: x

  def dumpValue(_pos, _name, _type, _value, _mod), do: []
  def dumpClass(_pos, _name, _mod, _type), do: []
  def dumpPType(_pos, _name, _args, _type), do: []
  def dumpModule(_pos, _name, _defid, _tagdefault, _exports, _imports), do: []

  def compile(save, file \\ "priv/proto/CHAT.asn1") do
      tokens = :asn1ct_tok.file file
      {:ok, mod} = :asn1ct_parser2.parse file, tokens
      {:module, pos, name, defid, tagdefault, exports, imports, _, typeorval} = mod
      :lists.map(fn
         {:typedef,  _, pos, name, type} -> compileType(pos, name, type, save)
         {:ptypedef, _, pos, name, args, type} -> dumpPType(pos, name, args, type)
         {:classdef, _, pos, name, mod, type} -> dumpClass(pos, name, mod, type)
         {:valuedef, _, pos, name, type, value, mod} -> dumpValue(pos, name, type, value, mod)
      end, typeorval)
      dumpModule(pos, name, defid, tagdefault, exports, imports)
  end

end
