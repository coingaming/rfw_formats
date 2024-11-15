defmodule RfwFormats.IntegrationTest do
  use ExUnit.Case

  alias RfwFormats.{Text, Binary, Model, OrderedMap}

  test "Complex template with nested widgets and state" do
    template = """
    import widgets;
    import material;

    widget root {counter: 0} = Column(
      children: [
        Text(text: ["Current count: ", state.counter]),
        Row(
          children: [
            Button(
              onPressed: event "decrement" {},
              child: Text(text: "-")
            ),
            Button(
              onPressed: event "increment" {},
              child: Text(text: "+")
            )
          ]
        ),
        Builder(
          builder: (context) => switch context.theme {
            "dark": Container(color: 0xFF000000),
            "light": Container(color: 0xFFFFFFFF),
            default: Container()
          }
        )
      ]
    );
    """

    expected_binary =
      <<254, 82, 70, 87, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0,
        119, 105, 100, 103, 101, 116, 115, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 109,
        97, 116, 101, 114, 105, 97, 108, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 114, 111,
        111, 116, 1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 99, 111, 117, 110, 116, 101,
        114, 2, 0, 0, 0, 0, 0, 0, 0, 0, 9, 6, 0, 0, 0, 0, 0, 0, 0, 67, 111, 108, 117, 109, 110, 1,
        0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105, 108, 100, 114, 101, 110, 5, 3,
        0, 0, 0, 0, 0, 0, 0, 9, 4, 0, 0, 0, 0, 0, 0, 0, 84, 101, 120, 116, 1, 0, 0, 0, 0, 0, 0, 0,
        4, 0, 0, 0, 0, 0, 0, 0, 116, 101, 120, 116, 5, 2, 0, 0, 0, 0, 0, 0, 0, 4, 15, 0, 0, 0, 0,
        0, 0, 0, 67, 117, 114, 114, 101, 110, 116, 32, 99, 111, 117, 110, 116, 58, 32, 13, 1, 0,
        0, 0, 0, 0, 0, 0, 4, 7, 0, 0, 0, 0, 0, 0, 0, 99, 111, 117, 110, 116, 101, 114, 9, 3, 0, 0,
        0, 0, 0, 0, 0, 82, 111, 119, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105,
        108, 100, 114, 101, 110, 5, 2, 0, 0, 0, 0, 0, 0, 0, 9, 6, 0, 0, 0, 0, 0, 0, 0, 66, 117,
        116, 116, 111, 110, 2, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 111, 110, 80, 114,
        101, 115, 115, 101, 100, 14, 9, 0, 0, 0, 0, 0, 0, 0, 100, 101, 99, 114, 101, 109, 101,
        110, 116, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105, 108, 100, 9, 4, 0,
        0, 0, 0, 0, 0, 0, 84, 101, 120, 116, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 116,
        101, 120, 116, 4, 1, 0, 0, 0, 0, 0, 0, 0, 45, 9, 6, 0, 0, 0, 0, 0, 0, 0, 66, 117, 116,
        116, 111, 110, 2, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 111, 110, 80, 114, 101,
        115, 115, 101, 100, 14, 9, 0, 0, 0, 0, 0, 0, 0, 105, 110, 99, 114, 101, 109, 101, 110,
        116, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105, 108, 100, 9, 4, 0, 0,
        0, 0, 0, 0, 0, 84, 101, 120, 116, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 116,
        101, 120, 116, 4, 1, 0, 0, 0, 0, 0, 0, 0, 43, 9, 7, 0, 0, 0, 0, 0, 0, 0, 66, 117, 105,
        108, 100, 101, 114, 1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 98, 117, 105, 108,
        100, 101, 114, 18, 7, 0, 0, 0, 0, 0, 0, 0, 99, 111, 110, 116, 101, 120, 116, 15, 19, 7, 0,
        0, 0, 0, 0, 0, 0, 99, 111, 110, 116, 101, 120, 116, 1, 0, 0, 0, 0, 0, 0, 0, 4, 5, 0, 0, 0,
        0, 0, 0, 0, 116, 104, 101, 109, 101, 3, 0, 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0,
        100, 97, 114, 107, 9, 9, 0, 0, 0, 0, 0, 0, 0, 67, 111, 110, 116, 97, 105, 110, 101, 114,
        1, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 99, 111, 108, 111, 114, 2, 0, 0, 0, 255,
        0, 0, 0, 0, 4, 5, 0, 0, 0, 0, 0, 0, 0, 108, 105, 103, 104, 116, 9, 9, 0, 0, 0, 0, 0, 0, 0,
        67, 111, 110, 116, 97, 105, 110, 101, 114, 1, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0,
        99, 111, 108, 111, 114, 2, 255, 255, 255, 255, 0, 0, 0, 0, 16, 9, 9, 0, 0, 0, 0, 0, 0, 0,
        67, 111, 110, 116, 97, 105, 110, 101, 114, 0, 0, 0, 0, 0, 0, 0, 0>>

    parsed = Text.parse_library_file(template)
    binary = Binary.encode_library_blob(parsed)
    decoded = Binary.decode_library_blob(binary)

    assert binary == expected_binary
    assert decoded == parsed

    assert length(decoded.imports) == 2
    assert length(decoded.widgets) == 1

    widget = hd(decoded.widgets)
    assert widget.name == "root"
    assert widget.initial_state == %OrderedMap{keys: ["counter"], map: %{"counter" => 0}}

    assert %Model.ConstructorCall{name: "Column"} = widget.root
    children = widget.root.arguments["children"]
    assert length(children) == 3

    [text, row, builder] = children
    assert %Model.ConstructorCall{name: "Text"} = text

    assert text.arguments["text"] == [
             "Current count: ",
             %Model.StateReference{parts: ["counter"]}
           ]

    assert %Model.ConstructorCall{name: "Row"} = row
    row_children = row.arguments["children"]
    assert length(row_children) == 2

    [decrement_button, increment_button] = row_children
    assert %Model.ConstructorCall{name: "Button"} = decrement_button
    assert %Model.EventHandler{event_name: "decrement"} = decrement_button.arguments["onPressed"]
    assert %Model.ConstructorCall{name: "Text"} = decrement_button.arguments["child"]
    assert decrement_button.arguments["child"].arguments["text"] == "-"

    assert %Model.ConstructorCall{name: "Button"} = increment_button
    assert %Model.EventHandler{event_name: "increment"} = increment_button.arguments["onPressed"]
    assert %Model.ConstructorCall{name: "Text"} = increment_button.arguments["child"]
    assert increment_button.arguments["child"].arguments["text"] == "+"

    assert %Model.ConstructorCall{name: "Builder"} = builder
    assert %Model.WidgetBuilderDeclaration{} = builder.arguments["builder"]
  end

  test "Template with complex data structures and loops" do
    template = """
    widget list = Column(
      children: [
        ...for item in data.items:
          Row(
            children: [
              Text(text: item.name),
              switch item.type {
                "active": Icon(icon: 0xe837),
                "inactive": Icon(icon: 0xe836)
              }
            ]
          ),
        Builder(
          builder: (stats) => Text(
            text: ["Total items: ", stats.count]
          )
        )
      ]
    );
    """

    expected_binary =
      <<254, 82, 70, 87, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0,
        108, 105, 115, 116, 0, 0, 0, 0, 0, 0, 0, 0, 9, 6, 0, 0, 0, 0, 0, 0, 0, 67, 111, 108, 117,
        109, 110, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105, 108, 100, 114,
        101, 110, 5, 2, 0, 0, 0, 0, 0, 0, 0, 8, 11, 1, 0, 0, 0, 0, 0, 0, 0, 4, 5, 0, 0, 0, 0, 0,
        0, 0, 105, 116, 101, 109, 115, 9, 3, 0, 0, 0, 0, 0, 0, 0, 82, 111, 119, 1, 0, 0, 0, 0, 0,
        0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105, 108, 100, 114, 101, 110, 5, 2, 0, 0, 0, 0, 0,
        0, 0, 9, 4, 0, 0, 0, 0, 0, 0, 0, 84, 101, 120, 116, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0,
        0, 0, 0, 116, 101, 120, 116, 12, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 4, 4, 0,
        0, 0, 0, 0, 0, 0, 110, 97, 109, 101, 15, 12, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
        0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 116, 121, 112, 101, 2, 0, 0, 0, 0, 0, 0, 0, 4, 6, 0, 0, 0,
        0, 0, 0, 0, 97, 99, 116, 105, 118, 101, 9, 4, 0, 0, 0, 0, 0, 0, 0, 73, 99, 111, 110, 1, 0,
        0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 105, 99, 111, 110, 2, 55, 232, 0, 0, 0, 0, 0, 0,
        4, 8, 0, 0, 0, 0, 0, 0, 0, 105, 110, 97, 99, 116, 105, 118, 101, 9, 4, 0, 0, 0, 0, 0, 0,
        0, 73, 99, 111, 110, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 105, 99, 111, 110, 2,
        54, 232, 0, 0, 0, 0, 0, 0, 9, 7, 0, 0, 0, 0, 0, 0, 0, 66, 117, 105, 108, 100, 101, 114, 1,
        0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 98, 117, 105, 108, 100, 101, 114, 18, 5, 0,
        0, 0, 0, 0, 0, 0, 115, 116, 97, 116, 115, 9, 4, 0, 0, 0, 0, 0, 0, 0, 84, 101, 120, 116, 1,
        0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 116, 101, 120, 116, 5, 2, 0, 0, 0, 0, 0, 0,
        0, 4, 13, 0, 0, 0, 0, 0, 0, 0, 84, 111, 116, 97, 108, 32, 105, 116, 101, 109, 115, 58, 32,
        19, 5, 0, 0, 0, 0, 0, 0, 0, 115, 116, 97, 116, 115, 1, 0, 0, 0, 0, 0, 0, 0, 4, 5, 0, 0, 0,
        0, 0, 0, 0, 99, 111, 117, 110, 116>>

    parsed = Text.parse_library_file(template)
    binary = Binary.encode_library_blob(parsed)
    decoded = Binary.decode_library_blob(binary)

    assert binary == expected_binary
    assert decoded == parsed

    widget = hd(decoded.widgets)
    assert widget.name == "list"

    assert %Model.ConstructorCall{name: "Column"} = widget.root
    children = widget.root.arguments["children"]
    assert length(children) == 2

    [loop, _builder] = children
    assert %Model.Loop{} = loop
    assert %Model.DataReference{parts: ["items"]} = loop.input

    assert %Model.ConstructorCall{name: "Row"} = loop.output
    row_children = loop.output.arguments["children"]
    assert length(row_children) == 2

    [text, switch] = row_children
    assert %Model.ConstructorCall{name: "Text"} = text
    assert %Model.Switch{} = switch
    assert length(Map.keys(switch.outputs.map)) == 2
  end

  test "Complex nested widget builders with state management" do
    template = """
    import widgets;
    import material;

    widget form {
      formData: {
        username: "",
        email: "",
        isValid: false
      }
    } = Column(
      children: [
        TextField(
          value: state.formData.username,
          onChanged: set state.formData.username = args.text,
          decoration: InputDecoration(
            labelText: "Username",
            errorText: switch state.formData.isValid {
              false: "Username is required"
            }
          )
        ),
        TextField(
          value: state.formData.email,
          onChanged: set state.formData.email = args.text,
          decoration: InputDecoration(
            labelText: "Email",
            errorText: switch state.formData.isValid {
              false: "Invalid email format"
            }
          )
        ),
        Builder(
          builder: (context) => Column(
            children: [
              Text(text: ["Current Form State:"]),
              ...for field in ["username", "email"]:
                Text(text: [
                  field,
                  ": ",
                  switch field {
                    "username": state.formData.username,
                    "email": state.formData.email,
                    default: ""
                  }
                ])
            ]
          )
        ),
        Button(
          onPressed: event "validateForm" {
            username: state.formData.username,
            email: state.formData.email
          },
          child: Text(text: "Submit")
        )
      ]
    );
    """

    expected_binary =
      <<254, 82, 70, 87, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0,
        119, 105, 100, 103, 101, 116, 115, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 109,
        97, 116, 101, 114, 105, 97, 108, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 102, 111,
        114, 109, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 102, 111, 114, 109, 68, 97, 116,
        97, 7, 3, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 117, 115, 101, 114, 110, 97, 109,
        101, 4, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 101, 109, 97, 105, 108, 4, 0, 0,
        0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 105, 115, 86, 97, 108, 105, 100, 0, 9, 6, 0, 0,
        0, 0, 0, 0, 0, 67, 111, 108, 117, 109, 110, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0,
        0, 99, 104, 105, 108, 100, 114, 101, 110, 5, 4, 0, 0, 0, 0, 0, 0, 0, 9, 9, 0, 0, 0, 0, 0,
        0, 0, 84, 101, 120, 116, 70, 105, 101, 108, 100, 3, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0,
        0, 0, 118, 97, 108, 117, 101, 13, 2, 0, 0, 0, 0, 0, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, 102,
        111, 114, 109, 68, 97, 116, 97, 4, 8, 0, 0, 0, 0, 0, 0, 0, 117, 115, 101, 114, 110, 97,
        109, 101, 9, 0, 0, 0, 0, 0, 0, 0, 111, 110, 67, 104, 97, 110, 103, 101, 100, 17, 2, 0, 0,
        0, 0, 0, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, 102, 111, 114, 109, 68, 97, 116, 97, 4, 8, 0, 0,
        0, 0, 0, 0, 0, 117, 115, 101, 114, 110, 97, 109, 101, 10, 1, 0, 0, 0, 0, 0, 0, 0, 4, 4, 0,
        0, 0, 0, 0, 0, 0, 116, 101, 120, 116, 10, 0, 0, 0, 0, 0, 0, 0, 100, 101, 99, 111, 114, 97,
        116, 105, 111, 110, 9, 15, 0, 0, 0, 0, 0, 0, 0, 73, 110, 112, 117, 116, 68, 101, 99, 111,
        114, 97, 116, 105, 111, 110, 2, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 108, 97, 98,
        101, 108, 84, 101, 120, 116, 4, 8, 0, 0, 0, 0, 0, 0, 0, 85, 115, 101, 114, 110, 97, 109,
        101, 9, 0, 0, 0, 0, 0, 0, 0, 101, 114, 114, 111, 114, 84, 101, 120, 116, 15, 13, 2, 0, 0,
        0, 0, 0, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, 102, 111, 114, 109, 68, 97, 116, 97, 4, 7, 0, 0,
        0, 0, 0, 0, 0, 105, 115, 86, 97, 108, 105, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 4, 20, 0, 0, 0,
        0, 0, 0, 0, 85, 115, 101, 114, 110, 97, 109, 101, 32, 105, 115, 32, 114, 101, 113, 117,
        105, 114, 101, 100, 9, 9, 0, 0, 0, 0, 0, 0, 0, 84, 101, 120, 116, 70, 105, 101, 108, 100,
        3, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 118, 97, 108, 117, 101, 13, 2, 0, 0, 0, 0,
        0, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, 102, 111, 114, 109, 68, 97, 116, 97, 4, 5, 0, 0, 0, 0,
        0, 0, 0, 101, 109, 97, 105, 108, 9, 0, 0, 0, 0, 0, 0, 0, 111, 110, 67, 104, 97, 110, 103,
        101, 100, 17, 2, 0, 0, 0, 0, 0, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, 102, 111, 114, 109, 68,
        97, 116, 97, 4, 5, 0, 0, 0, 0, 0, 0, 0, 101, 109, 97, 105, 108, 10, 1, 0, 0, 0, 0, 0, 0,
        0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 116, 101, 120, 116, 10, 0, 0, 0, 0, 0, 0, 0, 100, 101, 99,
        111, 114, 97, 116, 105, 111, 110, 9, 15, 0, 0, 0, 0, 0, 0, 0, 73, 110, 112, 117, 116, 68,
        101, 99, 111, 114, 97, 116, 105, 111, 110, 2, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0,
        108, 97, 98, 101, 108, 84, 101, 120, 116, 4, 5, 0, 0, 0, 0, 0, 0, 0, 69, 109, 97, 105,
        108, 9, 0, 0, 0, 0, 0, 0, 0, 101, 114, 114, 111, 114, 84, 101, 120, 116, 15, 13, 2, 0, 0,
        0, 0, 0, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, 102, 111, 114, 109, 68, 97, 116, 97, 4, 7, 0, 0,
        0, 0, 0, 0, 0, 105, 115, 86, 97, 108, 105, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 4, 20, 0, 0, 0,
        0, 0, 0, 0, 73, 110, 118, 97, 108, 105, 100, 32, 101, 109, 97, 105, 108, 32, 102, 111,
        114, 109, 97, 116, 9, 7, 0, 0, 0, 0, 0, 0, 0, 66, 117, 105, 108, 100, 101, 114, 1, 0, 0,
        0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 98, 117, 105, 108, 100, 101, 114, 18, 7, 0, 0, 0,
        0, 0, 0, 0, 99, 111, 110, 116, 101, 120, 116, 9, 6, 0, 0, 0, 0, 0, 0, 0, 67, 111, 108,
        117, 109, 110, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105, 108, 100,
        114, 101, 110, 5, 2, 0, 0, 0, 0, 0, 0, 0, 9, 4, 0, 0, 0, 0, 0, 0, 0, 84, 101, 120, 116, 1,
        0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 116, 101, 120, 116, 5, 1, 0, 0, 0, 0, 0, 0,
        0, 4, 19, 0, 0, 0, 0, 0, 0, 0, 67, 117, 114, 114, 101, 110, 116, 32, 70, 111, 114, 109,
        32, 83, 116, 97, 116, 101, 58, 8, 5, 2, 0, 0, 0, 0, 0, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0,
        117, 115, 101, 114, 110, 97, 109, 101, 4, 5, 0, 0, 0, 0, 0, 0, 0, 101, 109, 97, 105, 108,
        9, 4, 0, 0, 0, 0, 0, 0, 0, 84, 101, 120, 116, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0,
        0, 116, 101, 120, 116, 5, 3, 0, 0, 0, 0, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 4, 2, 0, 0, 0, 0, 0, 0, 0, 58, 32, 15, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, 117, 115, 101, 114, 110,
        97, 109, 101, 13, 2, 0, 0, 0, 0, 0, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, 102, 111, 114, 109,
        68, 97, 116, 97, 4, 8, 0, 0, 0, 0, 0, 0, 0, 117, 115, 101, 114, 110, 97, 109, 101, 4, 5,
        0, 0, 0, 0, 0, 0, 0, 101, 109, 97, 105, 108, 13, 2, 0, 0, 0, 0, 0, 0, 0, 4, 8, 0, 0, 0, 0,
        0, 0, 0, 102, 111, 114, 109, 68, 97, 116, 97, 4, 5, 0, 0, 0, 0, 0, 0, 0, 101, 109, 97,
        105, 108, 16, 4, 0, 0, 0, 0, 0, 0, 0, 0, 9, 6, 0, 0, 0, 0, 0, 0, 0, 66, 117, 116, 116,
        111, 110, 2, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 111, 110, 80, 114, 101, 115,
        115, 101, 100, 14, 12, 0, 0, 0, 0, 0, 0, 0, 118, 97, 108, 105, 100, 97, 116, 101, 70, 111,
        114, 109, 2, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 117, 115, 101, 114, 110, 97,
        109, 101, 13, 2, 0, 0, 0, 0, 0, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0, 102, 111, 114, 109, 68,
        97, 116, 97, 4, 8, 0, 0, 0, 0, 0, 0, 0, 117, 115, 101, 114, 110, 97, 109, 101, 5, 0, 0, 0,
        0, 0, 0, 0, 101, 109, 97, 105, 108, 13, 2, 0, 0, 0, 0, 0, 0, 0, 4, 8, 0, 0, 0, 0, 0, 0, 0,
        102, 111, 114, 109, 68, 97, 116, 97, 4, 5, 0, 0, 0, 0, 0, 0, 0, 101, 109, 97, 105, 108, 5,
        0, 0, 0, 0, 0, 0, 0, 99, 104, 105, 108, 100, 9, 4, 0, 0, 0, 0, 0, 0, 0, 84, 101, 120, 116,
        1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 116, 101, 120, 116, 4, 6, 0, 0, 0, 0, 0,
        0, 0, 83, 117, 98, 109, 105, 116>>

    parsed = Text.parse_library_file(template)
    binary = Binary.encode_library_blob(parsed)
    decoded = Binary.decode_library_blob(binary)

    assert binary == expected_binary
    assert decoded == parsed

    widget = hd(decoded.widgets)
    assert widget.name == "form"

    assert %OrderedMap{
             keys: ["formData"],
             map: %{
               "formData" => %OrderedMap{
                 keys: ["username", "email", "isValid"],
                 map: %{
                   "username" => "",
                   "email" => "",
                   "isValid" => false
                 }
               }
             }
           } = widget.initial_state

    assert %Model.ConstructorCall{name: "Column"} = widget.root
    children = widget.root.arguments["children"]
    assert length(children) == 4

    [username_field, email_field, form_state_builder, submit_button] = children

    assert %Model.ConstructorCall{name: "TextField"} = username_field

    assert %Model.StateReference{parts: ["formData", "username"]} =
             username_field.arguments["value"]

    assert %Model.SetStateHandler{
             state_reference: %Model.StateReference{parts: ["formData", "username"]},
             value: %Model.ArgsReference{parts: ["text"]}
           } = username_field.arguments["onChanged"]

    assert %Model.ConstructorCall{name: "TextField"} = email_field
    assert %Model.StateReference{parts: ["formData", "email"]} = email_field.arguments["value"]

    assert %Model.SetStateHandler{
             state_reference: %Model.StateReference{parts: ["formData", "email"]},
             value: %Model.ArgsReference{parts: ["text"]}
           } = email_field.arguments["onChanged"]

    assert %Model.ConstructorCall{name: "Builder"} = form_state_builder
    assert %Model.WidgetBuilderDeclaration{} = form_state_builder.arguments["builder"]

    assert %Model.ConstructorCall{name: "Button"} = submit_button

    assert %Model.EventHandler{
             event_name: "validateForm",
             event_arguments: %OrderedMap{
               keys: ["username", "email"],
               map: %{
                 "username" => %Model.StateReference{parts: ["formData", "username"]},
                 "email" => %Model.StateReference{parts: ["formData", "email"]}
               }
             }
           } = submit_button.arguments["onPressed"]
  end

  test "Complex data transformation with nested loops and builders" do
    template = """
    import widgets;
    import material;

    widget dataGrid = Column(
      children: [
        Row(
          children: [
            Text(text: "Data Grid"),
            Builder(
              builder: (stats) => Text(
                text: ["Total Rows: ", stats.totalRows]
              )
            )
          ]
        ),
        ...for section in data.sections:
          Column(
            children: [
              Container(
                color: 0xFFEEEEEE,
                child: Text(text: section.title)
              ),
              ...for row in section.rows:
                Builder(
                  builder: (context) => Row(
                    children: [
                      ...for cell in row.cells:
                        Container(
                          padding: EdgeInsets(all: 8),
                          child: switch cell.type {
                            "text": Text(text: cell.value),
                            "number": Text(
                              text: cell.value,
                              style: TextStyle(
                                color: switch cell.value {
                                  0: 0xFF0000,
                                  default: 0x000000
                                }
                              )
                            ),
                            "action": Button(
                              onPressed: event "cellAction" {
                                sectionId: section.id,
                                rowId: row.id,
                                cellId: cell.id
                              },
                              child: Text(text: "Action")
                            ),
                            default: Text(text: "Unknown")
                          }
                        )
                    ]
                  )
                )
            ]
          )
      ]
    );
    """

    expected_binary =
      <<254, 82, 70, 87, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0,
        119, 105, 100, 103, 101, 116, 115, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 109,
        97, 116, 101, 114, 105, 97, 108, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 100, 97,
        116, 97, 71, 114, 105, 100, 0, 0, 0, 0, 0, 0, 0, 0, 9, 6, 0, 0, 0, 0, 0, 0, 0, 67, 111,
        108, 117, 109, 110, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105, 108,
        100, 114, 101, 110, 5, 2, 0, 0, 0, 0, 0, 0, 0, 9, 3, 0, 0, 0, 0, 0, 0, 0, 82, 111, 119, 1,
        0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105, 108, 100, 114, 101, 110, 5, 2,
        0, 0, 0, 0, 0, 0, 0, 9, 4, 0, 0, 0, 0, 0, 0, 0, 84, 101, 120, 116, 1, 0, 0, 0, 0, 0, 0, 0,
        4, 0, 0, 0, 0, 0, 0, 0, 116, 101, 120, 116, 4, 9, 0, 0, 0, 0, 0, 0, 0, 68, 97, 116, 97,
        32, 71, 114, 105, 100, 9, 7, 0, 0, 0, 0, 0, 0, 0, 66, 117, 105, 108, 100, 101, 114, 1, 0,
        0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 98, 117, 105, 108, 100, 101, 114, 18, 5, 0, 0,
        0, 0, 0, 0, 0, 115, 116, 97, 116, 115, 9, 4, 0, 0, 0, 0, 0, 0, 0, 84, 101, 120, 116, 1, 0,
        0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 116, 101, 120, 116, 5, 2, 0, 0, 0, 0, 0, 0, 0,
        4, 12, 0, 0, 0, 0, 0, 0, 0, 84, 111, 116, 97, 108, 32, 82, 111, 119, 115, 58, 32, 19, 5,
        0, 0, 0, 0, 0, 0, 0, 115, 116, 97, 116, 115, 1, 0, 0, 0, 0, 0, 0, 0, 4, 9, 0, 0, 0, 0, 0,
        0, 0, 116, 111, 116, 97, 108, 82, 111, 119, 115, 8, 11, 1, 0, 0, 0, 0, 0, 0, 0, 4, 8, 0,
        0, 0, 0, 0, 0, 0, 115, 101, 99, 116, 105, 111, 110, 115, 9, 6, 0, 0, 0, 0, 0, 0, 0, 67,
        111, 108, 117, 109, 110, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105,
        108, 100, 114, 101, 110, 5, 2, 0, 0, 0, 0, 0, 0, 0, 9, 9, 0, 0, 0, 0, 0, 0, 0, 67, 111,
        110, 116, 97, 105, 110, 101, 114, 2, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 99, 111,
        108, 111, 114, 2, 238, 238, 238, 255, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105,
        108, 100, 9, 4, 0, 0, 0, 0, 0, 0, 0, 84, 101, 120, 116, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0,
        0, 0, 0, 0, 0, 116, 101, 120, 116, 12, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 4,
        5, 0, 0, 0, 0, 0, 0, 0, 116, 105, 116, 108, 101, 8, 12, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
        0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 114, 111, 119, 115, 9, 7, 0, 0, 0, 0, 0, 0, 0,
        66, 117, 105, 108, 100, 101, 114, 1, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 98, 117,
        105, 108, 100, 101, 114, 18, 7, 0, 0, 0, 0, 0, 0, 0, 99, 111, 110, 116, 101, 120, 116, 9,
        3, 0, 0, 0, 0, 0, 0, 0, 82, 111, 119, 1, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 99,
        104, 105, 108, 100, 114, 101, 110, 5, 1, 0, 0, 0, 0, 0, 0, 0, 8, 12, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 0, 0, 0, 0, 0, 0, 0, 4, 5, 0, 0, 0, 0, 0, 0, 0, 99, 101, 108, 108, 115, 9, 9, 0, 0,
        0, 0, 0, 0, 0, 67, 111, 110, 116, 97, 105, 110, 101, 114, 2, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0,
        0, 0, 0, 0, 0, 112, 97, 100, 100, 105, 110, 103, 9, 10, 0, 0, 0, 0, 0, 0, 0, 69, 100, 103,
        101, 73, 110, 115, 101, 116, 115, 1, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 97, 108,
        108, 2, 8, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105, 108, 100, 15, 12, 0,
        0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 116, 121, 112,
        101, 4, 0, 0, 0, 0, 0, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 116, 101, 120, 116, 9, 4, 0, 0, 0,
        0, 0, 0, 0, 84, 101, 120, 116, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 116, 101,
        120, 116, 12, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 4, 5, 0, 0, 0, 0, 0, 0, 0,
        118, 97, 108, 117, 101, 4, 6, 0, 0, 0, 0, 0, 0, 0, 110, 117, 109, 98, 101, 114, 9, 4, 0,
        0, 0, 0, 0, 0, 0, 84, 101, 120, 116, 2, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 116,
        101, 120, 116, 12, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 4, 5, 0, 0, 0, 0, 0, 0,
        0, 118, 97, 108, 117, 101, 5, 0, 0, 0, 0, 0, 0, 0, 115, 116, 121, 108, 101, 9, 9, 0, 0, 0,
        0, 0, 0, 0, 84, 101, 120, 116, 83, 116, 121, 108, 101, 1, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0,
        0, 0, 0, 0, 99, 111, 108, 111, 114, 15, 12, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
        0, 4, 5, 0, 0, 0, 0, 0, 0, 0, 118, 97, 108, 117, 101, 2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0,
        0, 0, 0, 0, 0, 2, 0, 0, 255, 0, 0, 0, 0, 0, 16, 2, 0, 0, 0, 0, 0, 0, 0, 0, 4, 6, 0, 0, 0,
        0, 0, 0, 0, 97, 99, 116, 105, 111, 110, 9, 6, 0, 0, 0, 0, 0, 0, 0, 66, 117, 116, 116, 111,
        110, 2, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 111, 110, 80, 114, 101, 115, 115,
        101, 100, 14, 10, 0, 0, 0, 0, 0, 0, 0, 99, 101, 108, 108, 65, 99, 116, 105, 111, 110, 3,
        0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 115, 101, 99, 116, 105, 111, 110, 73, 100,
        12, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 4, 2, 0, 0, 0, 0, 0, 0, 0, 105, 100,
        5, 0, 0, 0, 0, 0, 0, 0, 114, 111, 119, 73, 100, 12, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0,
        0, 0, 0, 4, 2, 0, 0, 0, 0, 0, 0, 0, 105, 100, 6, 0, 0, 0, 0, 0, 0, 0, 99, 101, 108, 108,
        73, 100, 12, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 4, 2, 0, 0, 0, 0, 0, 0, 0,
        105, 100, 5, 0, 0, 0, 0, 0, 0, 0, 99, 104, 105, 108, 100, 9, 4, 0, 0, 0, 0, 0, 0, 0, 84,
        101, 120, 116, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 116, 101, 120, 116, 4, 6,
        0, 0, 0, 0, 0, 0, 0, 65, 99, 116, 105, 111, 110, 16, 9, 4, 0, 0, 0, 0, 0, 0, 0, 84, 101,
        120, 116, 1, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 116, 101, 120, 116, 4, 7, 0, 0,
        0, 0, 0, 0, 0, 85, 110, 107, 110, 111, 119, 110>>

    parsed = Text.parse_library_file(template)
    binary = Binary.encode_library_blob(parsed)
    decoded = Binary.decode_library_blob(binary)

    assert binary == expected_binary
    assert decoded == parsed

    widget = hd(decoded.widgets)
    assert widget.name == "dataGrid"

    assert %Model.ConstructorCall{name: "Column"} = widget.root
    children = widget.root.arguments["children"]
    assert length(children) == 2

    [header_row, sections_loop] = children

    assert %Model.ConstructorCall{name: "Row"} = header_row
    header_children = header_row.arguments["children"]
    assert length(header_children) == 2
    [title, stats_builder] = header_children
    assert %Model.ConstructorCall{name: "Text"} = title
    assert %Model.ConstructorCall{name: "Builder"} = stats_builder

    assert %Model.Loop{} = sections_loop
    assert %Model.DataReference{parts: ["sections"]} = sections_loop.input
    assert %Model.ConstructorCall{name: "Column"} = sections_loop.output

    section_children = sections_loop.output.arguments["children"]
    assert length(section_children) == 2
    [section_header, rows_loop] = section_children

    assert %Model.ConstructorCall{name: "Container"} = section_header
    assert section_header.arguments["color"] == 0xFFEEEEEE
    assert %Model.ConstructorCall{name: "Text"} = section_header.arguments["child"]

    assert %Model.Loop{} = rows_loop
    assert %Model.LoopReference{loop: 0, parts: ["rows"]} = rows_loop.input
    assert %Model.ConstructorCall{name: "Builder"} = rows_loop.output

    row_builder = rows_loop.output.arguments["builder"]
    assert %Model.WidgetBuilderDeclaration{} = row_builder
    assert %Model.ConstructorCall{name: "Row"} = row_builder.widget

    cells_loop = hd(row_builder.widget.arguments["children"])
    assert %Model.Loop{} = cells_loop
    assert %Model.LoopReference{loop: 0, parts: ["cells"]} = cells_loop.input
    assert %Model.ConstructorCall{name: "Container"} = cells_loop.output

    cell_switch = cells_loop.output.arguments["child"]
    assert %Model.Switch{} = cell_switch
    assert %Model.LoopReference{loop: 0, parts: ["type"]} = cell_switch.input
    assert length(Map.keys(cell_switch.outputs.map)) == 4
  end
end
