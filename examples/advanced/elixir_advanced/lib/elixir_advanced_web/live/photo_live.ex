defmodule ElixirAdvancedWeb.PhotoLive do
  use ElixirAdvancedWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    image = get_image(String.to_integer(id))
    {:ok, assign(socket, image: image)}
  end

  defp get_image(id) do
    # This matches the data structure in GalleryLive
    images = [
      %{id: 1, src: "/images/photo-1.jpg", title: "Photo 1"},
      %{id: 2, src: "/images/photo-2.jpg", title: "Photo 2"},
      %{id: 3, src: "/images/photo-3.jpg", title: "Photo 3"}
    ]
    Enum.find(images, &(&1.id == id))
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen relative">
      <div class="absolute inset-0">
        <img src={@image.src} alt={@image.title} class="w-full h-full object-cover" />
        <div class="absolute inset-0 bg-black bg-opacity-50"></div>
      </div>

      <div class="relative z-10 max-w-3xl mx-auto pt-20 px-4">
        <div class="bg-white rounded-lg shadow-xl overflow-hidden">
          <div class="divide-y divide-gray-200">
            <div class="p-6">
              <button
                phx-click={JS.toggle(to: "#accordion-content")}
                class="w-full flex justify-between items-center focus:outline-none"
              >
                <h2 class="text-xl font-semibold text-gray-900"><%= @image.title %></h2>
                <svg
                  class="h-6 w-6 text-gray-500"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 9l-7 7-7-7"
                  />
                </svg>
              </button>
            </div>
            <div id="accordion-content" class="hidden p-6 bg-gray-50">
              <p class="text-gray-700">
                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor
                incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud
                exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute
                irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
                pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia
                deserunt mollit anim id est laborum.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
