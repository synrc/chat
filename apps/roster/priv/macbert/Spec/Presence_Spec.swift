func get_Presence() -> Model {
  return Model(value:Tuple(name:"Presence",body:[
    Model(value:Binary()),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Atom(constant:"offline")),
        Model(value:Atom(constant:"online")),
        Model(value:Binary())]))]))}
