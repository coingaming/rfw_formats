defmodule RfwFormats.BinaryTest do
  use ExUnit.Case
  alias RfwFormats.Binary
  alias RfwFormats.Model

  # This is a number that requires more than 32 bits but less than 53 bits,
  # so that it works in a JS Number and tests the logic that parses 64-bit ints as
  # two separate 32-bit ints.
  @large_number 9_007_199_254_730_661

  test "String example" do
    bytes = Binary.encode_data_blob("Hello")

    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x48,
               0x65, 0x6C, 0x6C, 0x6F>>

    value = Binary.decode_data_blob(bytes)
    assert is_binary(value)
    assert value == "Hello"
  end

  test "Big integer example" do
    bytes = Binary.encode_data_blob(@large_number)

    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x02, 0xA5, 0xD7, 0xFF, 0xFF, 0xFF, 0xFF, 0x1F, 0x00>>

    value = Binary.decode_data_blob(bytes)
    assert is_integer(value)
    assert value == @large_number
  end

  test "Big negative integer example" do
    bytes = Binary.encode_data_blob(-@large_number)

    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x02, 0x5B, 0x28, 0x00, 0x00, 0x00, 0x00, 0xE0, 0xFF>>

    value = Binary.decode_data_blob(bytes)
    assert is_integer(value)
    assert value == -@large_number
  end

  test "Small integer example" do
    bytes = Binary.encode_data_blob(1)

    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x02, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>

    value = Binary.decode_data_blob(bytes)
    assert is_integer(value)
    assert value == 1
  end

  test "Small negative integer example" do
    bytes = Binary.encode_data_blob(-1)

    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x02, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>

    value = Binary.decode_data_blob(bytes)
    assert is_integer(value)
    assert value == -1
  end

  test "Zero integer example" do
    bytes = Binary.encode_data_blob(0)

    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>

    value = Binary.decode_data_blob(bytes)
    assert is_integer(value)
    assert value == 0
  end

  test "Map example" do
    bytes = Binary.encode_data_blob(%{"a" => 15})

    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x07, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
               0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x02, 0x0F, 0x00, 0x00, 0x00, 0x00,
               0x00, 0x00, 0x00>>

    value = Binary.decode_data_blob(bytes)
    assert is_map(value)
    assert value == %{"a" => 15}
  end

  test "Signature check in decoders" do
    assert_raise RuntimeError,
                 "File signature mismatch. Expected FE 52 57 44, but found FE 52 46 57.",
                 fn ->
                   Binary.decode_data_blob(
                     <<0xFE, 0x52, 0x46, 0x57, 0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                       0x00, 0x48, 0x65, 0x6C, 0x6C, 0x6F>>
                   )
                 end

    assert_raise RuntimeError,
                 "File signature mismatch. Expected FE 52 46 57, but found FE 52 57 44.",
                 fn ->
                   Binary.decode_library_blob(
                     <<0xFE, 0x52, 0x57, 0x44, 0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                       0x00, 0x48, 0x65, 0x6C, 0x6C, 0x6F>>
                   )
                 end
  end

  test "Trailing byte check" do
    assert_raise RuntimeError, "Unexpected trailing bytes after value.", fn ->
      Binary.decode_data_blob(<<0xFE, 0x52, 0x57, 0x44, 0x00, 0x00>>)
    end

    assert_raise RuntimeError, "Unexpected trailing bytes after constructors.", fn ->
      Binary.decode_library_blob(
        <<0xFE, 0x52, 0x46, 0x57, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>
      )
    end
  end

  test "Incomplete files in signatures" do
    assert_raise RuntimeError,
                 "Could not read 4 bytes at offset 0: unexpected end of file.",
                 fn ->
                   Binary.decode_data_blob(<<0xFE, 0x52, 0x57>>)
                 end

    assert_raise RuntimeError,
                 "Could not read 4 bytes at offset 0: unexpected end of file.",
                 fn ->
                   Binary.decode_library_blob(<<0xFE, 0x52, 0x46>>)
                 end
  end

  test "Incomplete files after signatures" do
    assert_raise RuntimeError,
                 "Could not read byte at offset 4: unexpected end of file.",
                 fn ->
                   Binary.decode_data_blob(<<0xFE, 0x52, 0x57, 0x44>>)
                 end

    assert_raise RuntimeError,
                 "Could not read int64 at offset 4: unexpected end of file.",
                 fn ->
                   Binary.decode_library_blob(<<0xFE, 0x52, 0x46, 0x57>>)
                 end
  end

  test "Invalid value tag" do
    assert_raise RuntimeError, "Unrecognized data type 0xCC while decoding blob.", fn ->
      Binary.decode_data_blob(<<0xFE, 0x52, 0x57, 0x44, 0xCC>>)
    end
  end

  test "Library encoder smoke test" do
    bytes = Binary.encode_library_blob(%Model.RemoteWidgetLibrary{imports: [], widgets: []})

    assert bytes ==
             <<0xFE, 0x52, 0x46, 0x57, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
               0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>

    value = Binary.decode_library_blob(bytes)
    assert Enum.empty?(value.imports)
    assert Enum.empty?(value.widgets)
  end

  test "Library encoder: imports" do
    library = %Model.RemoteWidgetLibrary{
      imports: [%Model.Import{name: %Model.LibraryName{parts: ["a"]}}],
      widgets: []
    }

    bytes = Binary.encode_library_blob(library)

    assert bytes ==
             <<0xFE, 0x52, 0x46, 0x57, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00,
               0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
               0x61, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>

    value = Binary.decode_library_blob(bytes)
    assert length(value.imports) == 1
    assert hd(value.imports).name == %Model.LibraryName{parts: ["a"]}
    assert Enum.empty?(value.widgets)
  end

  test "Doubles" do
    bytes = Binary.encode_data_blob(0.25)

    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xD0, 0x3F>>

    value = Binary.decode_data_blob(bytes)
    assert is_float(value)
    assert value == 0.25
  end

  test "Library decoder: invalid widget declaration root" do
    bytes =
      <<0xFE, 0x52, 0x46, 0x57, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEF>>

    assert_raise RuntimeError,
                 "Unrecognized data type 0xEF while decoding widget declaration root.",
                 fn ->
                   Binary.decode_library_blob(bytes)
                 end
  end

  test "Library encoder: args references" do
    library = %Model.RemoteWidgetLibrary{
      imports: [],
      widgets: [
        %Model.WidgetDeclaration{
          name: "a",
          initial_state: nil,
          root: %Model.ConstructorCall{
            name: "b",
            arguments: %{
              "c" => [
                %Model.ArgsReference{parts: ["d", 5]}
              ]
            }
          }
        }
      ]
    }

    bytes = Binary.encode_library_blob(library)

    expected_bytes =
      <<0xFE, 0x52, 0x46, 0x57, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x62, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x63, 0x05, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0A, 0x02,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x64, 0x02, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>

    assert bytes == expected_bytes

    value = Binary.decode_library_blob(bytes)
    assert Enum.empty?(value.imports)
    assert length(value.widgets) == 1
    widget = hd(value.widgets)
    assert widget.name == "a"
    assert widget.initial_state == nil
    assert %Model.ConstructorCall{} = widget.root
    assert widget.root.name == "b"
    assert map_size(widget.root.arguments) == 1
    assert Map.has_key?(widget.root.arguments, "c")
    assert [args_ref] = widget.root.arguments["c"]
    assert %Model.ArgsReference{} = args_ref
    assert args_ref.parts == ["d", 5]
  end

  test "Library encoder: invalid args references" do
    library = %Model.RemoteWidgetLibrary{
      imports: [],
      widgets: [
        %Model.WidgetDeclaration{
          name: "a",
          initial_state: nil,
          root: %Model.ConstructorCall{
            name: "b",
            arguments: %{
              "c" => [
                %Model.ArgsReference{parts: [false]}
              ]
            }
          }
        }
      ]
    }

    assert_raise ArgumentError, "Unexpected type boolean while encoding blob.", fn ->
      Binary.encode_library_blob(library)
    end
  end

  test "Library decoder: invalid args references" do
    bytes =
      <<0xFE, 0x52, 0x46, 0x57, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x62, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x63, 0x05, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0A, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAC>>

    assert_raise RuntimeError, "Invalid reference type 0xAC while decoding blob.", fn ->
      Binary.decode_library_blob(bytes)
    end
  end

  test "Library encoder: switches with non-null key" do
    library = %Model.RemoteWidgetLibrary{
      imports: [],
      widgets: [
        %Model.WidgetDeclaration{
          name: "a",
          initial_state: nil,
          root: %Model.Switch{input: "b", outputs: %{"c" => "d"}}
        }
      ]
    }

    bytes = Binary.encode_library_blob(library)

    expected_bytes =
      <<0xFE, 0x52, 0x46, 0x57, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x62, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x64>>

    assert bytes == expected_bytes

    value = Binary.decode_library_blob(bytes)
    assert Enum.empty?(value.imports)
    assert length(value.widgets) == 1
    widget = hd(value.widgets)
    assert widget.name == "a"
    assert widget.initial_state == nil
    assert %Model.Switch{} = widget.root
    assert widget.root.input == "b"
    assert map_size(widget.root.outputs) == 1
    assert Map.has_key?(widget.root.outputs, "c")
    assert widget.root.outputs["c"] == "d"
  end

  test "Bools" do
    bytes = Binary.encode_data_blob([false, true])

    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x05, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
               0x01>>

    value = Binary.decode_data_blob(bytes)
    assert is_list(value)
    assert value == [false, true]
  end

  test "Library encoder: loops" do
    library = %Model.RemoteWidgetLibrary{
      imports: [],
      widgets: [
        %Model.WidgetDeclaration{
          name: "a",
          initial_state: nil,
          root: %Model.ConstructorCall{
            name: "b",
            arguments: %{
              "c" => [
                %Model.Loop{
                  input: [],
                  output: %Model.ConstructorCall{
                    name: "d",
                    arguments: %{
                      "e" => %Model.LoopReference{loop: 0, parts: []}
                    }
                  }
                }
              ]
            }
          }
        }
      ]
    }

    bytes = Binary.encode_library_blob(library)
    value = Binary.decode_library_blob(bytes)
    assert value == library
  end

  test "Library encoder: data references" do
    library = %Model.RemoteWidgetLibrary{
      imports: [],
      widgets: [
        %Model.WidgetDeclaration{
          name: "a",
          initial_state: nil,
          root: %Model.ConstructorCall{
            name: "b",
            arguments: %{
              "c" => %Model.DataReference{parts: ["d"]}
            }
          }
        }
      ]
    }

    bytes = Binary.encode_library_blob(library)
    value = Binary.decode_library_blob(bytes)
    assert value == library
  end

  test "Library encoder: state references" do
    library = %Model.RemoteWidgetLibrary{
      imports: [],
      widgets: [
        %Model.WidgetDeclaration{
          name: "a",
          initial_state: nil,
          root: %Model.ConstructorCall{
            name: "b",
            arguments: %{
              "c" => %Model.StateReference{parts: ["d"]}
            }
          }
        }
      ]
    }

    bytes = Binary.encode_library_blob(library)
    value = Binary.decode_library_blob(bytes)
    assert value == library
  end

  test "Library encoder: event handler" do
    library = %Model.RemoteWidgetLibrary{
      imports: [],
      widgets: [
        %Model.WidgetDeclaration{
          name: "a",
          initial_state: nil,
          root: %Model.ConstructorCall{
            name: "b",
            arguments: %{
              "c" => %Model.EventHandler{
                event_name: "d",
                event_arguments: %{}
              }
            }
          }
        }
      ]
    }

    bytes = Binary.encode_library_blob(library)
    value = Binary.decode_library_blob(bytes)
    assert value == library
  end

  test "Library encoder: state setter" do
    library = %Model.RemoteWidgetLibrary{
      imports: [],
      widgets: [
        %Model.WidgetDeclaration{
          name: "a",
          initial_state: nil,
          root: %Model.ConstructorCall{
            name: "b",
            arguments: %{
              "c" => %Model.SetStateHandler{
                state_reference: %Model.StateReference{parts: ["d"]},
                value: false
              }
            }
          }
        }
      ]
    }

    bytes = Binary.encode_library_blob(library)
    value = Binary.decode_library_blob(bytes)
    assert value == library
  end

  test "Library encoder: initial state" do
    library = %Model.RemoteWidgetLibrary{
      imports: [],
      widgets: [
        %Model.WidgetDeclaration{
          name: "a",
          initial_state: %{"b" => false},
          root: %Model.ConstructorCall{
            name: "c",
            arguments: %{}
          }
        }
      ]
    }

    bytes = Binary.encode_library_blob(library)
    value = Binary.decode_library_blob(bytes)
    assert value == library
  end

  test "Library encoder: widget builders work" do
    library = %Model.RemoteWidgetLibrary{
      imports: [],
      widgets: [
        %Model.WidgetDeclaration{
          name: "Foo",
          initial_state: nil,
          root: %Model.ConstructorCall{
            name: "Builder",
            arguments: %{
              "builder" => %Model.WidgetBuilderDeclaration{
                argument_name: "scope",
                widget: %Model.ConstructorCall{
                  name: "Text",
                  arguments: %{
                    "text" => %Model.WidgetBuilderArgReference{
                      argument_name: "scope",
                      parts: ["text"]
                    }
                  }
                }
              }
            }
          }
        }
      ]
    }

    bytes = Binary.encode_library_blob(library)
    value = Binary.decode_library_blob(bytes)
    assert value == library
  end

  test "Library encoder: widget builders throw on invalid widget" do
    library = %Model.RemoteWidgetLibrary{
      imports: [],
      widgets: [
        %Model.WidgetDeclaration{
          name: "a",
          initial_state: %{},
          root: %Model.ConstructorCall{
            name: "c",
            arguments: %{
              "builder" => %Model.WidgetBuilderDeclaration{
                argument_name: "scope",
                widget: %Model.ArgsReference{parts: []}
              }
            }
          }
        }
      ]
    }

    assert_raise RuntimeError,
                 "Unrecognized data type 0x0A while decoding widget builder blob.",
                 fn ->
                   bytes = Binary.encode_library_blob(library)
                   Binary.decode_library_blob(bytes)
                 end
  end

  test "Library encoder: switch with empty outputs" do
    library = %Model.RemoteWidgetLibrary{
      imports: [],
      widgets: [
        %Model.WidgetDeclaration{
          name: "a",
          initial_state: nil,
          root: %Model.ConstructorCall{
            name: "b",
            arguments: %{
              "c" => %Model.Switch{input: false, outputs: %{}}
            }
          }
        }
      ]
    }

    bytes = Binary.encode_library_blob(library)
    value = Binary.decode_library_blob(bytes)
    assert value == library
  end

  test "Specific double value" do
    bytes = Binary.encode_data_blob(0.25)
    value = Binary.decode_data_blob(bytes)
    assert value == 0.25
  end

  test "Signature mismatch in decoders" do
    assert_raise RuntimeError,
                 "File signature mismatch. Expected FE 52 57 44, but found FE 52 46 57.",
                 fn ->
                   Binary.decode_data_blob(
                     <<0xFE, 0x52, 0x46, 0x57, 0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                       0x00, 0x48, 0x65, 0x6C, 0x6C, 0x6F>>
                   )
                 end

    assert_raise RuntimeError,
                 "File signature mismatch. Expected FE 52 46 57, but found FE 52 57 44.",
                 fn ->
                   Binary.decode_library_blob(
                     <<0xFE, 0x52, 0x57, 0x44, 0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                       0x00, 0x48, 0x65, 0x6C, 0x6C, 0x6F>>
                   )
                 end
  end
end
