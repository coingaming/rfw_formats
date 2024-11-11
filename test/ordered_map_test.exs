defmodule RfwFormats.OrderedMapTest do
  use ExUnit.Case
  alias RfwFormats.OrderedMap

  test "new/0 creates an empty OrderedMap" do
    om = OrderedMap.new()
    assert om.map == %{}
    assert om.keys == []
  end

  test "new/1 creates an OrderedMap from entries" do
    om = OrderedMap.new(a: 1, b: 2)
    assert om.map == %{a: 1, b: 2}
    assert om.keys == [:a, :b]
  end

  test "put/3 inserts new keys and updates existing keys" do
    om = OrderedMap.new()
    om = OrderedMap.put(om, :a, 1)
    assert om.map == %{a: 1}
    assert om.keys == [:a]

    om = OrderedMap.put(om, :b, 2)
    assert om.map == %{a: 1, b: 2}
    assert om.keys == [:a, :b]

    om = OrderedMap.put(om, :a, 3)
    assert om.map == %{a: 3, b: 2}
    assert om.keys == [:a, :b]
  end

  test "put_new/3 only inserts if key does not exist" do
    om = OrderedMap.new(a: 1)
    om = OrderedMap.put_new(om, :a, 2)
    assert om.map == %{a: 1}
    assert om.keys == [:a]

    om = OrderedMap.put_new(om, :b, 2)
    assert om.map == %{a: 1, b: 2}
    assert om.keys == [:a, :b]
  end

  test "put_new_lazy/3 inserts lazily" do
    om = OrderedMap.new(a: 1)
    om = OrderedMap.put_new_lazy(om, :b, fn -> 2 end)
    assert om.map == %{a: 1, b: 2}
    assert om.keys == [:a, :b]

    om = OrderedMap.put_new_lazy(om, :a, fn -> 3 end)
    assert om.map == %{a: 1, b: 2}
    assert om.keys == [:a, :b]
  end

  test "update/4 updates existing keys and inserts new keys with default" do
    om = OrderedMap.new(a: 1, b: 2)
    om = OrderedMap.update(om, :a, 0, &(&1 + 1))
    assert om.map[:a] == 2

    om = OrderedMap.update(om, :c, 3, &(&1 + 1))
    assert om.map[:c] == 3
    assert om.keys == [:a, :b, :c]
  end

  test "update!/3 updates existing keys or raises if key does not exist" do
    om = OrderedMap.new(a: 1, b: 2)
    om = OrderedMap.update!(om, :a, &(&1 + 1))
    assert om.map[:a] == 2

    assert_raise KeyError, fn ->
      OrderedMap.update!(om, :c, &(&1 + 1))
    end
  end

  test "delete/2 removes keys" do
    om = OrderedMap.new(a: 1, b: 2)
    om = OrderedMap.delete(om, :a)
    assert om.map == %{b: 2}
    assert om.keys == [:b]

    om = OrderedMap.delete(om, :c)
    assert om.map == %{b: 2}
    assert om.keys == [:b]
  end

  test "pop/3 removes and returns the value" do
    om = OrderedMap.new(a: 1, b: 2)
    {val, om} = OrderedMap.pop(om, :a)
    assert val == 1
    assert om.map == %{b: 2}
    assert om.keys == [:b]

    {val, om} = OrderedMap.pop(om, :c, 3)
    assert val == 3
    assert om.map == %{b: 2}
    assert om.keys == [:b]
  end

  test "merge/3 combines two OrderedMaps" do
    om1 = OrderedMap.new(a: 1, b: 2)
    om2 = OrderedMap.new(b: 3, c: 4)
    merged = OrderedMap.merge(om1, om2)
    assert merged.map == %{a: 1, b: 3, c: 4}
    assert merged.keys == [:a, :b, :c]
  end

  test "reorder_key/3 changes the position of a key" do
    om = OrderedMap.new(a: 1, b: 2, c: 3)
    om = OrderedMap.reorder_key(om, :c, 1)
    assert om.keys == [:a, :c, :b]

    om = OrderedMap.reorder_key(om, :d, 0)
    # No change since :d does not exist
    assert om.keys == [:a, :c, :b]
  end

  test "Access behaviour works as expected" do
    om = OrderedMap.new(a: 1, b: 2)

    assert om[:a] == 1
    assert om[:c] == nil

    {val, om} = Access.get_and_update(om, :a, fn current -> {current, current + 1} end)
    assert val == 1
    assert om.map[:a] == 2

    {val, om} = Access.pop(om, :b)
    assert val == 2
    assert om.keys == [:a]
  end

  test "Inspect protocol formats output correctly" do
    om = OrderedMap.new(a: 1, b: 2)
    assert inspect(om) == "#OrderedMap<[a: 1, b: 2]>"
  end
end
