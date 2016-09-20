defmodule BertGate.Client.App do
  use Application

  def start(:normal, _) do
     BertGate.Client.Supervisor.start_link
  end
end
