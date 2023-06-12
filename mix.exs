defmodule CHAT.Mixfile do
  use Mix.Project

  def application(), do: [mod: {:chat, []}]

  def project do
    [app: :chat,
     version: "6.6.14",
     description: "CHAT X.509 Instant Messenger mqtt://chat.synrc.com",
     package: package(),
     deps: deps()]
  end

  def package() do
    [
      files: ["src", "etc", "priv", "include", "LICENSE", "README.md", "rebar.config", "sys.config", "vm.args"],
      licenses: ["DHARMA"],
      maintainers: ["Namdak Tonpa"],
      name: :chat,
      links: %{"GitHub" => "https://github.com/synrc/chat"}
    ]
  end

  def deps() do
    [#{:ex_doc, ">= 0.0.0", only: :dev},
      {:cowboy, "~> 2.5"},
      {:rocksdb, "~> 1.6.0"},
      {:syn, "~> 1.6.3"},
      {:rpc, "~> 4.11.0"},
      {:exmqttc, "~> 0.6.1"},
      {:n2o, "~> 8.8.1"},
      {:kvs, "~> 8.10.4"}
    ]
  end
end
