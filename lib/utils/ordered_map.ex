defmodule RfwFormats.OrderedMap do
  @moduledoc """
  An ordered map implementation that preserves the insertion order of keys.
  Implements `Access`, `Enumerable`, `Collectable`, and `Inspect` protocols.

  ## Examples

      iex> om = RfwFormats.OrderedMap.new(a: 1, b: 2)
      iex> om = RfwFormats.OrderedMap.put(om, :c, 3)
      iex> RfwFormats.OrderedMap.to_list(om)
      [a: 1, b: 2, c: 3]

      iex> om = RfwFormats.OrderedMap.put_new(om, :b, 4)
      iex> RfwFormats.OrderedMap.get(om, :b)
      2

      iex> {value, om} = RfwFormats.OrderedMap.pop(om, :a)
      iex> value
      1
      iex> RfwFormats.OrderedMap.keys(om)
      [:b, :c]
  """

  @behaviour Access

  defstruct map: %{}, keys: []

  @type key :: String.t() | atom()
  @type value :: any()
  @type t :: %__MODULE__{
          map: %{optional(key) => value},
          keys: [key]
        }

  # Creation Functions

  @doc """
  Creates a new, empty `OrderedMap`.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Creates a new `OrderedMap` from a list of key-value tuples.
  """
  @spec new([{key, value}]) :: t()
  def new(entries) when is_list(entries) do
    Enum.reduce(entries, new(), fn {k, v}, acc -> put(acc, k, v) end)
  end

  @doc """
  Creates a new `OrderedMap` from an enumerable with a transformation function.
  """
  @spec new(Enumerable.t(), (any() -> {key, value})) :: t()
  def new(enumerable, fun) when is_function(fun, 1) do
    enumerable
    |> Enum.map(fun)
    |> new()
  end

  # Core Functions

  @doc """
  Inserts a key-value pair. Updates value if key exists without changing order.
  Appends key if it's new.
  """
  @spec put(t(), key, value) :: t()
  def put(%__MODULE__{map: map, keys: keys} = om, key, value) do
    updated_keys =
      if Map.has_key?(map, key), do: keys, else: keys ++ [key]

    %{om | map: Map.put(map, key, value), keys: updated_keys}
  end

  @doc """
  Inserts a key-value pair at a specified position. Updates position if key exists.
  """
  @spec put(t(), key, value, non_neg_integer()) :: t()
  def put(%__MODULE__{map: map, keys: keys} = om, key, value, index)
      when is_integer(index) and index >= 0 do
    new_keys =
      keys
      |> List.delete(key)
      |> List.insert_at(index, key)

    %{om | map: Map.put(map, key, value), keys: new_keys}
  end

  @doc """
  Inserts a key-value pair only if the key does not exist.
  """
  @spec put_new(t(), key, value) :: t()
  def put_new(%__MODULE__{} = om, key, value) do
    if has_key?(om, key), do: om, else: put(om, key, value)
  end

  @doc """
  Lazily inserts a key-value pair only if the key does not exist.
  """
  @spec put_new_lazy(t(), key, (-> value)) :: t()
  def put_new_lazy(%__MODULE__{} = om, key, value_fun) when is_function(value_fun, 0) do
    if has_key?(om, key), do: om, else: put(om, key, value_fun.())
  end

  @doc """
  Retrieves the value for a key, returning a default if not found.
  """
  @spec get(t(), key, value) :: value
  def get(%__MODULE__{map: map}, key, default \\ nil) do
    Map.get(map, key, default)
  end

  @doc """
  Updates the value for a key with a function. Inserts with default if key doesn't exist.
  """
  @spec update(t(), key, value, (value -> value)) :: t()
  def update(%__MODULE__{} = om, key, default, update_fun) when is_function(update_fun, 1) do
    if has_key?(om, key), do: put(om, key, update_fun.(get(om, key))), else: put(om, key, default)
  end

  @doc """
  Updates the value for a key with a function. Raises if key doesn't exist.
  """
  @spec update!(t(), key, (value -> value)) :: t()
  def update!(%__MODULE__{} = om, key, update_fun) when is_function(update_fun, 1) do
    if has_key?(om, key),
      do: put(om, key, update_fun.(get(om, key))),
      else: raise(KeyError, key: key, term: om)
  end

  @doc """
  Deletes a key. Returns unchanged map if key doesn't exist.
  """
  @spec delete(t(), key) :: t()
  def delete(%__MODULE__{map: map, keys: keys} = om, key) do
    if Map.has_key?(map, key),
      do: %{om | map: Map.delete(map, key), keys: List.delete(keys, key)},
      else: om
  end

  @impl Access
  @doc """
  Pops a key, returning its value and the updated map. Returns default if key doesn't exist.
  """
  @spec pop(t(), key, value) :: {value, t()}
  def pop(%__MODULE__{} = om, key, default \\ nil) do
    if has_key?(om, key), do: {get(om, key), delete(om, key)}, else: {default, om}
  end

  @doc """
  Returns the number of key-value pairs.
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{map: map}), do: map_size(map)

  @doc """
  Converts to a list of key-value tuples in order.
  """
  @spec to_list(t()) :: [{key, value}]
  def to_list(%__MODULE__{map: map, keys: keys}) do
    Enum.map(keys, fn key -> {key, Map.get(map, key)} end)
  end

  @doc """
  Returns the list of keys in order.
  """
  @spec keys(t()) :: [key]
  def keys(%__MODULE__{keys: keys}), do: keys

  @doc """
  Returns the list of values in order.
  """
  @spec values(t()) :: [value]
  def values(%__MODULE__{} = om) do
    Enum.map(om.keys, fn key -> get(om, key) end)
  end

  @doc """
  Merges two `OrderedMap` structures with an optional merge function.
  """
  @spec merge(t(), t(), (key, value, value -> value)) :: t()
  def merge(%__MODULE__{} = map1, %__MODULE__{} = map2, merge_fun \\ fn _k, _v1, v2 -> v2 end)
      when is_function(merge_fun, 3) do
    Enum.reduce(to_list(map2), map1, fn {k, v}, acc ->
      if Map.has_key?(acc.map, k) do
        updated_value = merge_fun.(k, Map.get(acc.map, k), v)
        put(acc, k, updated_value)
      else
        put(acc, k, v)
      end
    end)
  end

  @doc """
  Reorders a key to a specified position. No change if key doesn't exist.
  """
  @spec reorder_key(t(), key, non_neg_integer()) :: t()
  def reorder_key(%__MODULE__{keys: keys} = om, key, position)
      when is_integer(position) and position >= 0 do
    if has_key?(om, key) do
      new_keys =
        keys
        |> List.delete(key)
        |> List.insert_at(position, key)

      %{om | keys: new_keys}
    else
      om
    end
  end

  @doc """
  Checks if a key exists.
  """
  @spec has_key?(t(), key) :: boolean()
  def has_key?(%__MODULE__{map: map}, key), do: Map.has_key?(map, key)

  # Access Behaviour Implementation

  @impl Access
  @doc """
  Fetches the value for a key.
  """
  @spec fetch(t(), key) :: {:ok, value} | :error
  def fetch(%__MODULE__{map: map}, key), do: Map.fetch(map, key)

  @impl Access
  @doc """
  Gets and updates the value for a key using a function.
  """
  @spec get_and_update(t(), key, (value | nil -> {value | nil, value | nil})) ::
          {value | nil, t()}
  def get_and_update(om, key, fun) when is_function(fun, 1) do
    current = get(om, key)

    case fun.(current) do
      {get_val, update_val} ->
        new_om =
          if update_val == nil do
            delete(om, key)
          else
            put(om, key, update_val)
          end

        {get_val, new_om}

      :pop ->
        pop(om, key)
    end
  end
end

# Enumerable Protocol Implementation
defimpl Enumerable, for: RfwFormats.OrderedMap do
  def count(ordered_map), do: {:ok, RfwFormats.OrderedMap.size(ordered_map)}

  def member?(ordered_map, {key, value}) do
    case RfwFormats.OrderedMap.fetch(ordered_map, key) do
      {:ok, ^value} -> {:ok, true}
      _ -> {:ok, false}
    end
  end

  def member?(_ordered_map, _element), do: {:ok, false}

  def reduce(ordered_map, acc, fun) do
    Enumerable.List.reduce(RfwFormats.OrderedMap.to_list(ordered_map), acc, fun)
  end

  def slice(_ordered_map), do: {:error, __MODULE__}
end

# Collectable Protocol Implementation
defimpl Collectable, for: RfwFormats.OrderedMap do
  def into(original) do
    collector_fun = fn
      om, {:cont, {key, value}} ->
        RfwFormats.OrderedMap.put(om, key, value)

      om, :done ->
        om

      _om, :halt ->
        :ok
    end

    {original, collector_fun}
  end
end

# Inspect Protocol Implementation
defimpl Inspect, for: RfwFormats.OrderedMap do
  import Inspect.Algebra

  def inspect(ordered_map, opts) do
    concat([
      "#OrderedMap<",
      to_doc(RfwFormats.OrderedMap.to_list(ordered_map), opts),
      ">"
    ])
  end
end
