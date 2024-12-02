defmodule ElixirAdvancedWeb.GalleryLive do
  use ElixirAdvancedWeb, :live_view

  def mount(_params, _session, socket) do
    images = [
      %{id: 1, src: "/images/photo-1.jpg", title: "Photo 1"},
      %{id: 2, src: "/images/photo-2.jpg", title: "Photo 2"},
      %{id: 3, src: "/images/photo-3.jpg", title: "Photo 3"}
    ]
    {:ok, assign(socket, :images, images)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
      <h1 class="text-2xl font-semibold text-gray-900 mb-6">Photo Gallery</h1>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <%= for image <- @images do %>
          <.link
            navigate={~p"/gallery/#{image.id}"}
            class="bg-white rounded-lg shadow-md overflow-hidden transform transition duration-300 hover:scale-105 hover:shadow-xl"
          >
            <img
              src={image.src}
              alt={image.title}
              class="w-full h-64 object-cover"
            />
            <div class="p-4">
              <h3 class="text-lg font-medium text-gray-900"><%= image.title %></h3>
              <p class="text-sm text-gray-500 mt-1">Click to view details</p>
            </div>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end
end
