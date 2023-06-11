func get_Message() -> Model {
  return Model(value:Tuple(name:"Message",body:[
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Number())])),
    Model(value:Chain(types:[
        Model(value:Atom(constant:"chain")),
        Model(value:Atom(constant:"cur")),
        Model(value:List(constant:""))])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        get_muc(),
        get_p2p()])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Number())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Number())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Binary())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Binary())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Binary())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Number())])),
    Model(value:List(constant:nil,model:get_Desc())),
    Model(value:List(constant:nil, model:Model(value:Chain(types:[
        Model(value:Atom(constant:"sys")),
        Model(value:Atom(constant:"reply")),
        Model(value:Atom(constant:"forward")),
        Model(value:Atom(constant:"read")),
        Model(value:Atom(constant:"edited")),
        Model(value:Atom(constant:"cursor"))])))),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Number()),
        get_Message()])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:List(constant:nil, model:Model(value:Chain(types:[
            Model(value:Binary()),
            Model(value:Number())]))))])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:List(constant:nil, model:Model(value:Number())))])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:List(constant:nil, model:Model(value:Number())))])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Atom(constant:"async")),
        Model(value:Atom(constant:"delete")),
        Model(value:Atom(constant:"clear")),
        Model(value:Atom(constant:"update")),
        Model(value:Atom(constant:"edit"))]))]))}
