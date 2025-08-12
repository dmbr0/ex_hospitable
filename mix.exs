defmodule HospitableClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_hospitable,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "HospitableClient",
      source_url: "https://github.com/dmbr0/ex_hospitable"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    "An Elixir client library for the Hospitable API, providing comprehensive access to reservations, properties, and messaging endpoints."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/dmbr0/ex_hospitable",
        "Documentation" => "https://hexdocs.pm/ex_hospitable"
      },
      maintainers: ["Alex Whitney"],
      files: ~w(lib mix.exs README.md EXAMPLES.md LICENSE CLAUDE.md)
    ]
  end

  defp docs do
    [
      main: "HospitableClient",
      extras: ["README.md", "EXAMPLES.md"],
      groups_for_modules: [
        "Core": [HospitableClient],
        "API Modules": [
          HospitableClient.Reservations,
          HospitableClient.Properties, 
          HospitableClient.Messages
        ],
        "Configuration": [
          HospitableClient.Auth,
          HospitableClient.Config
        ]
      ]
    ]
  end
end
