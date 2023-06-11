func get_Star() -> Model {
  return Model(value:Tuple(name:"Star",body:[
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Number())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Binary())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Number())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        get_Message()])),
    Model(value:List(constant:nil,model:get_Tag())),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Atom(constant:"add")),
        Model(value:Atom(constant:"remove"))]))]))}
