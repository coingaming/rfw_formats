defmodule ElixirAdvancedWeb.TodosLive do
  use ElixirAdvancedWeb, :live_view
  alias ElixirAdvanced.Todos
  alias ElixirAdvanced.Todos.Todo

  on_mount {ElixirAdvancedWeb.UserAuth, :ensure_authenticated}

  def mount(_params, _session, socket) do
    changeset = Todos.change_todo(%Todo{}, %{})

    if connected?(socket) do
      todos = Todos.list_todos(socket.assigns.current_user.id)
      {:ok, assign(socket, todos: todos, changeset: changeset)}
    else
      {:ok, assign(socket, todos: [], changeset: changeset)}
    end
  end

  def handle_event("save", %{"todo" => todo_params}, socket) do
    todo_params = Map.put(todo_params, "user_id", socket.assigns.current_user.id)

    case Todos.create_todo(todo_params) do
      {:ok, _todo} ->
        changeset = Todos.change_todo(%Todo{})
        todos = Todos.list_todos(socket.assigns.current_user.id)
        {:noreply, assign(socket, changeset: changeset, todos: todos)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("toggle", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _todo} = Todos.update_todo(todo, %{completed: !todo.completed})
    todos = Todos.list_todos(socket.assigns.current_user.id)
    {:noreply, assign(socket, todos: todos)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _} = Todos.delete_todo(todo)
    todos = Todos.list_todos(socket.assigns.current_user.id)
    {:noreply, assign(socket, todos: todos)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
      <h1 class="text-2xl font-semibold text-gray-900 mb-8">Todos</h1>

      <div class="mb-8">
        <.form :let={f} for={@changeset} phx-submit="save" class="flex gap-4">
          <div class="flex-grow">
            <.input
              field={f[:title]}
              type="text"
              placeholder="Add a new todo..."
              class="w-full"
            />
          </div>
          <.button type="submit" phx-disable-with="Saving...">
            Add Todo
          </.button>
        </.form>
      </div>

      <div class="space-y-4">
        <%= for todo <- @todos do %>
          <div class="flex items-center justify-between bg-white p-4 rounded-lg shadow">
            <div class="flex items-center gap-4">
              <input
                type="checkbox"
                checked={todo.completed}
                phx-click="toggle"
                phx-value-id={todo.id}
                class="h-4 w-4 text-indigo-600 rounded border-gray-300 cursor-pointer"
              />
              <span class={if todo.completed, do: "line-through text-gray-500", else: "text-gray-900"}>
                <%= todo.title %>
              </span>
            </div>
            <button
              phx-click="delete"
              phx-value-id={todo.id}
              class="text-red-600 hover:text-red-800"
            >
              <.icon name="hero-trash" class="h-5 w-5" />
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
