defmodule VectorTile.MixProject do
  use Mix.Project

  def project do
    [
      app: :vector_tile,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        "test.watch": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:protobuf, "~> 0.15.0"},
      {:mix_test_watch, "~> 1.3", only: [:dev, :test], runtime: false}
    ]
  end
end
