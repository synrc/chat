defmodule CHAT.Mixfile do
  use Mix.Project

  def project do
    [app: :chat,
     version: "6.6.14",
     description: "CHAT X.509 Instant Messenger mqtt://chat.synrc.com",
     package: package,
     deps: deps]
  end

  def application do
    [mod: {:chat, []}]
  end

  defp package do
    [files: ["src", "etc", "priv", "include", "LICENSE", "README.md", "rebar.config", "sys.config", "vm.args"],
     licenses: ["DHARMA"],
     maintainers: [Namdak Tonpa"],
     name: :chat,
     links: %{"GitHub" => "https://github.com/synrc/chat"}]
  end

  defp deps do
     [{:ex_doc, ">= 0.0.0", only: :dev}]
  end
end
