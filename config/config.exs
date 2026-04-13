import Config

import_config "kvs.exs"
import_config "ca.exs"

config :chat,
  tcp: 8830,
  logger_level: :info

