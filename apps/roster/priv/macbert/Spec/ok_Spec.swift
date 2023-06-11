func get_ok() -> Model {
  return Model(value:Tuple(name:"ok",body:[
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Atom(constant:"sms_sent")),
        Model(value:Atom(constant:"call_in_progress")),
        Model(value:Atom(constant:"push")),
        Model(value:Atom(constant:"cleared")),
        Model(value:Atom(constant:"logout")),
        Model(value:Binary())]))]))}
