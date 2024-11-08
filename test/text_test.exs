defmodule RfwFormats.TextTest do
  use ExUnit.Case
  alias RfwFormats.Text
  alias RfwFormats.Model

  test "empty parseDataFile" do
    result = Text.parse_data_file("{}")
    assert result == %{}
  end

  test "empty parseLibraryFile" do
    result = Text.parse_library_file("")
    assert result == Model.new_remote_widget_library([], [])
  end

  test "space parseDataFile" do
    result = Text.parse_data_file(" \n {} \n ")
    assert result == %{}
  end

  test "space parseLibraryFile" do
    result = Text.parse_library_file(" \n ")
    assert result == Model.new_remote_widget_library([], [])
  end

  test "valid values in parseDataFile" do
    assert Text.parse_data_file("{ }\n\n  \n\n") == %{}
    assert Text.parse_data_file("{ a: \"b\" }") == %{"a" => "b"}
    assert Text.parse_data_file("{ a: [ \"b\", 9 ] }") == %{"a" => ["b", 9]}
    assert Text.parse_data_file("{ a: { } }") == %{"a" => %{}}
    assert Text.parse_data_file("{ a: 123.456e7 }") == %{"a" => 123.456e7}
    assert Text.parse_data_file("{ a: true }") == %{"a" => true}
    assert Text.parse_data_file("{ a: false }") == %{"a" => false}
    assert Text.parse_data_file("{ \"a\": 0 }") == %{"a" => 0}
    assert Text.parse_data_file("{ \"a\": -0, b: \"x\" }") == %{"a" => 0, "b" => "x"}
    assert Text.parse_data_file("{ \"a\": null }") == %{}
    assert Text.parse_data_file("{ \"a\": -6 }") == %{"a" => -6}
    assert Text.parse_data_file("{ \"a\": -7 }") == %{"a" => -7}
    assert Text.parse_data_file("{ \"a\": -8 }") == %{"a" => -8}
    assert Text.parse_data_file("{ \"a\": -9 }") == %{"a" => -9}
    assert Text.parse_data_file("{ \"a\": 01 }") == %{"a" => 1}
    assert Text.parse_data_file("{ \"a\": 0e0 }") == %{"a" => 0.0}
    assert Text.parse_data_file("{ \"a\": 0e1 }") == %{"a" => 0.0}
    assert Text.parse_data_file("{ \"a\": 0e8 }") == %{"a" => 0.0}
    assert Text.parse_data_file("{ \"a\": 1e9 }") == %{"a" => 1.0e9}
    assert Text.parse_data_file("{ \"a\": -0e1 }") == %{"a" => 0.0}
    assert Text.parse_data_file("{ \"a\": 00e1 }") == %{"a" => 0.0}
    assert Text.parse_data_file("{ \"a\": -00e1 }") == %{"a" => 0.0}
    assert Text.parse_data_file("{ \"a\": 00.0e1 }") == %{"a" => 0.0}
    assert Text.parse_data_file("{ \"a\": -00.0e1 }") == %{"a" => 0.0}
    assert Text.parse_data_file("{ \"a\": -00.0e-1 }") == %{"a" => 0.0}
    assert Text.parse_data_file("{ \"a\": -1e-1 }") == %{"a" => -0.1}
    assert Text.parse_data_file("{ \"a\": -1e-2 }") == %{"a" => -0.01}
    assert Text.parse_data_file("{ \"a\": -1e-3 }") == %{"a" => -0.001}
    assert Text.parse_data_file("{ \"a\": -1e-4 }") == %{"a" => -0.0001}
    assert Text.parse_data_file("{ \"a\": -1e-5 }") == %{"a" => -0.00001}
    assert Text.parse_data_file("{ \"a\": -1e-6 }") == %{"a" => -0.000001}
    assert Text.parse_data_file("{ \"a\": -1e-7 }") == %{"a" => -0.0000001}
    assert Text.parse_data_file("{ \"a\": -1e-8 }") == %{"a" => -0.00000001}
    assert Text.parse_data_file("{ \"a\": -1e-9 }") == %{"a" => -0.000000001}
    assert Text.parse_data_file("{ \"a\": -1e-10 }") == %{"a" => -0.0000000001}
    assert Text.parse_data_file("{ \"a\": -1e-11 }") == %{"a" => -0.00000000001}
    assert Text.parse_data_file("{ \"a\": -1e-12 }") == %{"a" => -0.000000000001}
    assert Text.parse_data_file("{ \"a\": -1e-13 }") == %{"a" => -0.0000000000001}
    assert Text.parse_data_file("{ \"a\": -1e-14 }") == %{"a" => -0.00000000000001}
    assert Text.parse_data_file("{ \"a\": -1e-15 }") == %{"a" => -0.000000000000001}
    assert Text.parse_data_file("{ \"a\": -1e-16 }") == %{"a" => -0.0000000000000001}
    assert Text.parse_data_file("{ \"a\": -1e-17 }") == %{"a" => -0.00000000000000001}
    assert Text.parse_data_file("{ \"a\": -1e-18 }") == %{"a" => -1.0e-18}
    assert Text.parse_data_file("{ \"a\": -1e-19 }") == %{"a" => -1.0e-19}
    assert Text.parse_data_file("{ \"a\": 0x0 }") == %{"a" => 0}
    assert Text.parse_data_file("{ \"a\": 0x1 }") == %{"a" => 1}
    assert Text.parse_data_file("{ \"a\": 0x01 }") == %{"a" => 1}
    assert Text.parse_data_file("{ \"a\": 0xa }") == %{"a" => 10}
    assert Text.parse_data_file("{ \"a\": 0xb }") == %{"a" => 11}
    assert Text.parse_data_file("{ \"a\": 0xc }") == %{"a" => 12}
    assert Text.parse_data_file("{ \"a\": 0xd }") == %{"a" => 13}
    assert Text.parse_data_file("{ \"a\": 0xe }") == %{"a" => 14}
    assert Text.parse_data_file("{ \"a\": 0xfa }") == %{"a" => 250}
    assert Text.parse_data_file("{ \"a\": 0xfb }") == %{"a" => 251}
    assert Text.parse_data_file("{ \"a\": 0xfc }") == %{"a" => 252}
    assert Text.parse_data_file("{ \"a\": 0xfd }") == %{"a" => 253}
    assert Text.parse_data_file("{ \"a\": 0xfe }") == %{"a" => 254}

    assert Text.parse_data_file("{ \"a\": '\\\"\\/\\'\\b\\f\\n\\r\\t\\\\' }") == %{
             "a" => "\"/'\b\f\n\r\t\\"
           }

    assert Text.parse_data_file("{ \"a\": '\\\"\\/\\'\\b\\f\\n\\r\\t\\\\' }") == %{
             "a" => "\"/'\b\f\n\r\t\\"
           }

    assert Text.parse_data_file("{ \"a\": \"\\u263A\" }") == %{"a" => "☺"}
    assert Text.parse_data_file("{ \"a\": \"\\u0000\" }") == %{"a" => <<0>>}
    assert Text.parse_data_file("{ \"a\": \"\\u1111\" }") == %{"a" => "ᄑ"}
    assert Text.parse_data_file("{ \"a\": \"\\u2222\" }") == %{"a" => "∢"}
    assert Text.parse_data_file("{ \"a\": \"\\u3333\" }") == %{"a" => "㌳"}
    assert Text.parse_data_file("{ \"a\": \"\\u4444\" }") == %{"a" => "䑄"}
    assert Text.parse_data_file("{ \"a\": \"\\u5555\" }") == %{"a" => "啕"}
    assert Text.parse_data_file("{ \"a\": \"\\u6666\" }") == %{"a" => "晦"}
    assert Text.parse_data_file("{ \"a\": \"\\u7777\" }") == %{"a" => "睷"}
    assert Text.parse_data_file("{ \"a\": \"\\u8888\" }") == %{"a" => "袈"}
    assert Text.parse_data_file("{ \"a\": \"\\u9999\" }") == %{"a" => "香"}
    assert Text.parse_data_file("{ \"a\": \"\\uaaaa\" }") == %{"a" => "ꪪ"}
    assert Text.parse_data_file("{ \"a\": \"\\ubbbb\" }") == %{"a" => "뮻"}
    assert Text.parse_data_file("{ \"a\": \"\\ucccc\" }") == %{"a" => "쳌"}
    assert Text.parse_data_file("{ \"a\": \"\\udddd\" }") == %{"a" => <<0xDD, 0xDD>>}
    assert Text.parse_data_file("{ \"a\": \"\\ueeee\" }") == %{"a" => <<0xEE, 0xEE>>}
    assert Text.parse_data_file("{ \"a\": \"\\uffff\" }") == %{"a" => <<0xFF, 0xFF>>}
    assert Text.parse_data_file("{ \"a\": \"\\uAAAA\" }") == %{"a" => "ꪪ"}
    assert Text.parse_data_file("{ \"a\": \"\\uBBBB\" }") == %{"a" => "뮻"}
    assert Text.parse_data_file("{ \"a\": \"\\uCCCC\" }") == %{"a" => "쳌"}
    assert Text.parse_data_file("{ \"a\": \"\\uDDDD\" }") == %{"a" => <<0xDD, 0xDD>>}
    assert Text.parse_data_file("{ \"a\": \"\\uEEEE\" }") == %{"a" => <<0xEE, 0xEE>>}
    assert Text.parse_data_file("{ \"a\": \"\\uFFFF\" }") == %{"a" => <<0xFF, 0xFF>>}
    assert Text.parse_data_file("{ \"a\": /**/ \"1\" }") == %{"a" => "1"}
    assert Text.parse_data_file("{ \"a\": /* */ \"1\" }") == %{"a" => "1"}
    assert Text.parse_data_file("{ \"a\": /*\n*/ \"1\" }") == %{"a" => "1"}
  end

  test "error handling in parseLibraryFile" do
    test_cases = [
      {"widget a = b(c: [ ...for args in []: \"e\" ]);", "args is a reserved word at line 1"},
      {"widget a = switch 0 { 0: a(), 0: b() };",
       "Switch has duplicate cases for key 0 at line 1"},
      {"widget a = switch 0 { default: a(), default: b() };",
       "Switch has multiple default cases at line 1"}
    ]

    for {input, expected_message} <- test_cases do
      assert_raise Text.Error, expected_message, fn ->
        Text.parse_library_file(input)
      end
    end
  end

  test "parseLibraryFile: imports" do
    result = Text.parse_library_file("import foo.bar;")
    expected_import = Model.new_import(Model.new_library_name(["foo", "bar"]))
    assert result == Model.new_remote_widget_library([expected_import], [])
  end

  test "parseLibraryFile: loops" do
    result = Text.parse_library_file("widget a = b(c: [ ...for d in []: \"e\" ]);")
    assert length(result.widgets) == 1
    widget = hd(result.widgets)
    assert widget.name == "a"
    assert %Model.ConstructorCall{name: "b", arguments: args} = widget.root
    assert %{"c" => [%Model.Loop{input: input, output: output}]} = args
    assert input == []
    assert output == "e"
  end

  test "parseLibraryFile: switch" do
    result = Text.parse_library_file("widget a = switch 0 { 0: a() };")
    assert length(result.widgets) == 1
    widget = hd(result.widgets)
    assert widget.name == "a"
    assert %Model.Switch{input: input, outputs: outputs} = widget.root
    assert input == 0
    assert %{0 => %Model.ConstructorCall{name: "a", arguments: %{}}} = outputs

    result = Text.parse_library_file("widget a = switch 0 { default: a() };")
    widget = hd(result.widgets)

    assert %Model.Switch{outputs: %{nil => %Model.ConstructorCall{name: "a", arguments: %{}}}} =
             widget.root

    result = Text.parse_library_file("widget a = b(c: switch 1 { 2: 3 });")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => switch}} = widget.root
    assert %Model.Switch{input: 1, outputs: %{2 => 3}} = switch
  end

  test "parseLibraryFile: references" do
    result = Text.parse_library_file("widget a = b(c:data.11234567890.\"e\");")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => data_ref}} = widget.root
    assert %Model.DataReference{parts: [11_234_567_890, "e"]} = data_ref

    result = Text.parse_library_file("widget a = b(c: [...for d in []: d]);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => [loop]}} = widget.root
    assert %Model.Loop{input: [], output: %Model.LoopReference{loop: 0, parts: []}} = loop

    result = Text.parse_library_file("widget a = b(c:args.foo.bar);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => args_ref}} = widget.root
    assert %Model.ArgsReference{parts: ["foo", "bar"]} = args_ref

    result = Text.parse_library_file("widget a = b(c:data.foo.bar);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => data_ref}} = widget.root
    assert %Model.DataReference{parts: ["foo", "bar"]} = data_ref

    result = Text.parse_library_file("widget a = b(c:state.foo.bar);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => state_ref}} = widget.root
    assert %Model.StateReference{parts: ["foo", "bar"]} = state_ref

    result = Text.parse_library_file("widget a = b(c: [...for d in []: d.bar]);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => [loop]}} = widget.root
    assert %Model.Loop{input: [], output: %Model.LoopReference{loop: 0, parts: ["bar"]}} = loop

    result = Text.parse_library_file("widget a = b(c:args.foo.\"bar\");")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => args_ref}} = widget.root
    assert %Model.ArgsReference{parts: ["foo", "bar"]} = args_ref

    result = Text.parse_library_file("widget a = b(c:data.foo.\"bar\");")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => data_ref}} = widget.root
    assert %Model.DataReference{parts: ["foo", "bar"]} = data_ref

    result = Text.parse_library_file("widget a = b(c:state.foo.\"bar\");")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => state_ref}} = widget.root
    assert %Model.StateReference{parts: ["foo", "bar"]} = state_ref

    result = Text.parse_library_file("widget a = b(c: [...for d in []: d.\"bar\"]);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => [loop]}} = widget.root
    assert %Model.Loop{input: [], output: %Model.LoopReference{loop: 0, parts: ["bar"]}} = loop

    result = Text.parse_library_file("widget a = b(c:args.foo.9);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => args_ref}} = widget.root
    assert %Model.ArgsReference{parts: ["foo", 9]} = args_ref

    result = Text.parse_library_file("widget a = b(c:data.foo.9);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => data_ref}} = widget.root
    assert %Model.DataReference{parts: ["foo", 9]} = data_ref

    result = Text.parse_library_file("widget a = b(c:state.foo.9);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => state_ref}} = widget.root
    assert %Model.StateReference{parts: ["foo", 9]} = state_ref

    result = Text.parse_library_file("widget a = b(c: [...for d in []: d.9]);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => [loop]}} = widget.root
    assert %Model.Loop{input: [], output: %Model.LoopReference{loop: 0, parts: [9]}} = loop

    result = Text.parse_library_file("widget a = b(c:args.foo.12);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => args_ref}} = widget.root
    assert %Model.ArgsReference{parts: ["foo", 12]} = args_ref

    result = Text.parse_library_file("widget a = b(c:data.foo.12);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => data_ref}} = widget.root
    assert %Model.DataReference{parts: ["foo", 12]} = data_ref

    result = Text.parse_library_file("widget a = b(c:state.foo.12);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => state_ref}} = widget.root
    assert %Model.StateReference{parts: ["foo", 12]} = state_ref

    result = Text.parse_library_file("widget a = b(c: [...for d in []: d.12]);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => [loop]}} = widget.root
    assert %Model.Loop{input: [], output: %Model.LoopReference{loop: 0, parts: [12]}} = loop

    result = Text.parse_library_file("widget a = b(c:args.foo.98);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => args_ref}} = widget.root
    assert %Model.ArgsReference{parts: ["foo", 98]} = args_ref

    result = Text.parse_library_file("widget a = b(c:data.foo.98);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => data_ref}} = widget.root
    assert %Model.DataReference{parts: ["foo", 98]} = data_ref

    result = Text.parse_library_file("widget a = b(c:state.foo.98);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => state_ref}} = widget.root
    assert %Model.StateReference{parts: ["foo", 98]} = state_ref

    result = Text.parse_library_file("widget a = b(c: [...for d in []: d.98]);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => [loop]}} = widget.root
    assert %Model.Loop{input: [], output: %Model.LoopReference{loop: 0, parts: [98]}} = loop

    result = Text.parse_library_file("widget a = b(c:args.foo.000);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => args_ref}} = widget.root
    assert %Model.ArgsReference{parts: ["foo", 0]} = args_ref

    result = Text.parse_library_file("widget a = b(c:data.foo.000);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => data_ref}} = widget.root
    assert %Model.DataReference{parts: ["foo", 0]} = data_ref

    result = Text.parse_library_file("widget a = b(c:state.foo.000);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => state_ref}} = widget.root
    assert %Model.StateReference{parts: ["foo", 0]} = state_ref

    result = Text.parse_library_file("widget a = b(c: [...for d in []: d.000]);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => [loop]}} = widget.root
    assert %Model.Loop{input: [], output: %Model.LoopReference{loop: 0, parts: [0]}} = loop
  end

  test "parseLibraryFile: event handlers" do
    result = Text.parse_library_file("widget a = b(c: event \"d\" { });")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => event}} = widget.root
    assert %Model.EventHandler{event_name: "d", event_arguments: %{}} = event

    result = Text.parse_library_file("widget a = b(c: set state.d = 0);")
    widget = hd(result.widgets)
    assert %Model.ConstructorCall{name: "b", arguments: %{"c" => set_state}} = widget.root
    assert %Model.SetStateHandler{state_reference: state_ref, value: 0} = set_state
    assert %Model.StateReference{parts: ["d"]} = state_ref
  end

  test "parseLibraryFile: stateful widgets" do
    result = Text.parse_library_file("widget a {} = c();")
    widget = hd(result.widgets)
    assert widget.name == "a"
    assert widget.initial_state == %{}
    assert %Model.ConstructorCall{name: "c", arguments: %{}} = widget.root

    result = Text.parse_library_file("widget a {b: 0} = c();")
    widget = hd(result.widgets)
    assert widget.name == "a"
    assert widget.initial_state == %{"b" => 0}
    assert %Model.ConstructorCall{name: "c", arguments: %{}} = widget.root
  end

  test "parseLibraryFile: widgetBuilders work" do
    result =
      Text.parse_library_file("""
        widget a = Builder(builder: (scope) => Container());
      """)

    widget = hd(result.widgets)
    assert widget.name == "a"

    assert %Model.ConstructorCall{name: "Builder", arguments: %{"builder" => builder}} =
             widget.root

    assert %Model.WidgetBuilderDeclaration{argument_name: "scope", widget: container} = builder
    assert %Model.ConstructorCall{name: "Container", arguments: %{}} = container
  end

  test "parseLibraryFile: widgetBuilders work with arguments" do
    result =
      Text.parse_library_file("""
        widget a = Builder(builder: (scope) => Container(width: scope.width));
      """)

    widget = hd(result.widgets)
    assert widget.name == "a"

    assert %Model.ConstructorCall{name: "Builder", arguments: %{"builder" => builder}} =
             widget.root

    assert %Model.WidgetBuilderDeclaration{argument_name: "scope", widget: container} = builder

    assert %Model.ConstructorCall{name: "Container", arguments: %{"width" => width_ref}} =
             container

    assert %Model.WidgetBuilderArgReference{argument_name: "scope", parts: ["width"]} =
             width_ref
  end

  test "parseLibraryFile: widgetBuilder arguments are lexical scoped" do
    result =
      Text.parse_library_file("""
        widget a = A(
          a: (s1) => B(
            b: (s2) => T(s1: s1.s1, s2: s2.s2),
          ),
        );
      """)

    widget = hd(result.widgets)
    assert widget.name == "a"
    assert %Model.ConstructorCall{name: "A", arguments: %{"a" => builder1}} = widget.root
    assert %Model.WidgetBuilderDeclaration{argument_name: "s1", widget: b_call} = builder1
    assert %Model.ConstructorCall{name: "B", arguments: %{"b" => builder2}} = b_call
    assert %Model.WidgetBuilderDeclaration{argument_name: "s2", widget: t_call} = builder2

    assert %Model.ConstructorCall{name: "T", arguments: %{"s1" => s1_ref, "s2" => s2_ref}} =
             t_call

    assert %Model.WidgetBuilderArgReference{argument_name: "s1", parts: ["s1"]} = s1_ref
    assert %Model.WidgetBuilderArgReference{argument_name: "s2", parts: ["s2"]} = s2_ref
  end

  test "parseLibraryFile: widgetBuilder arguments can be shadowed" do
    result =
      Text.parse_library_file("""
        widget a = A(
          a: (s1) => B(
            b: (s1) => T(t: s1.foo),
          ),
        );
      """)

    widget = hd(result.widgets)
    assert widget.name == "a"
    assert %Model.ConstructorCall{name: "A", arguments: %{"a" => builder1}} = widget.root
    assert %Model.WidgetBuilderDeclaration{argument_name: "s1", widget: b_call} = builder1
    assert %Model.ConstructorCall{name: "B", arguments: %{"b" => builder2}} = b_call
    assert %Model.WidgetBuilderDeclaration{argument_name: "s1", widget: t_call} = builder2
    assert %Model.ConstructorCall{name: "T", arguments: %{"t" => t_ref}} = t_call
    assert %Model.WidgetBuilderArgReference{argument_name: "s1", parts: ["foo"]} = t_ref
  end

  test "parseLibraryFile: widgetBuilders check the returned value" do
    assert_raise Text.Error, "Expecting a switch or constructor call got 1 at line 1", fn ->
      Text.parse_library_file("widget a = B(b: (foo) => 1);")
    end
  end

  test "parseLibraryFile: widgetBuilders check reserved words" do
    assert_raise Text.Error, "args is a reserved word at line 1", fn ->
      Text.parse_library_file(
        "widget a = Builder(builder: (args) => Container(width: args.width));"
      )
    end
  end

  test "parseLibraryFile: switch works with widgetBuilders" do
    result =
      Text.parse_library_file("""
        widget a = A(
          b: switch args.down {
            true: (foo) => B(),
            false: (bar) => C(),
          }
        );
      """)

    widget = hd(result.widgets)
    assert widget.name == "a"
    assert %Model.ConstructorCall{name: "A", arguments: %{"b" => switch}} = widget.root

    assert %Model.Switch{
             input: %Model.ArgsReference{parts: ["down"]},
             outputs: %{
               true => %Model.WidgetBuilderDeclaration{
                 argument_name: "foo",
                 widget: %Model.ConstructorCall{name: "B"}
               },
               false => %Model.WidgetBuilderDeclaration{
                 argument_name: "bar",
                 widget: %Model.ConstructorCall{name: "C"}
               }
             }
           } = switch
  end

  test "parseLibraryFile: widgetBuilders work with switch" do
    result =
      Text.parse_library_file("""
        widget a = A(
          b: (foo) => switch foo.letter {
            'a': A(),
            'b': B(),
          },
        );
      """)

    widget = hd(result.widgets)
    assert widget.name == "a"
    assert %Model.ConstructorCall{name: "A", arguments: %{"b" => builder}} = widget.root
    assert %Model.WidgetBuilderDeclaration{argument_name: "foo", widget: switch} = builder

    assert %Model.Switch{
             input: %Model.WidgetBuilderArgReference{argument_name: "foo", parts: ["letter"]},
             outputs: %{
               "a" => %Model.ConstructorCall{name: "A"},
               "b" => %Model.ConstructorCall{name: "B"}
             }
           } = switch
  end

  test "parseLibraryFile: widgetBuilders work with lists" do
    result =
      Text.parse_library_file("""
        widget a = A(
          b: (s1) => B(c: [s1.c]),
        );
      """)

    widget = hd(result.widgets)
    assert widget.name == "a"
    assert %Model.ConstructorCall{name: "A", arguments: %{"b" => builder}} = widget.root
    assert %Model.WidgetBuilderDeclaration{argument_name: "s1", widget: b_call} = builder
    assert %Model.ConstructorCall{name: "B", arguments: %{"c" => [c_ref]}} = b_call
    assert %Model.WidgetBuilderArgReference{argument_name: "s1", parts: ["c"]} = c_ref
  end

  test "parseLibraryFile: widgetBuilders work with maps" do
    result =
      Text.parse_library_file("""
        widget a = A(
          b: (s1) => B(c: {d: s1.d}),
        );
      """)

    widget = hd(result.widgets)
    assert widget.name == "a"
    assert %Model.ConstructorCall{name: "A", arguments: %{"b" => builder}} = widget.root
    assert %Model.WidgetBuilderDeclaration{argument_name: "s1", widget: b_call} = builder
    assert %Model.ConstructorCall{name: "B", arguments: %{"c" => %{"d" => d_ref}}} = b_call
    assert %Model.WidgetBuilderArgReference{argument_name: "s1", parts: ["d"]} = d_ref
  end

  test "parseLibraryFile: widgetBuilders work with setters" do
    result =
      Text.parse_library_file("""
        widget a {foo: 0} = A(
          b: (s1) => B(onTap: set state.foo = s1.foo),
        );
      """)

    widget = hd(result.widgets)
    assert widget.name == "a"
    assert widget.initial_state == %{"foo" => 0}
    assert %Model.ConstructorCall{name: "A", arguments: %{"b" => builder}} = widget.root
    assert %Model.WidgetBuilderDeclaration{argument_name: "s1", widget: b_call} = builder
    assert %Model.ConstructorCall{name: "B", arguments: %{"onTap" => setter}} = b_call

    assert %Model.SetStateHandler{
             state_reference: %Model.StateReference{parts: ["foo"]},
             value: %Model.WidgetBuilderArgReference{argument_name: "s1", parts: ["foo"]}
           } = setter
  end

  test "parseLibraryFile: widgetBuilders work with events" do
    result =
      Text.parse_library_file("""
        widget a {foo: 0} = A(
          b: (s1) => B(onTap: event "foo" {result: s1.result})
        );
      """)

    widget = hd(result.widgets)
    assert widget.name == "a"
    assert widget.initial_state == %{"foo" => 0}
    assert %Model.ConstructorCall{name: "A", arguments: %{"b" => builder}} = widget.root
    assert %Model.WidgetBuilderDeclaration{argument_name: "s1", widget: b_call} = builder
    assert %Model.ConstructorCall{name: "B", arguments: %{"onTap" => event_handler}} = b_call

    assert %Model.EventHandler{
             event_name: "foo",
             event_arguments: %{
               "result" => %Model.WidgetBuilderArgReference{
                 argument_name: "s1",
                 parts: ["result"]
               }
             }
           } = event_handler
  end

  test "parseLibraryFile: complex nested structures" do
    result =
      Text.parse_library_file("""
      import widgets;
      import material;

      widget complexWidget = Column(
          children: [
            Text(text: "Header"),
            ...for item in data.items:
              Row(
                children: [
                  Text(text: ["Item: ", item.name]),
                  switch item.type {
                    "button": Button(
                      onPressed: event "buttonPressed" { id: item.id },
                      child: Text(text: "Press me")
                    ),
                    "checkbox": Checkbox(
                      value: state.value,
                      onChanged: set state.values = item.id
                    ),
                    default: Text(text: "Unknown type")
                  }
                ]
              ),
            Builder(
              builder: (context) => Text(text: [context.itemCount])
            )
          ]
        );
      """)

    widget = hd(result.widgets)
    assert widget.name == "complexWidget"

    assert %Model.ConstructorCall{name: "Column", arguments: %{"children" => children}} =
             widget.root

    [header, loop, builder] = children

    assert %Model.ConstructorCall{name: "Text", arguments: %{"text" => "Header"}} = header

    assert %Model.Loop{
             input: %Model.DataReference{parts: ["items"]},
             output: %Model.ConstructorCall{
               name: "Row",
               arguments: %{"children" => row_children}
             }
           } = loop

    [name_text, switch] = row_children

    assert %Model.ConstructorCall{
             name: "Text",
             arguments: %{"text" => ["Item: ", %Model.LoopReference{loop: 0, parts: ["name"]}]}
           } = name_text

    assert %Model.Switch{
             input: %Model.LoopReference{loop: 0, parts: ["type"]},
             outputs: %{
               "button" => %Model.ConstructorCall{
                 name: "Button",
                 arguments: %{
                   "onPressed" => %Model.EventHandler{
                     event_name: "buttonPressed",
                     event_arguments: %{
                       "id" => %Model.LoopReference{loop: 0, parts: ["id"]}
                     }
                   },
                   "child" => %Model.ConstructorCall{
                     name: "Text",
                     arguments: %{"text" => "Press me"}
                   }
                 }
               },
               "checkbox" => %Model.ConstructorCall{
                 name: "Checkbox",
                 arguments: %{
                   "value" => %Model.StateReference{parts: ["value"]},
                   "onChanged" => %Model.SetStateHandler{
                     state_reference: %Model.StateReference{parts: ["values"]},
                     value: %Model.LoopReference{loop: 0, parts: ["id"]}
                   }
                 }
               },
               nil => %Model.ConstructorCall{
                 name: "Text",
                 arguments: %{"text" => "Unknown type"}
               }
             }
           } = switch

    assert %Model.ConstructorCall{name: "Builder", arguments: %{"builder" => builder_decl}} =
             builder

    assert %Model.WidgetBuilderDeclaration{
             argument_name: "context",
             widget: %Model.ConstructorCall{
               name: "Text",
               arguments: %{
                 "text" => [
                   %Model.WidgetBuilderArgReference{
                     argument_name: "context",
                     parts: ["itemCount"]
                   }
                 ]
               }
             }
           } = builder_decl
  end

  test "parseLibraryFile: loops and concatenation in text" do
    result =
      Text.parse_library_file("""
      import core;

      widget root = test(
        list: ['A'],
        loop: [...for b in ['B', 'C']: b]
      );

      widget test = Text(
        textDirection: 'ltr',
        text: [
          '>',
          ...for a in args.list: a,
          ...for b in args.loop: b,
          '<',
        ],
      );
      """)

    widgets = result.widgets
    assert length(widgets) == 2
    [root_widget, test_widget] = widgets

    assert root_widget.name == "root"
    assert %Model.ConstructorCall{name: "test", arguments: root_args} = root_widget.root
    assert root_args["list"] == ["A"]

    assert [
             %Model.Loop{
               input: ["B", "C"],
               output: %Model.LoopReference{loop: 0}
             }
           ] = root_args["loop"]

    assert test_widget.name == "test"
    assert %Model.ConstructorCall{name: "Text", arguments: text_args} = test_widget.root
    assert text_args["textDirection"] == "ltr"

    assert [
             ">",
             %Model.Loop{
               input: %Model.ArgsReference{parts: ["list"]},
               output: %Model.LoopReference{loop: 0}
             },
             %Model.Loop{
               input: %Model.ArgsReference{parts: ["loop"]},
               output: %Model.LoopReference{loop: 0}
             },
             "<"
           ] = text_args["text"]

    test_args = %{
      "list" => ["A"],
      "loop" => ["B", "C"]
    }

    text_elements =
      Enum.flat_map(text_args["text"], fn
        %Model.Loop{
          input: %Model.ArgsReference{parts: ["list"]},
          output: %Model.LoopReference{loop: 0}
        } ->
          test_args["list"]

        %Model.Loop{
          input: %Model.ArgsReference{parts: ["loop"]},
          output: %Model.LoopReference{loop: 0}
        } ->
          test_args["loop"]

        other ->
          [other]
      end)

    concatenated_text = Enum.join(text_elements)
    assert concatenated_text == ">ABC<"
  end

  test "parseLibraryFile: nested builders and references" do
    template = """
      import core;
      import local;

      widget test = Sum(
        operand1: 1,
        operand2: 2,
        builder: (result1) => IntToString(
          value: result1.result,
          builder: (result2) => Text(
            text: ['1 + 2 = ', result2.result],
            textDirection: 'ltr'
          ),
        ),
      );
    """

    result = Text.parse_library_file(template)
    widget = hd(result.widgets)
    assert widget.name == "test"

    assert %Model.ConstructorCall{
             name: "Sum",
             arguments: %{
               "operand1" => 1,
               "operand2" => 2,
               "builder" => sum_builder
             }
           } = widget.root

    assert %Model.WidgetBuilderDeclaration{
             argument_name: "result1",
             widget: int_to_string_call
           } = sum_builder

    assert %Model.ConstructorCall{
             name: "IntToString",
             arguments: %{
               "value" => %Model.WidgetBuilderArgReference{
                 argument_name: "result1",
                 parts: ["result"]
               },
               "builder" => int_to_string_builder
             }
           } = int_to_string_call

    assert %Model.WidgetBuilderDeclaration{
             argument_name: "result2",
             widget: text_call
           } = int_to_string_builder

    assert %Model.ConstructorCall{
             name: "Text",
             arguments: %{
               "text" => [
                 "1 + 2 = ",
                 %Model.WidgetBuilderArgReference{
                   argument_name: "result2",
                   parts: ["result"]
                 }
               ],
               "textDirection" => "ltr"
             }
           } = text_call
  end

  test "parseLibraryFile: widgets with state, loops, and references" do
    template = """
      import core;
      widget verify { state: 0x00 } = GestureDetector(
        onTap: set state.state = args.value.a.b,
        child: ColoredBox(color: switch state.state {
          0x00: 0xFF000001,
          0xEE: 0xFF000002,
        }),
      );
      widget remote = SizedBox(child: args.corn.0);
      widget root = remote(
        corn: [
          ...for v in data.list:
            verify(value: v),
        ],
      );
    """

    result = Text.parse_library_file(template)
    widgets = result.widgets
    assert length(widgets) == 3

    verify_widget = Enum.find(widgets, fn widget -> widget.name == "verify" end)
    remote_widget = Enum.find(widgets, fn widget -> widget.name == "remote" end)
    root_widget = Enum.find(widgets, fn widget -> widget.name == "root" end)

    assert verify_widget != nil
    assert verify_widget.initial_state == %{"state" => 0x00}

    assert %Model.ConstructorCall{
             name: "GestureDetector",
             arguments: %{
               "onTap" => on_tap,
               "child" => child
             }
           } = verify_widget.root

    assert %Model.SetStateHandler{
             state_reference: %Model.StateReference{parts: ["state"]},
             value: %Model.ArgsReference{parts: ["value", "a", "b"]}
           } = on_tap

    assert %Model.ConstructorCall{
             name: "ColoredBox",
             arguments: %{
               "color" => color_switch
             }
           } = child

    assert %Model.Switch{
             input: %Model.StateReference{parts: ["state"]},
             outputs: %{
               0x00 => 0xFF000001,
               0xEE => 0xFF000002
             }
           } = color_switch

    assert remote_widget != nil

    assert %Model.ConstructorCall{
             name: "SizedBox",
             arguments: %{
               "child" => child_arg
             }
           } = remote_widget.root

    assert %Model.ArgsReference{parts: ["corn", 0]} = child_arg
    assert root_widget != nil

    assert %Model.ConstructorCall{
             name: "remote",
             arguments: %{
               "corn" => corn_value
             }
           } = root_widget.root

    assert [
             %Model.Loop{
               input: %Model.DataReference{parts: ["list"]},
               output: verify_call
             }
           ] = corn_value

    assert %Model.ConstructorCall{
             name: "verify",
             arguments: %{
               "value" => %Model.LoopReference{loop: 0}
             }
           } = verify_call
  end
end
