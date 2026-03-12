defmodule TeinumTictactoeEx.Stdio do
  def main(_args) do
    # Redirect logger to stderr
    Logger.configure_backend(:console, device: :standard_error)

    # Start the game server
    {:ok, _pid} = TeinumTictactoeEx.Game.start_link()

    # Set stdin/stdout to binary mode
    :io.setopts(:standard_io, encoding: :latin1)

    loop()
  end

  defp loop do
    case IO.read(:stdio, :line) do
      :eof ->
        :ok

      {:error, _reason} ->
        :ok

      line ->
        line = String.trim(line)

        if line != "" do
          case TeinumTictactoeEx.Mcp.handle_message(line) do
            {:reply, response} ->
              IO.write(:stdio, [response, "\n"])

            :noreply ->
              :ok
          end
        end

        loop()
    end
  end
end
