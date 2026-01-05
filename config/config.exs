import Config

config :ca,
  enabled: [:issuer, :wallet, :verifier, :est, :cmp, :cmc, :ocsp, :tsp],
  issuer:   8107,
  wallet:   8108,
  verifier: 8109,
  est:  8047,
  cmp:  8829,
  cmc:  5318,
  mad:  8088,
  ocsp: 8020,
  tsp:  8021,
  ldap: 8389,
  logger_level: :info,
  logger: [{:handler, :default2, :logger_std_h,
            %{level: :info,
              id: :synrc2,
              max_size: 2000,
              module: :logger_std_h,
              config: %{type: :file, file: ~c"chat.log"},
              formatter: {:logger_formatter,
                          %{template: [:time,~c" ",:pid,~c" ",:module,~c" ",:msg,~c"\n"],
                            single_line: true,}}}}]

config :ldap,
  port: 1489,
  instance: "D4252CF20538EC22",
  module: LDAP,
  logger_level: :info

config :ns,
  servers: [[{:name, :inet_localhost_1}, {:address, ~c"0.0.0.0"}, {:port, 8053}, {:family, :inet}, {:processes, 2}],
            [{:name, :inet6_localhost_1}, {:address, ~c"::1"}, {:port, 8053}, {:family, :inet6}]],
  dnssec: [{:enabled, true}],
  use_root_hints: false,
  catch_exceptions: false,
  zones: ~c"priv/synrc.zone.json",
  pools: [{:tcp_worker_pool, :erldns_worker, [{:size, 10},{:max_overflow, 20}]}],
  logger_level: :info

config :chat,
  tcp: 8830,
  logger_level: :info

