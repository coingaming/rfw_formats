defmodule RfwFormats.Binary do
  @moduledoc """
  Provides encoding and decoding functionality for Remote Flutter Widgets binary blobs.
  """

  alias RfwFormats.Model
  alias __MODULE__.BlobEncoder
  alias __MODULE__.BlobDecoder

  # Magic signatures
  @data_blob_signature <<0xFE, 0x52, 0x57, 0x44>>
  @library_blob_signature <<0xFE, 0x52, 0x46, 0x57>>

  @doc """
  Encodes data as a Remote Flutter Widgets binary data blob.
  """
  @spec encode_data_blob(any()) :: binary()
  def encode_data_blob(value) do
    encoder = BlobEncoder.new()
    encoder = BlobEncoder.write_signature(encoder, @data_blob_signature)
    {encoder, _} = BlobEncoder.write_value(encoder, value)
    BlobEncoder.to_binary(encoder)
  end

  @doc """
  Decodes a Remote Flutter Widgets binary data blob.
  """
  @spec decode_data_blob(binary()) :: any()
  def decode_data_blob(bytes) do
    decoder = BlobDecoder.new(bytes)
    decoder = BlobDecoder.expect_signature(decoder, @data_blob_signature)
    {decoder, result} = BlobDecoder.read_value(decoder)

    if not BlobDecoder.finished?(decoder) do
      raise "Unexpected trailing bytes after value."
    end

    result
  end

  @doc """
  Encodes data as a Remote Flutter Widgets binary library blob.
  """
  @spec encode_library_blob(Model.RemoteWidgetLibrary.t()) :: binary()
  def encode_library_blob(value) do
    encoder = BlobEncoder.new()
    encoder = BlobEncoder.write_signature(encoder, @library_blob_signature)
    {encoder, _} = BlobEncoder.write_library(encoder, value)
    BlobEncoder.to_binary(encoder)
  end

  @doc """
  Decodes a Remote Flutter Widgets binary library blob.
  """
  @spec decode_library_blob(binary()) :: Model.RemoteWidgetLibrary.t()
  def decode_library_blob(bytes) do
    decoder = BlobDecoder.new(bytes)
    decoder = BlobDecoder.expect_signature(decoder, @library_blob_signature)
    {decoder, result} = BlobDecoder.read_library(decoder)

    if not BlobDecoder.finished?(decoder) do
      raise "Unexpected trailing bytes after library."
    end

    result
  end

  defmodule BlobEncoder do
    @moduledoc false
    defstruct [:bytes]

    # Magic values
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

    def new, do: %__MODULE__{bytes: <<>>}

    def write_signature(encoder, signature) do
      %{encoder | bytes: <<encoder.bytes::binary, signature::binary>>}
    end

    def write_byte(encoder, byte) do
      %{encoder | bytes: <<encoder.bytes::binary, byte::8>>}
    end

    def write_int64(encoder, value) do
      %{encoder | bytes: <<encoder.bytes::binary, value::little-64>>}
    end

    def write_binary64(encoder, value) do
      %{encoder | bytes: <<encoder.bytes::binary, value::little-float-64>>}
    end

    def write_string(encoder, value) do
      encoder = write_int64(encoder, byte_size(value))
      %{encoder | bytes: <<encoder.bytes::binary, value::binary>>}
    end

    def write_value(encoder, value) do
      cond do
        is_boolean(value) ->
          if value, do: write_byte(encoder, @ms_true), else: write_byte(encoder, @ms_false)

        is_integer(value) ->
          encoder = write_byte(encoder, @ms_int64)
          write_int64(encoder, value)

        is_float(value) ->
          encoder = write_byte(encoder, @ms_binary64)
          write_binary64(encoder, value)

        is_binary(value) ->
          encoder = write_byte(encoder, @ms_string)
          write_string(encoder, value)

        is_list(value) ->
          encoder = write_byte(encoder, @ms_list)
          encoder = write_int64(encoder, length(value))
          Enum.reduce(value, {encoder, nil}, fn item, {acc, _} -> write_value(acc, item) end)

        is_map(value) ->
          encoder = write_byte(encoder, @ms_map)
          write_map(encoder, value, &write_value/2)

        true ->
          write_argument(encoder, value)
      end
    end

    def write_argument(encoder, value) do
      cond do
        is_struct(value, Model.Loop) ->
          encoder = write_byte(encoder, @ms_loop)
          {encoder, _} = write_argument(encoder, value.input)
          write_argument(encoder, value.output)

        is_struct(value, Model.ConstructorCall) ->
          write_widget(encoder, value)

        is_struct(value, Model.WidgetBuilderDeclaration) ->
          encoder = write_byte(encoder, @ms_widget_builder)
          encoder = write_string(encoder, value.argument_name)
          write_argument(encoder, value.widget)

        is_struct(value, Model.ArgsReference) ->
          encoder = write_byte(encoder, @ms_args_reference)
          write_part_list(encoder, value.parts)

        is_struct(value, Model.DataReference) ->
          encoder = write_byte(encoder, @ms_data_reference)
          write_part_list(encoder, value.parts)

        is_struct(value, Model.WidgetBuilderArgReference) ->
          encoder = write_byte(encoder, @ms_widget_builder_arg_reference)
          encoder = write_string(encoder, value.argument_name)
          write_part_list(encoder, value.parts)

        is_struct(value, Model.LoopReference) ->
          encoder = write_byte(encoder, @ms_loop_reference)
          encoder = write_int64(encoder, value.loop)
          write_part_list(encoder, value.parts)

        is_struct(value, Model.StateReference) ->
          encoder = write_byte(encoder, @ms_state_reference)
          write_part_list(encoder, value.parts)

        is_struct(value, Model.EventHandler) ->
          encoder = write_byte(encoder, @ms_event)
          encoder = write_string(encoder, value.event_name)
          write_map(encoder, value.event_arguments, &write_argument/2)

        is_struct(value, Model.Switch) ->
          encoder = write_byte(encoder, @ms_switch)
          {encoder, _} = write_argument(encoder, value.input)
          encoder = write_int64(encoder, map_size(value.outputs))

          Enum.reduce(value.outputs, {encoder, nil}, fn {k, v}, {acc, _} ->
            acc = if is_nil(k), do: write_byte(acc, @ms_default), else: write_argument(acc, k)
            write_argument(acc, v)
          end)

        is_struct(value, Model.SetStateHandler) ->
          encoder = write_byte(encoder, @ms_set_state)
          encoder = write_part_list(encoder, value.state_reference.parts)
          write_argument(encoder, value.value)

        true ->
          raise "Unexpected data type: #{inspect(value)}"
      end
    end

    def write_widget(encoder, value) do
      encoder = write_byte(encoder, @ms_widget)
      encoder = write_string(encoder, value.name)
      write_map(encoder, value.arguments, &write_argument/2)
    end

    def write_map(encoder, map, write_fn) do
      encoder = write_int64(encoder, map_size(map))

      Enum.reduce(map, {encoder, nil}, fn {k, v}, {acc, _} ->
        acc = write_string(acc, to_string(k))
        write_fn.(acc, v)
      end)
    end

    def write_part_list(encoder, parts) do
      encoder = write_int64(encoder, length(parts))

      Enum.reduce(parts, {encoder, nil}, fn part, {acc, _} ->
        cond do
          is_integer(part) ->
            acc = write_byte(acc, @ms_int64)
            write_int64(acc, part)

          is_binary(part) ->
            acc = write_byte(acc, @ms_string)
            write_string(acc, part)

          true ->
            raise "Invalid reference part type: #{inspect(part)}"
        end
      end)
    end

    def write_library(encoder, library) do
      encoder = write_import_list(encoder, library.imports)
      write_declaration_list(encoder, library.widgets)
    end

    def write_import_list(encoder, imports) do
      encoder = write_int64(encoder, length(imports))

      Enum.reduce(imports, {encoder, nil}, fn import, {acc, _} ->
        acc = write_int64(acc, length(import.name.parts))

        Enum.reduce(import.name.parts, {acc, nil}, fn part, {acc2, _} ->
          write_string(acc2, part)
        end)
      end)
    end

    def write_declaration_list(encoder, declarations) do
      encoder = write_int64(encoder, length(declarations))

      Enum.reduce(declarations, {encoder, nil}, fn decl, {acc, _} ->
        write_declaration(acc, decl)
      end)
    end

    def write_declaration(encoder, declaration) do
      encoder = write_string(encoder, declaration.name)

      encoder =
        if is_nil(declaration.initial_state),
          do: write_int64(encoder, 0),
          else: write_map(encoder, declaration.initial_state, &write_argument/2)

      write_argument(encoder, declaration.root)
    end

    def to_binary(encoder), do: encoder.bytes
  end

  defmodule BlobDecoder do
    @moduledoc false
    defstruct [:bytes, :cursor]

    # Magic values
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

    def new(bytes), do: %__MODULE__{bytes: bytes, cursor: 0}

    def finished?(decoder), do: decoder.cursor >= byte_size(decoder.bytes)

    def expect_signature(decoder, signature) do
      {decoder, read_signature} = read_bytes(decoder, byte_size(signature))

      if read_signature != signature do
        raise "File signature mismatch. Expected #{inspect(signature)}, but found #{inspect(read_signature)}."
      end

      decoder
    end

    def read_byte(decoder) do
      {decoder, <<byte::8>>} = read_bytes(decoder, 1)
      {decoder, byte}
    end

    def read_int64(decoder) do
      {decoder, <<value::little-64>>} = read_bytes(decoder, 8)
      {decoder, value}
    end

    def read_binary64(decoder) do
      {decoder, <<value::little-float-64>>} = read_bytes(decoder, 8)
      {decoder, value}
    end

    def read_string(decoder) do
      {decoder, length} = read_int64(decoder)
      read_bytes(decoder, length)
    end

    def read_bytes(decoder, length) do
      if decoder.cursor + length > byte_size(decoder.bytes) do
        raise "Could not read #{length} bytes at offset #{decoder.cursor}: unexpected end of file."
      end

      value = binary_part(decoder.bytes, decoder.cursor, length)
      decoder = %{decoder | cursor: decoder.cursor + length}
      {decoder, value}
    end

    def read_value(decoder) do
      {decoder, type} = read_byte(decoder)

      case type do
        @ms_false -> {decoder, false}
        @ms_true -> {decoder, true}
        @ms_int64 -> read_int64(decoder)
        @ms_binary64 -> read_binary64(decoder)
        @ms_string -> read_string(decoder)
        @ms_list -> read_list(decoder)
        @ms_map -> read_map(decoder, &read_value/1)
        _ -> read_argument(decoder, type)
      end
    end

    def read_argument(decoder, type) do
      case type do
        @ms_loop -> read_loop(decoder)
        @ms_widget -> read_widget(decoder)
        @ms_args_reference -> read_args_reference(decoder)
        @ms_data_reference -> read_data_reference(decoder)
        @ms_loop_reference -> read_loop_reference(decoder)
        @ms_state_reference -> read_state_reference(decoder)
        @ms_event -> read_event(decoder)
        @ms_switch -> read_switch(decoder)
        @ms_set_state -> read_set_state(decoder)
        @ms_widget_builder -> read_widget_builder(decoder)
        @ms_widget_builder_arg_reference -> read_widget_builder_arg_reference(decoder)
        _ -> raise "Unrecognized data type 0x#{Integer.to_string(type, 16)} while decoding blob."
      end
    end

    def read_list(decoder) do
      {decoder, length} = read_int64(decoder)

      Enum.reduce(1..length, {decoder, []}, fn _, {acc, list} ->
        {acc, value} = read_value(acc)
        {acc, [value | list]}
      end)
      |> then(fn {decoder, list} -> {decoder, Enum.reverse(list)} end)
    end

    def read_switch(decoder) do
      {decoder, input} = read_value(decoder)
      {decoder, count} = read_int64(decoder)

      {decoder, outputs} =
        Enum.reduce(1..count, {decoder, %{}}, fn _, {acc, map} ->
          {acc, key} = read_switch_key(acc)
          {acc, value} = read_value(acc)
          {acc, Map.put(map, key, value)}
        end)

      {decoder, Model.new_switch(input, outputs)}
    end

    def read_switch_key(decoder) do
      {decoder, type} = read_byte(decoder)

      if type == @ms_default do
        {decoder, nil}
      else
        parse_value(decoder, type)
      end
    end

    def parse_value(decoder, type) do
      case type do
        @ms_false ->
          {decoder, false}

        @ms_true ->
          {decoder, true}

        @ms_int64 ->
          read_int64(decoder)

        @ms_binary64 ->
          read_binary64(decoder)

        @ms_string ->
          read_string(decoder)

        @ms_list ->
          {decoder, length} = read_int64(decoder)

          Enum.reduce(1..length, {decoder, []}, fn _, {acc, list} ->
            {acc, value} = read_value(acc)
            {acc, [value | list]}
          end)
          |> then(fn {decoder, list} -> {decoder, Enum.reverse(list)} end)

        @ms_map ->
          {decoder, length} = read_int64(decoder)

          Enum.reduce(1..length, {decoder, %{}}, fn _, {acc, map} ->
            {acc, key} = read_string(acc)
            {acc, value} = read_value(acc)
            {acc, Map.put(map, key, value)}
          end)

        _ ->
          parse_argument(decoder, type)
      end
    end

    def parse_argument(decoder, type) do
      case type do
        @ms_loop -> read_loop(decoder)
        @ms_widget -> read_widget(decoder)
        @ms_args_reference -> read_args_reference(decoder)
        @ms_data_reference -> read_data_reference(decoder)
        @ms_loop_reference -> read_loop_reference(decoder)
        @ms_state_reference -> read_state_reference(decoder)
        @ms_event -> read_event(decoder)
        @ms_switch -> read_switch(decoder)
        @ms_set_state -> read_set_state(decoder)
        @ms_widget_builder -> read_widget_builder(decoder)
        @ms_widget_builder_arg_reference -> read_widget_builder_arg_reference(decoder)
        _ -> raise "Unrecognized data type 0x#{Integer.to_string(type, 16)} while decoding blob."
      end
    end

    def read_loop(decoder) do
      {decoder, input} = read_value(decoder)
      {decoder, output} = read_value(decoder)
      {decoder, Model.new_loop(input, output)}
    end

    def read_widget(decoder) do
      {decoder, name} = read_string(decoder)
      {decoder, arguments} = read_map(decoder, &read_value/1)
      {decoder, Model.new_constructor_call(name, arguments)}
    end

    def read_args_reference(decoder) do
      {decoder, parts} = read_part_list(decoder)
      {decoder, Model.new_args_reference(parts)}
    end

    def read_data_reference(decoder) do
      {decoder, parts} = read_part_list(decoder)
      {decoder, Model.new_data_reference(parts)}
    end

    def read_loop_reference(decoder) do
      {decoder, loop} = read_int64(decoder)
      {decoder, parts} = read_part_list(decoder)
      {decoder, Model.new_loop_reference(loop, parts)}
    end

    def read_state_reference(decoder) do
      {decoder, parts} = read_part_list(decoder)
      {decoder, Model.new_state_reference(parts)}
    end

    def read_event(decoder) do
      {decoder, event_name} = read_string(decoder)
      {decoder, event_arguments} = read_map(decoder, &read_value/1)
      {decoder, Model.new_event_handler(event_name, event_arguments)}
    end

    def read_set_state(decoder) do
      {decoder, parts} = read_part_list(decoder)
      {decoder, value} = read_value(decoder)
      {decoder, Model.new_set_state_handler(Model.new_state_reference(parts), value)}
    end

    def read_widget_builder(decoder) do
      {decoder, argument_name} = read_string(decoder)
      {decoder, widget} = read_value(decoder)
      {decoder, Model.new_widget_builder_declaration(argument_name, widget)}
    end

    def read_widget_builder_arg_reference(decoder) do
      {decoder, argument_name} = read_string(decoder)
      {decoder, parts} = read_part_list(decoder)
      {decoder, Model.new_widget_builder_arg_reference(argument_name, parts)}
    end

    def read_part_list(decoder) do
      {decoder, length} = read_int64(decoder)

      Enum.reduce(1..length, {decoder, []}, fn _, {acc, list} ->
        {acc, type} = read_byte(acc)

        {acc, part} =
          case type do
            @ms_string -> read_string(acc)
            @ms_int64 -> read_int64(acc)
            _ -> raise "Invalid reference part type: #{type}"
          end

        {acc, [part | list]}
      end)
      |> then(fn {decoder, list} -> {decoder, Enum.reverse(list)} end)
    end

    def read_map(decoder, read_fn) do
      {decoder, count} = read_int64(decoder)

      Enum.reduce(1..count, {decoder, %{}}, fn _, {acc, map} ->
        {acc, key} = read_string(acc)
        {acc, value} = read_fn.(acc)
        {acc, Map.put(map, key, value)}
      end)
    end

    def read_library(decoder) do
      {decoder, imports} = read_import_list(decoder)
      {decoder, widgets} = read_declaration_list(decoder)
      {decoder, Model.new_remote_widget_library(imports, widgets)}
    end

    def read_import_list(decoder) do
      {decoder, count} = read_int64(decoder)

      Enum.reduce(1..count, {decoder, []}, fn _, {acc, list} ->
        {acc, parts_count} = read_int64(acc)

        {acc, parts} =
          Enum.reduce(1..parts_count, {acc, []}, fn _, {acc2, parts} ->
            {acc2, part} = read_string(acc2)
            {acc2, [part | parts]}
          end)

        library_name = Model.new_library_name(Enum.reverse(parts))
        {acc, [Model.new_import(library_name) | list]}
      end)
      |> then(fn {decoder, list} -> {decoder, Enum.reverse(list)} end)
    end

    def read_declaration_list(decoder) do
      {decoder, count} = read_int64(decoder)

      Enum.reduce(1..count, {decoder, []}, fn _, {acc, list} ->
        {acc, declaration} = read_declaration(acc)
        {acc, [declaration | list]}
      end)
      |> then(fn {decoder, list} -> {decoder, Enum.reverse(list)} end)
    end

    def read_declaration(decoder) do
      {decoder, name} = read_string(decoder)
      {decoder, initial_state} = read_map(decoder, &read_value/1)
      initial_state = if map_size(initial_state) == 0, do: nil, else: initial_state
      {decoder, root} = read_value(decoder)
      {decoder, Model.new_widget_declaration(name, initial_state, root)}
    end
  end
end
