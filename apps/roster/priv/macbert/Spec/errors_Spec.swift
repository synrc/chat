func get_errors() -> Model {
  return Model(value:Tuple(name:"errors",body:[
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:List(constant:nil, model:Model(value:Binary())))])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Chain(types:[Model(value:Tuple()),Model(value:Atom()),Model(value:Binary()),Model(value:Number()),Model(value:List(constant:""))]))]))]))}
