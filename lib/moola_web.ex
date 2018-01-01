defmodule MoolaWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use MoolaWeb, :controller
      use MoolaWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def channel do
    quote do
      use Phoenix.Channel
      alias Phoenix.Socket
      alias Moola.User
      alias Moola.Log
      
      import Moola.Transmute
      import Moola.Util
      import Moola.NotifyChannels
      import MoolaWeb.Gettext
      import MoolaWeb.RenderJson
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: MoolaWeb
      import Plug.Conn
      import MoolaWeb.Router.Helpers
      import MoolaWeb.Gettext

      import Moola.Transmute
      import Moola.Util
      import Moola.NotifyChannels
      import MoolaWeb.Gettext
      import MoolaWeb.RenderJson

      alias Moola.Log
      alias Moola.User
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/moola_web/templates",
                        namespace: MoolaWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      import MoolaWeb.Router.Helpers
      import MoolaWeb.ErrorHelpers
      import MoolaWeb.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import MoolaWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
