func get_mqi() -> Model {
  return Model(value:Tuple(name:"mqi",body:[
    get_muc(),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Binary())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Atom(constant:"admin")),
        Model(value:Atom(constant:"member")),
        Model(value:Atom(constant:"removed"))]))]))}
