defmodule CHAT.Mixfile do
  use Mix.Project

  def application() do
      [
        mod: {CHAT, []},
        extra_applications: [ :crypto, :thousand_island, :x509, :bandit, :plug, :logger, :ca, :ldap, :mnesia ]
      ]
  end

  def project do
      [
        app: :chat,
        version: "9.4.13",
        description: "CHAT  CXC 138 25 X.509 CMS Instant Messenger",
        package: package(),
        deps: deps(),
        releases: [chat: [include_executables_for: [:unix], cookie: "SYNRC:CHAT"]]
      ]
  end

  def package() do
      [
        files: ~w(include config lib LICENSE mix.exs README.md),
        licenses: ["ISC"],
        maintainers: ["Namdak Tonpa"],
        name: :chat,
        links: %{"GitHub" => "https://github.com/synrc/chat"}
      ]
  end

  def deps() do
      [
        {:ex_doc, ">= 0.0.0", only: :dev},
        {:ldap, "~> 15.1.1"},
        {:kvs, "~> 13.4.15"},
        {:ca, "~> 7.1.4"},
        {:thousand_island, "~> 1.4.3"},
        {:ssl_verify_fun, "~> 1.1.7"}
      ]
  end
end
