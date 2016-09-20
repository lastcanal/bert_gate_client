defmodule BertGate.Client.Impl do
   require Logger
   use GenServer
   alias BertGate.Client.State

   def init(state) do
     {:ok, state}
   end

   def handle_call({:call,mod,fun,args,timeout},_,s=%State{socket: socket}) do
      res = try do
        res = call_(socket,mod,fun,args,timeout)
        {:result,res}
      rescue
        e -> {:exception,e}
      end
      {:reply,res,s}
   end

   def handle_call({:cast,mod,fun,args},_,s=%State{socket: socket}) do
      res = try do
        cast_(socket,mod,fun,args)
        {:result, :ok}
      rescue
        e -> {:exception,e}
      end
      {:reply,res,s}
   end

   def handle_call(:close,_,s=%State{socket: socket}) do
      res = :gen_tcp.close socket
      {:reply,res,%State{s|socket: nil}}
   end

   defp call_(socket,mod,fun,args,timeout) do
      :ok = send_packet(socket,{:call,mod,fun,args})
      recv_packet(socket,timeout)
   end

   defp cast_(socket,mod,fun,args\\[]) do
      :ok = send_packet(socket,{:cast,mod,fun,args})
      :ok
   end

   # NOTE: packet length is automatically inserted by gen_tcp due to the {:packet,4} option
   defp send_packet(socket,data) do
      payload=Bert.encode(data)
      case :gen_tcp.send(socket,payload) do
         :ok -> :ok
         {:error,reason} -> raise NetworkError, error: reason
      end
   end

   # @TODO: receive packet!
   defp recv_packet(socket,timeout) do
      case :gen_tcp.recv(socket,0,timeout) do
         {:ok,data} ->
            case Bert.decode(data) do
               {:reply,reply} -> reply
               # exception raised by user function
               {:error,{:user,601,_,err,_}} ->
                  raise err
               {:error, {type, code, class, detail, backtrace}=err} ->
                  raise BERTError, type: type, code: code, class: class, detail: detail, backtrace: backtrace
               any ->
                  raise "Bad reply: #{inspect(any)}"
            end
         {:error,x} when x in [:closed,:timeout] ->
            :gen_tcp.close socket
            raise BERTClosed
         {:error,any} ->
            Logger.error "BERT: error: #{inspect(any)}"
            :gen_tcp.close socket
            raise "BERT recv error: #{inspect(any)}"
      end
   end
end
