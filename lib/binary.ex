defmodule RfwFormats.Binary do
  @moduledoc """
  Provides functions to encode and decode Remote Flutter Widgets data and library blobs.
  """

  alias RfwFormats.Model

  alias Model.{
    RemoteWidgetLibrary,
    WidgetDeclaration,
    ConstructorCall,
    Import,
    Loop,
    Switch,
    ArgsReference,
    DataReference,
    StateReference,
    LoopReference,
    EventHandler,
    SetStateHandler,
    WidgetBuilderDeclaration,
    WidgetBuilderArgReference
  }

  @data_blob_signature <<0xFE, 0x52, 0x57, 0x44>>
  @library_blob_signature <<0xFE, 0x52, 0x46, 0x57>>

  # Magic signatures (type tags)
  @ms_false 0x00
  @ms_true 0x01
  @ms_int64 0x02
  @ms_binary64 0x03
  @ms_string 0x04
  @ms_list 0x05
  @ms_map 0x07
  @ms_loop 0x08
  @ms_widget 0x09
  @ms_args_reference 0x0A
  @ms_data_reference 0x0B
  @ms_loop_reference 0x0C
  @ms_state_reference 0x0D
  @ms_event 0x0E
  @ms_switch 0x0F
  @ms_default 0x10
  @ms_set_state 0x11
  @ms_widget_builder 0x12
  @ms_widget_builder_arg_reference 0x13

  @int64_size 8
  @float64_size 8

  @doc """
  Encodes a value into a Remote Flutter Widgets binary data blob.

  ## Parameters

  - `value`: The value to encode. Can be various types including structs defined in `RfwFormats.Model`.

  ## Returns

  - A binary representing the encoded data blob.

  ## Examples

      iex> RfwFormats.Binary.encode_data_blob(true)
      <<0xFE, 0x52, 0x57, 0x44, 0x01>>

  """
  @spec encode_data_blob(any()) :: binary()
  def encode_data_blob(value) do
    encoder = [@data_blob_signature]
    encoder = write_value(encoder, value)
    :erlang.iolist_to_binary(encoder)
  end

  @doc """
  Decodes a Remote Flutter Widgets binary data blob into a value.

  ## Parameters

  - `bytes`: The binary data blob to decode.

  ## Returns

  - The decoded value.

  ## Raises

  - RuntimeError: If the blob is invalid or cannot be decoded.
  """
  @spec decode_data_blob(binary()) :: any()
  def decode_data_blob(bytes) do
    with {:ok, decoder} <- init_decoder(bytes),
         {:ok, decoder} <- expect_signature(decoder, @data_blob_signature),
         {:ok, {value, decoder}} <- read_value(decoder) do
      if finished?(decoder) do
        value
      else
        raise "Unexpected trailing bytes after value."
      end
    else
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Encodes a `RemoteWidgetLibrary` into a binary library blob.

  ## Parameters

  - `library`: The `RemoteWidgetLibrary` struct to encode.

  ## Returns

  - A binary representing the encoded library blob.
  """
  @spec encode_library_blob(RemoteWidgetLibrary.t()) :: binary()
  def encode_library_blob(library) do
    encoder = [@library_blob_signature]
    encoder = write_library(encoder, library)
    :erlang.iolist_to_binary(encoder)
  end

  @doc """
  Decodes a Remote Flutter Widgets binary library blob into a `RemoteWidgetLibrary`.

  ## Parameters

  - `bytes`: The binary library blob to decode.

  ## Returns

  - A `RemoteWidgetLibrary` struct.

  ## Raises

  - RuntimeError: If the blob is invalid or cannot be decoded.
  """
  @spec decode_library_blob(binary()) :: RemoteWidgetLibrary.t()
  def decode_library_blob(bytes) do
    with {:ok, decoder} <- init_decoder(bytes),
         {:ok, decoder} <- expect_signature(decoder, @library_blob_signature),
         {:ok, {library, decoder}} <- read_library(decoder) do
      if finished?(decoder) do
        library
      else
        raise "Unexpected trailing bytes after library."
      end
    else
      {:error, reason} -> raise reason
    end
  end

  # Private functions

  defp init_decoder(bytes), do: {:ok, %{bytes: bytes, cursor: 0}}

  defp finished?(%{bytes: bytes, cursor: cursor}), do: byte_size(bytes) <= cursor

  defp expect_signature(decoder, signature) do
    case read_bytes(decoder, byte_size(signature)) do
      {:ok, {^signature, decoder}} ->
        {:ok, decoder}

      {:ok, {other, _}} ->
        {:error,
         "File signature mismatch. Expected #{inspect(signature, base: :hex)}, but found #{inspect(other, base: :hex)}."}

      error ->
        error
    end
  end

  defp write_byte(encoder, byte), do: [encoder, <<byte>>]

  defp write_int64(encoder, value), do: [encoder, <<value::little-signed-integer-size(64)>>]

  defp write_string(encoder, value),
    do: [encoder, <<byte_size(value)::little-unsigned-integer-size(64)>>, value]

  defp write_value(encoder, %RemoteWidgetLibrary{} = library), do: write_library(encoder, library)

  defp write_value(encoder, %WidgetDeclaration{} = widget),
    do: write_widget_declaration(encoder, widget)

  defp write_value(encoder, %ConstructorCall{} = call), do: write_constructor_call(encoder, call)
  defp write_value(encoder, %Import{} = import), do: write_import(encoder, import)
  defp write_value(encoder, %Loop{} = loop), do: write_loop(encoder, loop)
  defp write_value(encoder, %Switch{} = switch), do: write_switch(encoder, switch)
  defp write_value(encoder, %ArgsReference{} = ref), do: write_args_reference(encoder, ref)
  defp write_value(encoder, %DataReference{} = ref), do: write_data_reference(encoder, ref)
  defp write_value(encoder, %StateReference{} = ref), do: write_state_reference(encoder, ref)
  defp write_value(encoder, %LoopReference{} = ref), do: write_loop_reference(encoder, ref)
  defp write_value(encoder, %EventHandler{} = handler), do: write_event_handler(encoder, handler)

  defp write_value(encoder, %SetStateHandler{} = handler),
    do: write_set_state_handler(encoder, handler)

  defp write_value(encoder, %WidgetBuilderDeclaration{} = decl),
    do: write_widget_builder_declaration(encoder, decl)

  defp write_value(encoder, %WidgetBuilderArgReference{} = ref),
    do: write_widget_builder_arg_reference(encoder, ref)

  defp write_value(encoder, true), do: write_byte(encoder, @ms_true)
  defp write_value(encoder, false), do: write_byte(encoder, @ms_false)
  defp write_value(encoder, v) when is_list(v), do: write_list(encoder, v)
  defp write_value(encoder, v) when is_map(v), do: write_map(encoder, v)

  defp write_value(encoder, v) when is_integer(v) do
    [encoder, @ms_int64, <<v::little-signed-integer-size(64)>>]
  end

  defp write_value(encoder, v) when is_float(v) do
    [encoder, @ms_binary64, <<v::little-float-size(64)>>]
  end

  defp write_value(encoder, v) when is_binary(v),
    do: [encoder, [@ms_string | write_string([], v)]]

  defp write_value(_encoder, nil), do: write_map([], %{})

  defp write_value(_encoder, value),
    do: raise(ArgumentError, "Unsupported value type: #{inspect(value)}")

  defp write_list(encoder, list) do
    [encoder, [@ms_list, <<length(list)::little-unsigned-integer-size(64)>>]]
    |> then(fn e -> Enum.reduce(list, e, &write_value(&2, &1)) end)
  end

  defp write_map(encoder, map) do
    [encoder, [@ms_map, <<map_size(map)::little-unsigned-integer-size(64)>>]]
    |> then(fn e ->
      Enum.reduce(map, e, fn {k, v}, acc ->
        acc
        |> write_string(to_string(k))
        |> write_value(v)
      end)
    end)
  end

  defp write_widget_builder_arg_reference(encoder, %WidgetBuilderArgReference{
         argument_name: arg_name,
         parts: parts
       }) do
    [encoder, [@ms_widget_builder_arg_reference]]
    |> write_string(arg_name)
    |> write_parts(parts)
  end

  defp write_widget_builder_declaration(encoder, %WidgetBuilderDeclaration{
         argument_name: arg_name,
         widget: widget
       }) do
    [encoder, [@ms_widget_builder]]
    |> write_string(arg_name)
    |> write_value(widget)
  end

  defp write_loop(encoder, %Loop{input: input, output: output}) do
    [encoder, [@ms_loop]]
    |> write_value(input)
    |> write_value(output)
  end

  defp write_loop_reference(encoder, %LoopReference{loop: loop, parts: parts}) do
    [encoder, [@ms_loop_reference]]
    |> write_int64(loop)
    |> write_parts(parts)
  end

  defp write_event_handler(encoder, %EventHandler{event_name: name, event_arguments: args}) do
    [encoder, [@ms_event]]
    |> write_string(name)
    |> write_map(args)
  end

  defp write_set_state_handler(encoder, %SetStateHandler{state_reference: ref, value: value}) do
    [encoder, [@ms_set_state]]
    |> write_value(ref)
    |> write_value(value)
  end

  defp write_constructor_call(encoder, %ConstructorCall{name: name, arguments: arguments}) do
    [encoder, [@ms_widget]]
    |> write_string(name)
    |> write_int64(map_size(arguments))
    |> then(fn e ->
      Enum.reduce(arguments, e, fn {k, v}, acc ->
        acc
        |> write_string(to_string(k))
        |> write_value(v)
      end)
    end)
  end

  defp write_switch(encoder, %Switch{input: input, outputs: outputs}) do
    [encoder, [@ms_switch]]
    |> write_value(input)
    |> write_switch_outputs(outputs)
  end

  defp write_args_reference(encoder, %ArgsReference{parts: parts}) do
    [encoder, [@ms_args_reference]]
    |> write_parts(parts)
  end

  defp write_data_reference(encoder, %DataReference{parts: parts}) do
    [encoder, [@ms_data_reference]]
    |> write_parts(parts)
  end

  defp write_state_reference(encoder, %StateReference{parts: parts}) do
    [encoder, [@ms_state_reference]]
    |> write_parts(parts)
  end

  defp write_parts(encoder, parts) do
    [encoder, <<length(parts)::little-unsigned-integer-size(64)>>]
    |> then(fn e ->
      Enum.reduce(parts, e, fn part, acc ->
        case part do
          part when is_binary(part) or is_integer(part) ->
            write_value(acc, part)

          _ ->
            raise ArgumentError, "Unexpected type #{inspect(part)} while encoding blob."
        end
      end)
    end)
  end

  defp write_switch_outputs(encoder, outputs) do
    encoder = write_int64(encoder, map_size(outputs))

    Enum.reduce(outputs, encoder, fn
      {nil, v}, acc ->
        acc
        |> write_byte(@ms_default)
        |> write_value(v)

      {k, v}, acc ->
        acc
        |> write_value(k)
        |> write_value(v)
    end)
  end

  defp write_library(encoder, %RemoteWidgetLibrary{imports: imports, widgets: widgets}) do
    encoder
    |> write_int64(length(imports))
    |> then(fn e -> Enum.reduce(imports, e, &write_import(&2, &1)) end)
    |> write_int64(length(widgets))
    |> then(fn e -> Enum.reduce(widgets, e, &write_widget_declaration(&2, &1)) end)
  end

  defp write_widget_declaration(encoder, %WidgetDeclaration{
         name: name,
         initial_state: initial_state,
         root: root
       }) do
    encoder
    |> write_string(name)
    |> write_initial_state(initial_state)
    |> write_value(root)
  end

  defp write_initial_state(encoder, nil) do
    write_int64(encoder, 0)
  end

  defp write_initial_state(encoder, initial_state) when is_map(initial_state) do
    encoder = write_int64(encoder, map_size(initial_state))

    Enum.reduce(initial_state, encoder, fn {k, v}, acc ->
      acc
      |> write_string(to_string(k))
      |> write_value(v)
    end)
  end

  defp write_import(encoder, %Import{name: %Model.LibraryName{parts: parts}}) do
    encoder
    |> write_int64(length(parts))
    |> then(fn e -> Enum.reduce(parts, e, &write_string(&2, &1)) end)
  end

  defp read_byte(decoder) do
    case read_bytes(decoder, 1) do
      {:ok, {<<byte>>, decoder}} -> {:ok, {byte, decoder}}
      error -> error
    end
  end

  defp read_int64(decoder) do
    case read_bytes(decoder, @int64_size) do
      {:ok, {<<value::little-signed-integer-size(64)>>, decoder}} -> {:ok, {value, decoder}}
      error -> error
    end
  end

  defp read_float64(decoder) do
    case read_bytes(decoder, @float64_size) do
      {:ok, {<<value::little-float-size(64)>>, decoder}} -> {:ok, {value, decoder}}
      error -> error
    end
  end

  defp read_string(decoder) do
    with {:ok, {length, decoder}} <- read_int64(decoder),
         {:ok, {bytes, decoder}} <- read_bytes(decoder, length) do
      {:ok, {bytes, decoder}}
    end
  end

  defp read_value(decoder) do
    with {:ok, {type, decoder}} <- read_byte(decoder) do
      case type do
        @ms_false ->
          {:ok, {false, decoder}}

        @ms_true ->
          {:ok, {true, decoder}}

        @ms_int64 ->
          read_int64(decoder)

        @ms_binary64 ->
          read_float64(decoder)

        @ms_string ->
          read_string(decoder)

        @ms_list ->
          read_list(decoder)

        @ms_map ->
          read_map(decoder)

        @ms_loop ->
          read_loop(decoder)

        @ms_widget ->
          read_constructor_call(decoder)

        @ms_args_reference ->
          read_args_reference(decoder)

        @ms_data_reference ->
          read_data_reference(decoder)

        @ms_loop_reference ->
          read_loop_reference(decoder)

        @ms_state_reference ->
          read_state_reference(decoder)

        @ms_event ->
          read_event_handler(decoder)

        @ms_switch ->
          read_switch(decoder)

        @ms_set_state ->
          read_set_state_handler(decoder)

        @ms_widget_builder ->
          read_widget_builder_declaration(decoder)

        @ms_widget_builder_arg_reference ->
          read_widget_builder_arg_reference(decoder)

        _ ->
          {:error, "Unrecognized data type 0x#{Integer.to_string(type, 16)} while decoding blob."}
      end
    end
  end

  defp read_list(decoder) do
    with {:ok, {length, decoder}} <- read_int64(decoder) do
      read_n_values(decoder, length, [])
    end
  end

  defp read_n_values(decoder, 0, acc), do: {:ok, {Enum.reverse(acc), decoder}}

  defp read_n_values(decoder, n, acc) when n > 0 do
    with {:ok, {value, decoder}} <- read_value(decoder) do
      read_n_values(decoder, n - 1, [value | acc])
    end
  end

  defp read_map(decoder) do
    with {:ok, {length, decoder1}} <- read_int64(decoder) do
      read_n_pairs(decoder1, length, [])
    end
  end

  defp read_n_pairs(decoder, 0, acc), do: {:ok, {Enum.into(acc, %{}), decoder}}

  defp read_n_pairs(decoder, n, acc) when n > 0 do
    with {:ok, {key, decoder1}} <- read_string(decoder),
         {:ok, {value, decoder2}} <- read_value(decoder1) do
      read_n_pairs(decoder2, n - 1, [{key, value} | acc])
    end
  end

  defp read_loop(decoder) do
    with {:ok, {input, decoder}} <- read_value(decoder),
         {:ok, {output, decoder}} <- read_value(decoder) do
      {:ok, {%Loop{input: input, output: output}, decoder}}
    end
  end

  defp read_constructor_call(decoder) do
    with {:ok, {name, decoder}} <- read_string(decoder),
         {:ok, {arguments, decoder}} <- read_constructor_arguments(decoder) do
      {:ok, {%ConstructorCall{name: name, arguments: arguments}, decoder}}
    end
  end

  defp read_constructor_arguments(decoder) do
    with {:ok, {length, decoder}} <- read_int64(decoder) do
      read_n_constructor_arguments(decoder, length, [])
    end
  end

  defp read_n_constructor_arguments(decoder, 0, acc), do: {:ok, {Enum.into(acc, %{}), decoder}}

  defp read_n_constructor_arguments(decoder, n, acc) when n > 0 do
    with {:ok, {key, decoder}} <- read_string(decoder),
         {:ok, {value, decoder}} <- read_value(decoder) do
      read_n_constructor_arguments(decoder, n - 1, [{key, value} | acc])
    end
  end

  defp read_reference(decoder) do
    with {:ok, {parts, decoder}} <- read_list(decoder) do
      {:ok, {parts, decoder}}
    end
  end

  defp read_args_reference(decoder) do
    with {:ok, {parts, decoder}} <- read_reference(decoder) do
      {:ok, {%ArgsReference{parts: parts}, decoder}}
    end
  end

  defp read_data_reference(decoder) do
    with {:ok, {parts, decoder}} <- read_reference(decoder) do
      {:ok, {%DataReference{parts: parts}, decoder}}
    end
  end

  defp read_loop_reference(decoder) do
    with {:ok, {loop, decoder}} <- read_int64(decoder),
         {:ok, {parts, decoder}} <- read_reference(decoder) do
      {:ok, {%LoopReference{loop: loop, parts: parts}, decoder}}
    end
  end

  defp read_state_reference(decoder) do
    with {:ok, {parts, decoder}} <- read_reference(decoder) do
      {:ok, {%StateReference{parts: parts}, decoder}}
    end
  end

  defp read_event_handler(decoder) do
    with {:ok, {name, decoder}} <- read_string(decoder),
         {:ok, {arguments, decoder}} <- read_value(decoder) do
      {:ok, {%EventHandler{event_name: name, event_arguments: arguments}, decoder}}
    end
  end

  defp read_switch(decoder) do
    with {:ok, {input, decoder1}} <- read_value(decoder),
         {:ok, {outputs, decoder2}} <- read_switch_outputs(decoder1) do
      {:ok, {%Switch{input: input, outputs: outputs}, decoder2}}
    end
  end

  defp read_switch_outputs(decoder) do
    with {:ok, {length, decoder}} <- read_int64(decoder) do
      read_n_switch_cases(decoder, length, [])
    end
  end

  defp read_n_switch_cases(decoder, 0, acc), do: {:ok, {Enum.into(acc, %{}), decoder}}

  defp read_n_switch_cases(decoder, n, acc) when n > 0 do
    with {:ok, {key, decoder}} <- read_switch_key(decoder),
         {:ok, {value, decoder}} <- read_value(decoder) do
      read_n_switch_cases(decoder, n - 1, [{key, value} | acc])
    end
  end

  defp read_switch_key(decoder) do
    with {:ok, {type, decoder}} <- read_byte(decoder) do
      case type do
        @ms_default ->
          {:ok, {nil, decoder}}

        _ ->
          decoder = %{decoder | cursor: decoder.cursor - 1}
          read_value(decoder)
      end
    end
  end

  defp read_set_state_handler(decoder) do
    with {:ok, {state_reference, decoder1}} <- read_value(decoder),
         {:ok, {value, decoder2}} <- read_value(decoder1) do
      {:ok,
       {%SetStateHandler{
          state_reference: state_reference,
          value: value
        }, decoder2}}
    end
  end

  defp read_widget_builder_declaration(decoder) do
    with {:ok, {arg_name, decoder1}} <- read_string(decoder),
         {:ok, {type, decoder2}} <- read_byte(decoder1) do
      case type do
        @ms_widget ->
          with {:ok, {widget, decoder3}} <- read_constructor_call(decoder2) do
            {:ok, {%WidgetBuilderDeclaration{argument_name: arg_name, widget: widget}, decoder3}}
          end

        @ms_switch ->
          with {:ok, {widget, decoder3}} <- read_switch(decoder2) do
            {:ok, {%WidgetBuilderDeclaration{argument_name: arg_name, widget: widget}, decoder3}}
          end

        _ ->
          raise RuntimeError,
                "Unrecognized data type 0x#{Integer.to_string(type, 16) |> String.pad_leading(2, "0")} while decoding widget builder blob."
      end
    end
  end

  defp read_widget_builder_arg_reference(decoder) do
    with {:ok, {arg_name, decoder}} <- read_string(decoder),
         {:ok, {parts, decoder}} <- read_reference(decoder) do
      {:ok, {%WidgetBuilderArgReference{argument_name: arg_name, parts: parts}, decoder}}
    end
  end

  defp read_library(decoder) do
    with {:ok, {imports, decoder}} <- read_import_list(decoder),
         {:ok, {widgets, decoder}} <- read_declaration_list(decoder) do
      library = %RemoteWidgetLibrary{imports: imports, widgets: widgets}
      {:ok, {library, decoder}}
    end
  end

  defp read_import_list(decoder) do
    with {:ok, {length, decoder}} <- read_int64(decoder) do
      read_n_imports(decoder, length, [])
    end
  end

  defp read_n_imports(decoder, n, acc) do
    if n == 0 do
      {:ok, {Enum.reverse(acc), decoder}}
    else
      with {:ok, {import, decoder}} <- read_import(decoder) do
        read_n_imports(decoder, n - 1, [import | acc])
      end
    end
  end

  defp read_import(decoder) do
    with {:ok, {_parts, decoder}} <- read_int64(decoder),
         {:ok, {name, decoder}} <- read_string(decoder) do
      {:ok, {%Import{name: %Model.LibraryName{parts: [name]}}, decoder}}
    end
  end

  defp read_declaration(decoder) do
    with {:ok, {name, decoder1}} <- read_string(decoder),
         {:ok, {initial_state, decoder2}} <- read_optional_map(decoder1),
         {:ok, {root, decoder3}} <- read_value(decoder2) do
      {:ok, {%WidgetDeclaration{name: name, initial_state: initial_state, root: root}, decoder3}}
    end
  end

  defp read_optional_map(decoder) do
    with {:ok, {length, decoder}} <- read_int64(decoder) do
      if length == 0 do
        {:ok, {nil, decoder}}
      else
        read_n_pairs(decoder, length, [])
      end
    end
  end

  defp read_declaration_list(decoder) do
    with {:ok, {length, decoder}} <- read_int64(decoder) do
      read_n_declarations(decoder, length, [])
    end
  end

  defp read_n_declarations(decoder, n, acc) do
    if n == 0 do
      {:ok, {Enum.reverse(acc), decoder}}
    else
      with {:ok, {declaration, decoder}} <- read_declaration(decoder) do
        read_n_declarations(decoder, n - 1, [declaration | acc])
      end
    end
  end

  defp read_bytes(%{bytes: bytes, cursor: cursor} = decoder, length) do
    if cursor + length > byte_size(bytes) do
      {:error, "Could not read #{length} bytes at offset #{cursor}: unexpected end of file."}
    else
      data = binary_part(bytes, cursor, length)
      {:ok, {data, %{decoder | cursor: cursor + length}}}
    end
  end
end
