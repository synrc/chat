use Mix.Config

config :chat,
  logger_level: :info,
  logger: [{:handler, :default4, :logger_std_h,
            %{level: :info,
              id: :synrc,
              max_size: 2000,
              module: :logger_std_h,
              config: %{type: :file, file: 'chat.log'},
              formatter: {:logger_formatter,
                          %{template: [:time,' ',:pid,' ',:module,' ',:msg,'\n'],
                            single_line: true,}}}}]



#config :ns,
#  dnssec: [{:enabled, true}],
#  use_root_hints: false,
#  catch_exceptions: false,
#  zones: '/synrc.zone.json',
#  pools: [{:tcp_worker_pool, :erldns_worker, [{:size, 10},{:max_overflow, 20}]}],
#  servers: [ [{:name, :inet_localhost_1}, {:address, '127.0.0.1'}, {:port, 8053}, {:family, :inet}, {:processes, 2}],
#             [{:name, :inet6_localhost_1}, {:address, '::1'}, {:port, 8053}, {:family, :inet6}] ]

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
