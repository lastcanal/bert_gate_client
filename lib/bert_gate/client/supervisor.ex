defmodule BertGate.Client.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_bucket do
    Supervisor.start_child(__MODULE__, [])
  end

  def init(:ok) do
    children = [
      worker(BertGate.Client, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
