import Config

config :ns,
  servers: [[{:name, :inet_localhost_1}, {:address, ~c"0.0.0.0"}, {:port, 8053}, {:family, :inet}, {:processes, 2}],
            [{:name, :inet6_localhost_1}, {:address, ~c"::1"}, {:port, 8053}, {:family, :inet6}]],
  dnssec: [{:enabled, true}],
  use_root_hints: false,
  catch_exceptions: false,
  zones: ~c"priv/synrc.zone.json",
  pools: [{:tcp_worker_pool, :erldns_worker, [{:size, 10},{:max_overflow, 20}]}],
  logger_level: :info
