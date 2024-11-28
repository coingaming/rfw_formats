defmodule ElixirAdvancedWeb.GalleryLive do
  use ElixirAdvancedWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
      <h1 class="text-2xl font-semibold text-gray-900">Gallery</h1>
      <div class="mt-4">
        <p>Gallery functionality will be implemented here</p>
      </div>
    </div>
    """
  end
end
