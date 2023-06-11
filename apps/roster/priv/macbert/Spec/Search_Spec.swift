func get_Search() -> Model {
  return Model(value:Tuple(name:"Search",body:[
    Model(value:Number()),
    Model(value:Binary()),
    Model(value:Binary()),
    Model(value:Chain(types:[
        Model(value:Atom(constant:"==")),
        Model(value:Atom(constant:"!=")),
        Model(value:Atom(constant:"like"))])),
    Model(value:List(constant:nil, model:Model(value:Chain(types:[Model(value:Tuple()),Model(value:Atom()),Model(value:Binary()),Model(value:Number()),Model(value:List(constant:""))])))),
    Model(value:Chain(types:[
        Model(value:Atom(constant:"profile")),
        Model(value:Atom(constant:"roster")),
        Model(value:Atom(constant:"contact")),
        Model(value:Atom(constant:"member")),
        Model(value:Atom(constant:"room"))]))]))}
