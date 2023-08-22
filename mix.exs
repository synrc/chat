defmodule CHAT.Mixfile do
  use Mix.Project

  def application(), do:
   [  mod: {CHAT, []},
      applications: [:n2o,:kvs,:ca,:emqtt,:ldap],
   ]

  def project do
    [app: :chat,
     version: "6.8.5",
     description: "CHAT  CXC 138 25 X.509 CMS Instant Messenger",
     xref: [exclude: [:asn1ct_tok,:asn1ct_parser2]],
     package: package(),
     deps: deps()]
  end

  def package() do
    [
      files: ["src", "include", "LICENSE", "README.md" ],
      licenses: ["DHARMA"],
      maintainers: ["Namdak Tonpa"],
      name: :chat,
      links: %{"GitHub" => "https://github.com/synrc/chat"}
    ]
  end

  def deps() do
    [ {:ex_doc, ">= 0.0.0", only: :dev},
      {:ca, "~> 4.8.2"},
#      {:ns, "~> 1.6.4"},
      {:ldap, "~> 8.6.3"},
      {:cowboy, "~> 2.5.0"},
      {:cowlib, "~> 2.6.0"},
      {:emqtt, "~> 1.2.0"},
      {:n2o, "~> 10.8.2"},
      {:kvs, "~> 10.8.2"},
      {:ssl_verify_fun, "~> 1.1.5"}
    ]
  end
end
