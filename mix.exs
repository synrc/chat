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
      {:ca, "~> 4.7.12"},
      {:ns, "~> 1.6.4"},
      {:ldap, "~> 8.6.3"},
      {:cowboy, "~> 2.5.0"},
      {:cowlib, "~> 2.6.0"},
      {:emqtt, "~> 1.2.0"},
      {:n2o, "~> 8.8.1"},
      {:ssl_verify_fun, "~> 1.1.5"},
      {:kvs, "~> 8.10.4"}
    ]
  end
end
