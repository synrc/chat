func get_Friend() -> Model {
  return Model(value:Tuple(name:"Friend",body:[
    Model(value:Binary()),
    Model(value:Binary()),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:List(constant:nil,model:get_Feature()))])),
    Model(value:Chain(types:[
        Model(value:Atom(constant:"ban")),
        Model(value:Atom(constant:"unban")),
        Model(value:Atom(constant:"request")),
        Model(value:Atom(constant:"confirm")),
        Model(value:Atom(constant:"update")),
        Model(value:Atom(constant:"ignore"))]))]))}
