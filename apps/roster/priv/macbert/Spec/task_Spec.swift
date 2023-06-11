func get_task() -> Model {
  return Model(value:Tuple(name:"task",body:[
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Atom())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Atom())])),
    Model(value:List(constant:nil, model:Model(value:Tuple()))),
    Model(value:Binary())]))}
