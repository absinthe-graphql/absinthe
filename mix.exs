defmodule Absinthe.Mixfile do
  use Mix.Project

  @version "0.4.2"

  def project do
    [app: :absinthe,
     version: @version,
     elixir: "~> 1.2-dev",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package,
     docs: [source_ref: "v#{@version}", main: "Absinthe"],
     deps: deps
    ]
  end

  defp package do
    [description: "An experimental GraphQL API toolkit",
     files: ["lib", "src", "mix.exs", "README*"],
     maintainers: ["Bruce Williams"],
     licenses: ["BSD"],
     links: %{github: "https://github.com/CargoSense/absinthe"}]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_spec, "~> 1.0.0", only: :test},
      {:ex_doc, "~> 0.11.0", only: :dev},
      {:earmark, "~> 0.1.19", only: :dev}
    ]
  end
end
