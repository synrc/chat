defmodule CHAT.Mixfile do
  use Mix.Project

  def project do
    [app: :chat,
     version: "0.6.12",
     description: "CHAT Instant Messenger",
     package: package,
     deps: deps]
  end

  def application do
    [mod: {:mq, []}]
  end

  defp package do
    [files: ["src", "LICENSE", "README.md", "rebar.config", "sys.config", "vm.args"],
     licenses: ["DHARMA"],
     maintainers: [Namdak Tonpa"],
     name: :mq,
     links: %{"GitHub" => "https://github.com/synrc/chat"}]
  end

  defp deps do
     [{:ex_doc, ">= 0.0.0", only: :dev}]
  end
end
