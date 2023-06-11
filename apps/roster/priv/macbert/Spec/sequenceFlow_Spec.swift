func get_sequenceFlow() -> Model {
  return Model(value:Tuple(name:"sequenceFlow",body:[
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Atom())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Atom()),
        Model(value:List(constant:nil, model:Model(value:Atom())))]))]))}
