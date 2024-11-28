defmodule ElixirAdvanced.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "todos" do
    field :title, :string
    field :completed, :boolean, default: false
    belongs_to :user, ElixirAdvanced.Account.User

    timestamps()
  end

  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:title, :completed, :user_id])
    |> validate_required([:title, :user_id])
  end
end
