func get_Profile() -> Model {
  return Model(value:Tuple(name:"Profile",body:[
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Binary())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:List(constant:nil,model:get_Service()))])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:List(constant:nil, model:Model(value:Chain(types:[
            get_Roster(),
            Model(value:Binary()),
            Model(value:Number())]))))])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:List(constant:nil,model:get_Feature()))])),
    Model(value:Number()),
    Model(value:Number()),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Atom(constant:"offline")),
        Model(value:Atom(constant:"online")),
        Model(value:Binary())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Atom(constant:"remove")),
        Model(value:Atom(constant:"get")),
        Model(value:Atom(constant:"patch")),
        Model(value:Atom(constant:"update")),
        Model(value:Atom(constant:"delete")),
        Model(value:Atom(constant:"create")),
        Model(value:Atom(constant:"init"))]))]))}
