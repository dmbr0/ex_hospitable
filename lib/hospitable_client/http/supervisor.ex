defmodule HospitableClient.HTTP.Supervisor do
  @moduledoc """
  Supervisor for HTTP-related processes.

  This supervisor manages HTTP client processes and ensures they
  are restarted if they crash.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Add HTTP client workers here if needed in the future
      # For now, the HTTP client is stateless
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
