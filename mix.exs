defmodule HospitableClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_hospitable,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "HospitableClient",
      description: "Elixir client library for Hospitable Public API",
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {HospitableClient.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:dotenv, "~> 3.1.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Alex"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/your-username/ex_hospitable"}
    ]
  end

  defp docs do
    [
      main: "HospitableClient",
      extras: ["README.md"]
    ]
  end
end
