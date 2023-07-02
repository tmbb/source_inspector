defmodule SourceInspector do
  use Phoenix.Component

  @default_debuggable_element_title "[Source Inspector] Right click to view source"

  @doc """
  Adds the necessary CSS to highlight

  This function will only return actual content if the `:enable`
  option is true in the application environment for `:source_inspector`.
  """

  attr(:highlight_border_width, :string, default: "2px")
  attr(:highlight_border_color, :string, default: "magenta")

  def css(assigns) do
    if Application.get_env(:source_inspector, :enable, false) do
      ~H"""
      <style>
        [data-source-inspector="true"]:hover {
          cursor: help;
          border-left-width: <%= @highlight_border_width %> !important;
          border-top-width: <%= @highlight_border_width %> !important;
          border-right-width: <%= @highlight_border_width %> !important;
          border-bottom-width: <%= @highlight_border_width %> !important;

          border-left-color: <%= @highlight_border_color %> !important;
          border-top-color: <%= @highlight_border_color %> !important;
          border-right-color: <%= @highlight_border_color %> !important;
          border-bottom-color: <%= @highlight_border_color %> !important;

          border-style: solid !important;
        }
      </style>
      """
    else
      ~H""
    end
  end

  @doc """
  Establishes a communication channel between the client and the server
  for the Source Inspection functionality.

  Inside the scope you can (and should!) add your own pipeline.
  The scope will only be active if `Mix.env() == :dev` and if
  the source inspector functionality has been set in the `:source_inspector`
  application environment.

  ## Example

      # router.ex

      require SourceInspect

      SourceInspector.scope do
        pipe_trough :browser
      end
  """
  defmacro scope([do: body]) do
    quote do
      if Mix.env() == :dev and Application.compile_env(:source_inspector, :enable, false) do
        require Phoenix.Router

        Phoenix.Router.scope "/" do
          # Include the body so that the user can setup pipelines and such
          unquote(body)
          # Add a new route for the Source Inspector controller
          post "/_source_inspector_goto_source", SourceInspector.Controller, :goto_source
        end
      end
    end
  end

  @external_resource "priv/js/source_inspector.js"
  @source_inspector_js File.read!("priv/js/source_inspector.js")

  @doc """
  Adds the necessary JS file into your `assets/vendor/` directory
  to make it possible to import the `SourceInspector` hook.
  This function is meant to be run from the `iex` interpreter.

  This will create the `assets/vendor/SourceInspector.js` file
  in your source tree.
  You can then import the `SourceInspector` function, which will create
  a LiveView Hook when given a `csrfToken`.

  ## Example

  ```js
  import SourceInspector from "../vendor/SourceInspector.js"

  let csrfToken = ...

  let Hooks = {}
  Hooks.SourceInspector = SourceInspector(csrfToken)
  let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})
  ```

  *Note*: the SourceInspector hook requires the `csrfToken` because it actually
  uses a POST request to communicate with the backend instead of using the live socket.
  Using a normal POST request outside of the LiveView circuit actually works pretty well.
  The fact that it uses HTTP requests is an implementation detail and may change
  in future versions.
  """
  def vendor_js_hook() do
    path = "assets/vendor/SourceInspector.js"
    File.write!(path, @source_inspector_js)
  end

  @doc false
  def debuggable_element_title() do
    # Returns a title for the HTML element, as defined in a configuration option
    case Application.get_env(:source_inspector, :debuggable_element_title) do
      nil ->
        @default_debuggable_element_title

      message when is_binary(message) ->
        message

      {module, function, args} ->
        apply(module, function, args)
    end
  end

  @doc """
  Sets a breakpoint for a slot which plays nicely with `SourceInspector.pry()`.
  """

  def slot_breakpoint(slot, opts \\ [])

  def slot_breakpoint([slot], opts), do: slot_breakpoint_helper(slot, opts)
  def slot_breakpoint(slot, opts), do: slot_breakpoint_helper(slot, opts)

  defp slot_breakpoint_helper(slot, opts) do
    random_id = Keyword.get(opts, :random_id, true)

    source_inspector_attrs = Map.get(slot, :source_inspector_attrs, %{})

    if random_id == true and Map.has_key?(source_inspector_attrs, :"phx-hook") do
      id = random_dom_id()
      Map.put(source_inspector_attrs, :id, id)
    else
      source_inspector_attrs
    end
  end

  @doc """
  Sets a breakpoint in an HTML element which plays nicely with `SourceInspector.pry()`.
  It can't be used in a component.

  This macro works by adding a number of attributes to an HTML element.

  > #### Warning {: .warning}
  >
  > The attributes that Source Inspector adds are an implementation detail.
  > User code should not depend on these attributes.
  """
  defmacro breakpoint(opts \\ []) do
    quote do
      SourceInspector.attrs_from_assigns(
        unquote(Macro.var(:assigns, nil)),
        unquote(opts)
      )
    end
  end

  @doc false
  def attrs_from_assigns(assigns, opts \\ []) do
    random_id = Keyword.get(opts, :random_id, true)

    source_inspector_attrs = Map.get(assigns, :source_inspector_attrs, %{})

    if random_id == true and Map.has_key?(source_inspector_attrs, :"phx-hook") do
      id = random_dom_id()
      Map.put(source_inspector_attrs, :id, id)
    else
      source_inspector_attrs
    end
  end

  defp random_dom_id() do
    # Generate a random (probably) unique id for an HTML node
    hex_digits = Enum.map(1..16, fn _ -> Enum.random(0..15) |> Integer.to_string(16) end)
    IO.iodata_to_binary(hex_digits)
  end

  @doc """
  Makes a component debuggable by adding a number of attributes
  that can be extracted from the arguments passed at the call site.

  > #### Warning {: .warning}
  >
  > The attributes that Source Inspector adds are an implementation detail.
  > User code should not depend on these attributes.
  """
  defmacro debuggable() do
    quote do
      attr(:source_inspector_attrs, :map, default: %{})
    end
  end

  @doc """
  Makes a slot debuggable by adding a number of attributes
  that can be extracted from the arguments passed at the call site.

  > #### Warning {: .warning}
  >
  > The attributes that Source Inspector adds are an implementation detail.
  > User code should not depend on these attributes.
  """
  defmacro debuggable_slot() do
    quote do
      attr(:source_inspector_attrs, :map, required: false)
    end
  end

  defmacro pry() do
    # Test *at compile-time" whether to add the necessary attributes or not
    if Mix.env() == :dev do
      # We're in dev mode; we might get to add some attributes
      quote do
        # Let's see if we want to actually activate Source Inspector or not
        if Application.get_env(:source_inspector, :enabled, false) do
          # The config option is set, so we return a number of attributes
          %{
            source_inspector_attrs: %{
              "data-source-inspector": "true",
              "data-source-inspector-file": unquote(__CALLER__.file),
              "data-source-inspector-line": unquote(__CALLER__.line),
              title: SourceInspector.debuggable_element_title(),
              "phx-hook": (Mix.env() == :dev && "SourceInspector")
            }
          }
        else
          # The config option is not set, so we return an empty map
          %{}
        end
      end
    else
      # We're not in dev mode; just return an empty map
      quote do
        %{}
      end
    end
  end
end
