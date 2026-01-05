defmodule CHAT.Mixfile do
  use Mix.Project

  def application() do
      [
        mod: {CHAT, []},
        extra_applications: [:x509, :bandit, :plug, :logger, :ca ]
      ]
  end

  def project do
      [
        app: :chat,
        version: "9.1.1",
        description: "CHAT  CXC 138 25 X.509 CMS Instant Messenger",
        package: package(),
        deps: deps()
      ]
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
      [
        {:ex_doc, ">= 0.0.0", only: :dev},
        {:ca, "~> 7.1.2"},
        {:ssl_verify_fun, "~> 1.1.7"}
      ]
  end
end
