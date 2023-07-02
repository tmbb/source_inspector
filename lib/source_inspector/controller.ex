defmodule SourceInspector.Controller do
  @moduledoc false

  # This is a very simple controller which launches the code editor.
  # The function that launches the editor can be changes in the
  # application's config.
  # TODO: document this better in the README.

  use Phoenix.Controller
  import Phoenix.Controller

  def goto_source(conn, %{"file" => file, "line" => line} = _params) do
    {module, function, args} =
      Application.get_env(
        :source_inspector,
        :goto_source,
        # By default use the `goto_source_command` defined in this controller
        {__MODULE__, :goto_source_command, []}
      )

    # Call the editor
    apply(module, function, [file, line] ++ args)
    # Return something to indicate success
    # (the return value is actually not used by the frontend)
    Plug.Conn.send_resp(conn, 200, "ok")
  end

  @doc false
  def goto_source_command(file, line) do
    System.cmd("code", ["--goto", "#{file}:#{line}"])
  end
end
