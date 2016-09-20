defmodule BertGateClient.Mixfile do
  use Mix.Project

  def project do
    [app: :bert_gate_client,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [ mod: {BertGate.Client.App, []},
      applications: [:logger] ]
  end

  defp deps do
    deps(Mix.env)
  end

  defp deps(:test) do
    deps(:all) ++ [
      {:bert_gate, github: "lastcanal/bertgate"}
    ]
  end

  defp deps(_any) do
    []
  end

end
