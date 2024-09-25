defmodule RfwFormats.ModelTest do
  use ExUnit.Case
  alias RfwFormats.Model

  test "LibraryName" do
    a = Model.new_library_name(["core", "widgets"])
    b = Model.new_library_name(["core", "widgets"])
    c = Model.new_library_name(["core", "material"])
    d = Model.new_library_name(["core"])

    assert Model.library_name_to_string(a) == "core.widgets"
    assert Model.library_name_to_string(c) == "core.material"
    assert a == b
    assert a != c
    assert Model.compare_library_names(a, b) == :eq
    assert Model.compare_library_names(b, a) == :eq
    assert Model.compare_library_names(a, c) == :gt
    assert Model.compare_library_names(c, a) == :lt
    assert Model.compare_library_names(b, c) == :gt
    assert Model.compare_library_names(c, b) == :lt
    assert Model.compare_library_names(a, d) == :gt
    assert Model.compare_library_names(b, d) == :gt
    assert Model.compare_library_names(c, d) == :gt
    assert Model.compare_library_names(d, a) == :lt
    assert Model.compare_library_names(d, b) == :lt
    assert Model.compare_library_names(d, c) == :lt
  end

  test "FullyQualifiedWidgetName" do
    aa = Model.new_fully_qualified_widget_name(Model.new_library_name(["a"]), "a")
    ab = Model.new_fully_qualified_widget_name(Model.new_library_name(["a"]), "b")
    bb = Model.new_fully_qualified_widget_name(Model.new_library_name(["b"]), "b")

    assert Model.fully_qualified_widget_name_to_string(aa) == "a:a"
    assert aa != bb
    assert Model.compare_fully_qualified_widget_names(aa, aa) == :eq
    assert Model.compare_fully_qualified_widget_names(aa, ab) == :lt
    assert Model.compare_fully_qualified_widget_names(aa, bb) == :lt
    assert Model.compare_fully_qualified_widget_names(ab, aa) == :gt
    assert Model.compare_fully_qualified_widget_names(ab, ab) == :eq
    assert Model.compare_fully_qualified_widget_names(ab, bb) == :lt
    assert Model.compare_fully_qualified_widget_names(bb, aa) == :gt
    assert Model.compare_fully_qualified_widget_names(bb, ab) == :gt
    assert Model.compare_fully_qualified_widget_names(bb, bb) == :eq
  end

  test "to_string representations" do
    assert "#{Model.missing()}" == "<missing>"
    assert "#{Model.new_loop(0, 1)}" == "...for loop in 0: 1"
    assert "#{Model.new_switch(0, %{1 => 2})}" == "switch 0 %{1 => 2}"
    assert "#{Model.new_constructor_call("a", %{})}" == "a(%{})"
    assert "#{Model.new_args_reference(["a"])}" == "args.a"
    assert "#{Model.new_bound_args_reference(false, ["a"])}" == "args(false).a"
    assert "#{Model.new_data_reference(["a"])}" == "data.a"
    assert "#{Model.new_loop_reference(0, ["a"])}" == "loop0.a"
    assert "#{Model.new_bound_loop_reference(0, ["a"])}" == "loop(0).a"
    assert "#{Model.new_state_reference(["a"])}" == "state.a"
    assert "#{Model.new_bound_state_reference(0, ["a"])}" == "state^0.a"
    assert "#{Model.new_event_handler("a", %{})}" == "event a %{}"

    assert "#{Model.new_set_state_handler(Model.new_state_reference(["a"]), false)}" ==
             "set state.a = false"

    assert "#{Model.new_import(Model.new_library_name(["a"]))}" == "import a;"

    assert "#{Model.new_widget_declaration("a", nil, Model.new_constructor_call("b", %{}))}" ==
             "widget a = b(%{});"

    assert "#{Model.new_widget_declaration("a", %{"x" => false}, Model.new_constructor_call("b", %{}))}" ==
             "widget a = b(%{});"

    assert "#{Model.new_remote_widget_library([Model.new_import(Model.new_library_name(["a"]))], [Model.new_widget_declaration("a", nil, Model.new_constructor_call("b", %{}))])}" ==
             "import a;\nwidget a = b(%{});"
  end

  test "BoundArgsReference" do
    target = %{}
    result = Model.ArgsReference.bind(Model.new_args_reference([0]), target)
    assert result.arguments == target
    assert result.parts == [0]
  end

  test "DataReference" do
    result = Model.Reference.construct_reference(Model.new_data_reference([0]), [1])
    assert result.parts == [0, 1]
  end

  test "LoopReference" do
    result = Model.Reference.construct_reference(Model.new_loop_reference(9, [0]), [1])
    assert result.parts == [0, 1]
  end

  test "BoundLoopReference" do
    target = %{}
    loop_ref = Model.new_loop_reference(9, [0])
    bound_ref = Model.LoopReference.bind(loop_ref, target)
    result = Model.Reference.construct_reference(bound_ref, [1])
    assert result.value == target
    assert result.parts == [0, 1]
  end

  test "BoundStateReference" do
    state_ref = Model.new_state_reference([0])
    bound_ref = Model.StateReference.bind(state_ref, 9)
    result = Model.Reference.construct_reference(bound_ref, [1])
    assert result.depth == 9
    assert result.parts == [0, 1]
  end

  test "SourceLocation comparison" do
    test1 = Model.SourceLocation.new("test", 123)
    test2 = Model.SourceLocation.new("test", 234)

    assert Model.SourceLocation.compare(test1, test2) == :lt
    assert Model.SourceLocation.compare(test1, test1) == :eq
    assert Model.SourceLocation.compare(test2, test1) == :gt

    assert_raise RuntimeError, fn ->
      Model.SourceLocation.compare(test1, Model.SourceLocation.new("other", 123))
    end
  end

  test "SourceLocation to_string" do
    test = Model.SourceLocation.new("test1", 123)
    assert Model.SourceLocation.to_string(test) == "test1@123"
  end

  test "SourceRange" do
    a = Model.SourceLocation.new("test", 123)
    b = Model.SourceLocation.new("test", 124)
    c = Model.SourceLocation.new("test", 125)

    range1 = Model.SourceRange.new(a, b)
    range2 = Model.SourceRange.new(b, c)

    assert Model.SourceRange.to_string(range1) == "test@123..124"
    assert range1 != range2
  end
end
