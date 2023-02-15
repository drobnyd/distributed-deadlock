defmodule ServiceA.MixProject do
  use Mix.Project

  def project do
    [
      app: :deadlock_example,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:deadlock_example, :amqp_lib],
        flags: [:error_handling, :race_conditions]
      ]
      # elixirc_paths: ["lib, test/support"]
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
      {:amqp_lib, path: "../amqp_lib"},
      # TODO only: [:dev, :test]
      {:local_cluster, "~> 1.2"},
      {:dialyxir, "~> 1.2.0", runtime: false}
    ]
  end
end
