defmodule ElixirAdvancedWeb.Components.Navbar do
  use Phoenix.Component
  use Phoenix.VerifiedRoutes,
    endpoint: ElixirAdvancedWeb.Endpoint,
    router: ElixirAdvancedWeb.Router

  import Phoenix.Component

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
        </div>
      </div>
    </nav>
    """
  end
end
