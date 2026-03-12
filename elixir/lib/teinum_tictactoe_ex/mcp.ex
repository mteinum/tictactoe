defmodule TeinumTictactoeEx.Mcp do
  alias TeinumTictactoeEx.Tools

  def handle_message(json_bin) do
    case Jason.decode(json_bin) do
      {:ok, msg} -> dispatch(msg)
      {:error, _} -> {:reply, encode(error_response(nil, -32700, "Parse error"))}
    end
  end

  defp dispatch(%{"method" => "initialize", "id" => id}) do
    result = %{
      "protocolVersion" => "2025-03-26",
      "capabilities" => %{"tools" => %{}},
      "serverInfo" => %{"name" => "teinum-tictactoe-ex", "version" => "0.1.0"}
    }

    {:reply, encode(success_response(id, result))}
  end

  defp dispatch(%{"method" => "notifications/" <> _}) do
    :noreply
  end

  defp dispatch(%{"method" => "ping", "id" => id}) do
    {:reply, encode(success_response(id, %{}))}
  end

  defp dispatch(%{"method" => "tools/list", "id" => id}) do
    {:reply, encode(success_response(id, %{"tools" => Tools.list()}))}
  end

  defp dispatch(%{"method" => "tools/call", "id" => id, "params" => params}) do
    name = params["name"]
    args = Map.get(params, "arguments", %{})
    result = Tools.call(name, args)
    {:reply, encode(success_response(id, result))}
  end

  defp dispatch(%{"method" => _method, "id" => id}) do
    {:reply, encode(error_response(id, -32601, "Method not found"))}
  end

  defp dispatch(%{"id" => id}) do
    {:reply, encode(error_response(id, -32600, "Invalid request"))}
  end

  defp dispatch(_) do
    :noreply
  end

  defp success_response(id, result) do
    %{"jsonrpc" => "2.0", "id" => id, "result" => result}
  end

  defp error_response(id, code, message) do
    %{"jsonrpc" => "2.0", "id" => id, "error" => %{"code" => code, "message" => message}}
  end

  defp encode(map) do
    Jason.encode!(map)
  end
end
