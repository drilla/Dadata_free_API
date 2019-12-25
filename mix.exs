defmodule AddressProcessor.MixProject do
  use Mix.Project

  def project do
    [
      app: :address_processor,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AddressProcessor.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      httpoison: "~> 1.6",
      myxql:     ">= 0.0.0",
      ecto_sql:  "~> 3.1",
      poison:    "~> 3.1"

    ]
  end

    # Specifies which paths to compile per environment. lib by default, but we need a test helpers
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
