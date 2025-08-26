defmodule VectorTile.MixProject do
  use Mix.Project

  defp source_url, do: "https://github.com/box-id/vector_tile"

  def project do
    [
      app: :vector_tile,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [
        "test.watch": :test
      ],

      # Docs
      name: "VectorTile",
      source_url: source_url(),
      docs: docs(),
      package: package()
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      nest_modules_by_prefix: [VectorTile]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "Changelog" => source_url() <> "/releases",
        "GitHub" => source_url()
      },
      keywords: [
        "vector",
        "tile",
        "map"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:protobuf, "~> 0.15.0"},
      {:mix_test_watch, "~> 1.3", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true}
    ]
  end
end
