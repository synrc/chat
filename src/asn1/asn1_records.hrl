-ifdef(debug).
-define(dbg(Fmt, Args), ok=io:format("~p: " ++ Fmt, [?LINE|Args])).
-else.
-define(dbg(Fmt, Args), no_debug).
-endif.

-define('COMPLETE_ENCODE',1).
-define('TLV_DECODE',2).

-define(MISSING_IN_MAP, asn1__MISSING_IN_MAP).

-record(module,{pos,name,defid,tagdefault='EXPLICIT',exports={exports,[]},imports={imports,[]}, extensiondefault=empty,typeorval}).

-record('ExtensionAdditionGroup',{number}).
-record('SEQUENCE',{pname=false,tablecinf=false,extaddgroup,components=[]}).
-record('SET',{pname=false,sorted=false,tablecinf=false,components=[]}).
-record('ComponentType',{pos,name,typespec,prop,tags,textual_order}).
-record('ObjectClassFieldType',{classname,class,fieldname,type}).

-record(typedef,{checked=false,pos,name,typespec}).
-record(classdef, {checked=false,pos,name,module,typespec}).
-record(valuedef,{checked=false,pos,name,type,value,module}).
-record(ptypedef,{checked=false,pos,name,args,typespec}).
-record(pvaluedef,{checked=false,pos,name,args,type,value}).
-record(pvaluesetdef,{checked=false,pos,name,args,type,valueset}).
-record(pobjectdef,{checked=false,pos,name,args,class,def}).
-record(pobjectsetdef,{checked=false,pos,name,args,class,def}).

-record('Constraint',{'SingleValue'=no,'SizeConstraint'=no,'ValueRange'=no,'PermittedAlphabet'=no,
		      'ContainedSubtype'=no, 'TypeConstraint'=no,'InnerSubtyping'=no,e=no,'Other'=no}).
-record(simpletableattributes,{objectsetname,c_name,c_index,usedclassfield,
			       uniqueclassfield,valueindex}).
-record(type,{tag=[],def,constraint=[],tablecinf=[],inlined=no}).

-record(objectclass,{fields=[],syntax}).
-record('Object',{classname,gen=true,def}).
-record('ObjectSet',{class,gen=true,uniquefname,set}).

-record(tag,{class,number,type,form=32}). % form = ?CONSTRUCTED
% This record holds information about allowed constraint types per type
-record(cmap,{single_value=no,contained_subtype=no,value_range=no,
		size=no,permitted_alphabet=no,type_constraint=no,
		inner_subtyping=no}).


-record('EXTENSIONMARK',{pos,val}).
-record('SymbolsFromModule',{symbols,module,objid}).
-record('Externaltypereference',{pos,module,type}).
-record('Externalvaluereference',{pos,module,value}).

-record(seqtag,
	{pos :: integer(),
	 module :: atom(),
	 val :: atom()}).

-record(state,
	{module,
	 mname,
	 tname,
	 erule,
	 parameters=[],
	 inputmodules=[],
	 abscomppath=[],
	 recordtopname=[],
	 options,
	 sourcedir,
	 error_context
	}).

-record(gen,
        {erule=ber :: 'ber' | 'per' | 'jer',
         der=false :: boolean(),
         jer=false :: boolean(),
         aligned=false :: boolean(),
         rec_prefix="" :: string(),
         macro_prefix="" :: string(),
         pack=record :: 'record' | 'map',
         options=[] :: [any()]
        }).

-record(abst,
        {name :: module(),                      %Name of module.
         types,                                 %Types.
         values,                                %Values.
         ptypes,                                %Parameterized types.
         classes,                               %Classes.
         objects,                               %Objects.
         objsets                                %Object sets.
        }).

