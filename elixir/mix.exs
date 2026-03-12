defmodule TeinumTictactoeEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :teinum_tictactoe_ex,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"}
    ]
  end

  defp escript do
    [main_module: TeinumTictactoeEx.Stdio]
  end
end
