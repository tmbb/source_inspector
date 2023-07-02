defmodule SourceInspector.MixProject do
  use Mix.Project

  def project do
    [
      app: :source_inspector,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:ex_doc, "~> 0.29", only: [:dev, :doc]},
      {:phoenix, "> 0.0.0"},
      {:phoenix_live_view, "> 0.0.0"}
    ]
  end
end
