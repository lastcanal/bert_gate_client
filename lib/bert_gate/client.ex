defmodule BertGate.Client do
   require Logger


   defmodule State do
     defstruct host: nil, port: nil, socket: nil
   end

   def connect(host,options\\%{}) do
      port = Dict.get(options,:port,9484)
      Logger.info "Connecting to #{inspect host}:#{port}"
      case :gen_tcp.connect(String.to_char_list(host), port, [:binary,{:packet,4},{:active, false}]) do
         {:ok, socket} ->
           {:ok, pid} = GenServer.start_link(BertGate.Client.Impl, %State{host: host, port: port, socket: socket})
           pid
         {:error, err} -> raise NetworkError, error: err
      end
   end

   def call(pid,mod,fun,args\\[],timeout\\5000) do
      res = GenServer.call(pid, {:call,mod,fun,args,timeout})
      case res do
         {:result,r} -> r
         {:exception,e} -> raise e
      end
   end

   def cast(pid,mod,fun,args\\[]) do
      res = GenServer.call(pid, {:cast,mod,fun,args})
      case res do
         {:result,r} -> r
         {:exception,e} -> raise e
      end
   end

   def auth(pid,token), do:
      call(pid,:'Auth',:auth,[token])

   def close(pid), do:
      GenServer.call(pid, :close)

   # @TODO: info not implemented

end
