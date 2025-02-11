defmodule Elrec.MixProject do
  use Mix.Project

  @source_url "https://github.com/choualacreme/elrec"
  @version "0.1.0"

  def project do
    [
      app: :elrec,
      version: @version,
      name: :ELREC,
      source_url: @source_url,
      elixir: "~> 1.18",
      escript: [main_module: Elrec.CLI],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      aliases: aliases(),
      elixirc_options: [warnings_as_errors: true]
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
      {:benchee, "~> 1.0", only: [:dev, :test]},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:ex_doc, "~> 0.10", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["choualacreme"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "LICENSE.md"
      ]
    ]
  end

  defp aliases do
    [
      format: ["format", "credo --strict"]
    ]
  end
end
