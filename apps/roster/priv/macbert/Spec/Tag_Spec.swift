func get_Tag() -> Model {
  return Model(value:Tuple(name:"Tag",body:[
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Binary())])),
    Model(value:Binary()),
    Model(value:Binary()),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Atom(constant:"create")),
        Model(value:Atom(constant:"remove")),
        Model(value:Atom(constant:"edit"))]))]))}
