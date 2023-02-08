defmodule ServiceA do
  use Application

  @impl Application
  @spec start(any(), any()) :: {:ok, pid()} | {:error, reason :: term()}
  def start(_type, _args) do
    children = [
      Producer,
      {}
    ]

    opts = [strategy: :one_for_one, max_restarts: 30, max_seconds: 1]
    Supervisor.start_link(children, opts)
  end
end
