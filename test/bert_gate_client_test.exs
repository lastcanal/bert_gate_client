defmodule BertGateClientTest do
  use ExUnit.Case

  alias BertGate.Client

  @port 9485

  setup_all do
     Rpc.start_link
     authenticator = fn
        _,_,:calc_auth_token -> {[:'CalcPrivate'],:some_auth_data}
        _,_,_ -> nil
     end
     {:ok, server} = BertGate.Server.start_link(%{
        port: @port,
        authenticator: authenticator,
        public: [:'Bert',:'CalcPublic'],
     })
     {:ok, [server: server]}
  end

  setup do
     conn=Client.connect("localhost", %{port: @port})
     {:ok, [conn: conn]}
  end

  test "ping", meta do
    conn=meta[:conn]
    assert Client.call(conn,:'Bert',:ping,[]) == :pong
    assert Client.cast(conn,:'Bert',:ping,[]) == :ok
  end

  test "data types", meta do
    conn=meta[:conn]
    assert Client.call(conn,:'Bert',:some_integer,[]) == 1234
    assert Client.call(conn,:'Bert',:some_float,[]) == 1.234
    assert Client.call(conn,:'Bert',:some_atom,[]) == :this_is_atom
    assert Client.call(conn,:'Bert',:some_tuple,[]) == {1,2,3,4}
    assert Client.call(conn,:'Bert',:some_bytelist,[]) == [1,2,3,4]
    assert Client.call(conn,:'Bert',:some_list,[]) == [1,2,[3,4]]
    assert Client.call(conn,:'Bert',:some_binary,[]) == "This is a binary"
    assert Client.call(conn,:'Bert',:some_map,[]) == %{a: 1, b: 2}
    assert_raise RuntimeError, fn -> Client.call(conn,:'Bert',:exception1,[]) end
    assert_raise ArgumentError, fn -> Client.call(conn,:'Bert',:exception2,[]) end
  end

  test "nonexistent module call", meta do
    conn=Client.connect("localhost", %{port: @port})
    assert_raise BERTError, "BERTError(401): Unauthorized. Closing connection.", fn ->
       Client.call(conn,:'Nonexistent',:somefun)
    end
  end

  test "nonexistent function call", meta do
    conn=Client.connect("localhost", %{port: @port})
    assert_raise UndefinedFunctionError, fn -> Client.call(conn,:'Bert',:nonexistent) end
  end

  test "invalid authentication", meta do
    conn=Client.connect("localhost", %{port: @port})
    assert_raise BERTError, "BERTError(401): Authentication failed. Closing connection.", fn -> Client.auth(conn,:invalid_token) end
  end

end

defmodule BertGate.Modules.CalcPublic do
  def sum(_,x,y), do: x+y
end

defmodule BertGate.Modules.CalcPrivate do
  def sum(_,x,y), do: x+y
end

