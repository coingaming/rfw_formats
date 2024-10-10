defmodule RfwFormats.BinaryTest do
  require Logger

  use ExUnit.Case

  alias RfwFormats.Binary
  alias RfwFormats.Model

  # This is a number that requires more than 32 bits but less than 53 bits,
  # so that it works in a JS Number and tests the logic that parses 64-bit ints as
  # two separate 32-bit ints.
  @large_number 9_007_199_254_730_661

  test "String example" do
    Logger.debug("Starting String example test")
    bytes = Binary.encode_data_blob("Hello")
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x57, 0x44 - Data blob signature
    # 0x04 - String tag
    # 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - String length (5) as 64-bit little-endian integer
    # 0x48, 0x65, 0x6C, 0x6C, 0x6F - UTF-8 encoded "Hello"
    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x48,
               0x65, 0x6C, 0x6C, 0x6F>>

    value = Binary.decode_data_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert is_binary(value)
    assert value == "Hello"
  end

  test "Bools" do
    Logger.debug("Starting Bools test")
    bytes = Binary.encode_data_blob([false, true])
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x57, 0x44 - Data blob signature
    # 0x05 - List tag
    # 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - List length (2)
    # 0x00 - Boolean false
    # 0x01 - Boolean true
    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x05, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
               0x01>>

    value = Binary.decode_data_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert is_list(value)
    assert value == [false, true]
  end

  test "Big integer example" do
    Logger.debug("Starting Big integer example test")
    bytes = Binary.encode_data_blob(@large_number)
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x57, 0x44 - Data blob signature
    # 0x02 - Integer tag
    # 0xA5, 0xD7, 0xFF, 0xFF, 0xFF, 0xFF, 0x1F, 0x00 - 64-bit little-endian integer representation of @large_number
    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x02, 0xA5, 0xD7, 0xFF, 0xFF, 0xFF, 0xFF, 0x1F, 0x00>>

    value = Binary.decode_data_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert is_integer(value)
    assert value == @large_number
  end

  test "Big negative integer example" do
    Logger.debug("Starting Big negative integer example test")
    bytes = Binary.encode_data_blob(-@large_number)
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x57, 0x44 - Data blob signature
    # 0x02 - Integer tag
    # 0x5B, 0x28, 0x00, 0x00, 0x00, 0x00, 0xE0, 0xFF - 64-bit little-endian integer representation of -@large_number
    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x02, 0x5B, 0x28, 0x00, 0x00, 0x00, 0x00, 0xE0, 0xFF>>

    value = Binary.decode_data_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert is_integer(value)
    assert value == -@large_number
  end

  test "Small integer example" do
    Logger.debug("Starting Small integer example test")
    bytes = Binary.encode_data_blob(1)
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x57, 0x44 - Data blob signature
    # 0x02 - Integer tag
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - 64-bit little-endian integer representation of 1
    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x02, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>

    value = Binary.decode_data_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert is_integer(value)
    assert value == 1
  end

  test "Small negative integer example" do
    Logger.debug("Starting Small negative integer example test")
    bytes = Binary.encode_data_blob(-1)
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x57, 0x44 - Data blob signature
    # 0x02 - Integer tag
    # 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF - 64-bit little-endian integer representation of -1
    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x02, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>

    value = Binary.decode_data_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert is_integer(value)
    assert value == -1
  end

  test "Zero integer example" do
    Logger.debug("Starting Zero integer example test")
    bytes = Binary.encode_data_blob(0)
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x57, 0x44 - Data blob signature
    # 0x02 - Integer tag
    # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - 64-bit little-endian integer representation of 0
    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>

    value = Binary.decode_data_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert is_integer(value)
    assert value == 0
  end

  test "Doubles" do
    Logger.debug("Starting Doubles test")
    bytes = Binary.encode_data_blob(0.25)
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x57, 0x44 - Data blob signature
    # 0x03 - Double tag
    # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xD0, 0x3F - 64-bit little-endian IEEE 754 representation of 0.25
    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xD0, 0x3F>>

    value = Binary.decode_data_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert is_float(value)
    assert value == 0.25
  end

  test "Specific double value" do
    Logger.debug("Starting Specific double value test")
    bytes = Binary.encode_data_blob(0.25)
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")
    value = Binary.decode_data_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert value == 0.25
  end

  test "Map example" do
    Logger.debug("Starting Map example test")
    bytes = Binary.encode_data_blob(%{"a" => 15})
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x57, 0x44 - Data blob signature
    # 0x07 - Map tag
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Map length (1) as 64-bit little-endian integer
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - String length (1) for key "a"
    # 0x61 - UTF-8 encoded "a"
    # 0x02 - Integer tag for value
    # 0x0F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - 64-bit little-endian integer representation of 15
    assert bytes ==
             <<0xFE, 0x52, 0x57, 0x44, 0x07, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
               0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x02, 0x0F, 0x00, 0x00, 0x00, 0x00,
               0x00, 0x00, 0x00>>

    value = Binary.decode_data_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert is_map(value)
    assert value == %{"a" => 15}
  end

  test "Signature check in decoders" do
    Logger.debug("Starting Signature check in decoders test")

    assert_raise RuntimeError,
                 "File signature mismatch. Expected <<0xFE, 0x52, 0x57, 0x44>>, but found <<0xFE, 0x52, 0x46, 0x57>>.",
                 fn ->
                   Binary.decode_data_blob(
                     <<0xFE, 0x52, 0x46, 0x57, 0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                       0x00, 0x48, 0x65, 0x6C, 0x6C, 0x6F>>
                   )
                 end

    assert_raise RuntimeError,
                 "File signature mismatch. Expected <<0xFE, 0x52, 0x46, 0x57>>, but found <<0xFE, 0x52, 0x57, 0x44>>.",
                 fn ->
                   Binary.decode_library_blob(
                     <<0xFE, 0x52, 0x57, 0x44, 0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                       0x00, 0x48, 0x65, 0x6C, 0x6C, 0x6F>>
                   )
                 end
  end

  test "Trailing byte check" do
    Logger.debug("Starting Trailing byte check test")

    assert_raise RuntimeError, "Unexpected trailing bytes after value.", fn ->
      Binary.decode_data_blob(<<0xFE, 0x52, 0x57, 0x44, 0x00, 0x00>>)
    end

    assert_raise RuntimeError, "Unexpected trailing bytes after library.", fn ->
      Binary.decode_library_blob(
        <<0xFE, 0x52, 0x46, 0x57, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>
      )
    end
  end

  test "Incomplete files in signatures" do
    Logger.debug("Starting Incomplete files in signatures test")

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
    Logger.debug("Starting Incomplete files after signatures test")

    assert_raise RuntimeError,
                 "Could not read 1 bytes at offset 4: unexpected end of file.",
                 fn ->
                   Binary.decode_data_blob(<<0xFE, 0x52, 0x57, 0x44>>)
                 end

    assert_raise RuntimeError,
                 "Could not read 8 bytes at offset 4: unexpected end of file.",
                 fn ->
                   Binary.decode_library_blob(<<0xFE, 0x52, 0x46, 0x57>>)
                 end
  end

  test "Invalid value tag" do
    Logger.debug("Starting Invalid value tag test")
    # Test that the decoder detects an invalid value tag (0xCC is not a valid tag)
    assert_raise RuntimeError, "Unrecognized data type 0xCC while decoding blob.", fn ->
      Binary.decode_data_blob(<<0xFE, 0x52, 0x57, 0x44, 0xCC>>)
    end
  end

  test "Library encoder smoke test" do
    Logger.debug("Starting Library encoder smoke test")
    bytes = Binary.encode_library_blob(%Model.RemoteWidgetLibrary{imports: [], widgets: []})
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x46, 0x57 - Library blob signature
    # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of imports (0) as 64-bit little-endian integer
    # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of widgets (0) as 64-bit little-endian integer
    assert bytes ==
             <<0xFE, 0x52, 0x46, 0x57, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
               0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>

    value = Binary.decode_library_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert Enum.empty?(value.imports)
    assert Enum.empty?(value.widgets)
  end

  @tag :verbose
  test "Library encoder: imports" do
    Logger.debug("Starting Library encoder: imports test")

    library = %Model.RemoteWidgetLibrary{
      imports: [%Model.Import{name: %Model.LibraryName{parts: ["a"]}}],
      widgets: []
    }

    bytes = Binary.encode_library_blob(library)
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x46, 0x57 - Library blob signature
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of imports (1) as 64-bit little-endian integer
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of parts in the library name (1) as 64-bit little-endian integer
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Length of the part name (1) as 64-bit little-endian integer
    # 0x61 - UTF-8 encoded "a"
    # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of widgets (0) as 64-bit little-endian integer
    assert bytes ==
             <<0xFE, 0x52, 0x46, 0x57, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00,
               0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
               0x61, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>

    value = Binary.decode_library_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert length(value.imports) == 1
    assert hd(value.imports).name == %Model.LibraryName{parts: ["a"]}
    assert Enum.empty?(value.widgets)
  end

  test "Library decoder: invalid widget declaration root" do
    Logger.debug("Starting Library decoder: invalid widget declaration root test")
    # Bytes explanation:
    # 0xFE, 0x52, 0x46, 0x57 - Library blob signature
    # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of imports (0)
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of widgets (1)
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Length of widget name (1)
    # 0x61 - UTF-8 encoded "a" (widget name)
    # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Empty initial state
    # 0xEF - Invalid tag for widget root (should be 0x09 for ConstructorCall or 0x0F for Switch)
    bytes =
      <<0xFE, 0x52, 0x46, 0x57, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xEF>>

    assert_raise RuntimeError,
                 "Unrecognized data type 0xEF while decoding blob.",
                 fn ->
                   Binary.decode_library_blob(bytes)
                 end
  end

  test "Library encoder: args references" do
    Logger.debug("Starting Library encoder: args references test")

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
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x46, 0x57 - Library blob signature
    # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of imports (0)
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of widgets (1)
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Length of widget name (1)
    # 0x61 - UTF-8 encoded "a" (widget name)
    # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Empty initial state
    # 0x09 - ConstructorCall tag
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Length of constructor name (1)
    # 0x62 - UTF-8 encoded "b" (constructor name)
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of constructor arguments (1)
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Length of argument name (1)
    # 0x63 - UTF-8 encoded "c" (argument name)
    # 0x05 - List tag
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - List length (1)
    # 0x0A - ArgsReference tag
    # 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of parts in ArgsReference (2)
    # 0x04 - String tag
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Length of string (1)
    # 0x64 - UTF-8 encoded "d"
    # 0x02 - Integer tag
    # 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Integer value (5)
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
    Logger.debug("Decoded value: #{inspect(value)}")
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
    Logger.debug("Starting Library encoder: invalid args references test")

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

    assert_raise ArgumentError, "Unexpected type false while encoding blob.", fn ->
      Binary.encode_library_blob(library)
    end
  end

  test "Library decoder: invalid args references" do
    Logger.debug("Starting Library decoder: invalid args references test")
    # Bytes explanation: Same as previous test, except:
    # 0xAC - Invalid tag for ArgsReference part (should be 0x04 for String or 0x02 for Integer)
    bytes =
      <<0xFE, 0x52, 0x46, 0x57, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x62, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x63, 0x05, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0A, 0x01,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xAC>>

    assert_raise RuntimeError, "Unrecognized data type 0xAC while decoding blob.", fn ->
      Binary.decode_library_blob(bytes)
    end
  end

  test "Library encoder: switches with non-null key" do
    Logger.debug("Starting Library encoder: switches with non-null key test")

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
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")

    # Bytes explanation:
    # 0xFE, 0x52, 0x46, 0x57 - Library blob signature
    # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of imports (0)
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of widgets (1)
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Length of widget name (1)
    # 0x61 - UTF-8 encoded "a" (widget name)
    # 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Empty initial state
    # 0x0F - Switch tag
    # 0x04 - String tag (for input)
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Length of input string (1)
    # 0x62 - UTF-8 encoded "b" (input)
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Number of switch cases (1)
    # 0x04 - String tag (for case key)
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Length of case key string (1)
    # 0x63 - UTF-8 encoded "c" (case key)
    # 0x04 - String tag (for case value)
    # 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 - Length of case value string (1)
    # 0x64 - UTF-8 encoded "d" (case value)
    expected_bytes =
      <<0xFE, 0x52, 0x46, 0x57, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x61, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x62, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x63, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x64>>

    assert bytes == expected_bytes

    value = Binary.decode_library_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
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

  test "Library encoder: loops" do
    Logger.debug("Starting Library encoder: loops test")

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
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")
    value = Binary.decode_library_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert value == library
  end

  test "Library encoder: data references" do
    Logger.debug("Starting Library encoder: data references test")

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
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")
    value = Binary.decode_library_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert value == library
  end

  test "Library encoder: state references" do
    Logger.debug("Starting Library encoder: state references test")

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
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")
    value = Binary.decode_library_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert value == library
  end

  test "Library encoder: event handler" do
    Logger.debug("Starting Library encoder: event handler test")

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
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")
    value = Binary.decode_library_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert value == library
  end

  test "Library encoder: state setter" do
    Logger.debug("Starting Library encoder: state setter test")

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
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")
    value = Binary.decode_library_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert value == library
  end

  test "Library encoder: initial state" do
    Logger.debug("Starting Library encoder: initial state test")

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
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")
    value = Binary.decode_library_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert value == library
  end

  test "Library encoder: widget builders work" do
    Logger.debug("Starting Library encoder: widget builders work test")

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
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")
    value = Binary.decode_library_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert value == library
  end

  test "Library encoder: widget builders throw on invalid widget" do
    Logger.debug("Starting Library encoder: widget builders throw on invalid widget test")

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
    Logger.debug("Starting Library encoder: switch with empty outputs test")

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
    Logger.debug("Encoded bytes: #{inspect(bytes, limit: :infinity)}")
    value = Binary.decode_library_blob(bytes)
    Logger.debug("Decoded value: #{inspect(value)}")
    assert value == library
  end

  test "Signature mismatch in decoders" do
    Logger.debug("Starting Signature mismatch in decoders test")

    assert_raise RuntimeError,
                 "File signature mismatch. Expected <<0xFE, 0x52, 0x57, 0x44>>, but found <<0xFE, 0x52, 0x46, 0x57>>.",
                 fn ->
                   Binary.decode_data_blob(
                     <<0xFE, 0x52, 0x46, 0x57, 0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                       0x00, 0x48, 0x65, 0x6C, 0x6C, 0x6F>>
                   )
                 end

    assert_raise RuntimeError,
                 "File signature mismatch. Expected <<0xFE, 0x52, 0x46, 0x57>>, but found <<0xFE, 0x52, 0x57, 0x44>>.",
                 fn ->
                   Binary.decode_library_blob(
                     <<0xFE, 0x52, 0x57, 0x44, 0x04, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                       0x00, 0x48, 0x65, 0x6C, 0x6C, 0x6F>>
                   )
                 end
  end
end
