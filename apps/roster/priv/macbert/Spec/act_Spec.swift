func get_act() -> Model {
  return Model(value:Tuple(name:"act",body:[
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Binary())])),
    Model(value:Chain(types:[
        Model(value:Binary()),
        Model(value:Number()),
        Model(value:List(constant:nil, model:Model(value:Chain(types:[Model(value:Tuple()),Model(value:Atom()),Model(value:Binary()),Model(value:Number()),Model(value:List(constant:""))]))))]))]))}
