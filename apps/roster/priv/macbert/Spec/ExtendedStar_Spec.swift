func get_ExtendedStar() -> Model {
  return Model(value:Tuple(name:"ExtendedStar",body:[
    Model(value:Chain(types:[
        get_Star(),
        Model(value:List(constant:""))])),
    Model(value:Chain(types:[
        get_Contact(),
        get_Room(),
        Model(value:List(constant:""))]))]))}
