func get_History() -> Model {
  return Model(value:Tuple(name:"History",body:[
    Model(value:Binary()),
    Model(value:Chain(types:[
        get_p2p(),
        get_muc(),
        get_act(),
        get_StickerPack(),
        Model(value:List(constant:""))])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Number())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:Number())])),
    Model(value:Chain(types:[
        Model(value:List(constant:"")),
        Model(value:List(constant:nil, model:Model(value:Chain(types:[
            get_Message(),
            get_Job(),
            get_StickerPack()]))))])),
    Model(value:Chain(types:[
        Model(value:Atom(constant:"updated")),
        Model(value:Atom(constant:"get")),
        Model(value:Atom(constant:"update")),
        Model(value:Atom(constant:"last_loaded")),
        Model(value:Atom(constant:"last_msg")),
        Model(value:Atom(constant:"get_reply")),
        Model(value:Atom(constant:"double_get")),
        Model(value:Atom(constant:"delete")),
        Model(value:Atom(constant:"image")),
        Model(value:Atom(constant:"video")),
        Model(value:Atom(constant:"file")),
        Model(value:Atom(constant:"link")),
        Model(value:Atom(constant:"audio")),
        Model(value:Atom(constant:"contact")),
        Model(value:Atom(constant:"location")),
        Model(value:Atom(constant:"text"))]))]))}
