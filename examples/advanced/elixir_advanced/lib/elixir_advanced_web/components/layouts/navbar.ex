defmodule ElixirAdvancedWeb.Components.Navbar do
  use Phoenix.Component
  use Phoenix.VerifiedRoutes,
    endpoint: ElixirAdvancedWeb.Endpoint,
    router: ElixirAdvancedWeb.Router

  import Phoenix.Component
  alias Phoenix.LiveView.JS

  attr :current_user, :map, required: true

  def navbar(assigns) do
    ~H"""
    <nav class="bg-gray-800">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <span class="text-white font-bold">ElixirAdvanced</span>
            </div>
            <div class="hidden md:block">
              <div class="ml-10 flex items-baseline space-x-4">
                <.link
                  navigate={~p"/todos"}
                  class="text-gray-300 hover:bg-gray-700 hover:text-white px-3 py-2 rounded-md text-sm font-medium"
                >
                  Todos
                </.link>
                <.link
                  navigate={~p"/gallery"}
                  class="text-gray-300 hover:bg-gray-700 hover:text-white px-3 py-2 rounded-md text-sm font-medium"
                >
                  Gallery
                </.link>
              </div>
            </div>
          </div>
          <div class="hidden md:block">
            <div class="ml-4 flex items-center md:ml-6 space-x-4">
              <span class="text-gray-300 text-sm">
                <%= @current_user.email %>
              </span>
              <.link
                navigate={~p"/users/settings"}
                class="text-gray-300 hover:bg-gray-700 hover:text-white px-3 py-2 rounded-md text-sm font-medium"
              >
                Settings
              </.link>
              <.link
                href={~p"/users/log_out"}
                method="delete"
                class="text-gray-300 hover:bg-gray-700 hover:text-white px-3 py-2 rounded-md text-sm font-medium"
              >
                Log out
              </.link>
            </div>
          </div>
          <div class="md:hidden">
            <button
              type="button"
              phx-click={JS.toggle(to: "#mobile-menu")}
              class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 focus:outline-none"
              aria-controls="mobile-menu"
              aria-expanded="false"
            >
              <span class="sr-only">Open main menu</span>
              <img src="/images/hamburger.svg" class="h-6 w-6 invert brightness-0" alt="Menu" />
            </button>
          </div>
        </div>
      </div>

      <div class="hidden md:hidden" id="mobile-menu">
        <div class="px-2 pt-2 pb-3 space-y-1 sm:px-3">
          <.link
            navigate={~p"/todos"}
            class="text-gray-300 hover:bg-gray-700 hover:text-white block px-3 py-2 rounded-md text-base font-medium"
          >
            Todos
          </.link>
          <.link
            navigate={~p"/gallery"}
            class="text-gray-300 hover:bg-gray-700 hover:text-white block px-3 py-2 rounded-md text-base font-medium"
          >
            Gallery
          </.link>
        </div>
        <div class="pt-4 pb-3 border-t border-gray-700">
          <div class="px-2 space-y-1">
            <div class="text-gray-300 px-3 py-2">
              <%= @current_user.email %>
            </div>
            <.link
              navigate={~p"/users/settings"}
              class="text-gray-300 hover:bg-gray-700 hover:text-white block px-3 py-2 rounded-md text-base font-medium"
            >
              Settings
            </.link>
            <.link
              href={~p"/users/log_out"}
              method="delete"
              class="text-gray-300 hover:bg-gray-700 hover:text-white block px-3 py-2 rounded-md text-base font-medium"
            >
              Log out
            </.link>
          </div>
        </div>
      </div>
    </nav>
    """
  end
end
