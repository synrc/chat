use Mix.Config

config :n2o,
  port: 8888,
  app: :chat,
  pickler: :n2o_secret,
  mq: :n2o_syn,
  upload: "./priv/static",
  protocols: [:n2o_ftp, :chat_proto]

config :kvs,
  dba: :kvs_mnesia,
  dba_st: :kvs_stream,
  schema: [:kvs, :kvs_stream]
