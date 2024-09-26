defmodule RfwFormats.Binary do
  @moduledoc """
  Provides functions to encode and decode Remote Flutter Widgets data and library blobs.
  """

  alias RfwFormats.Model.{
    Loop,
    Switch,
    ConstructorCall,
    ArgsReference,
    DataReference,
    LoopReference,
    StateReference,
    EventHandler,
    SetStateHandler,
    WidgetBuilderDeclaration,
    WidgetBuilderArgReference,
    WidgetDeclaration,
    RemoteWidgetLibrary,
    Import,
    LibraryName
  }

  @data_blob_signature <<0xFE, 0x52, 0x57, 0x44>>
  @library_blob_signature <<0xFE, 0x52, 0x46, 0x57>>

  @doc """
  Encodes a value into a Remote Flutter Widgets binary data blob.
  """
  @spec encode_data_blob(any()) :: binary()
  def encode_data_blob(value) do
    encoder = RfwFormats.Binary.BlobEncoder.new()
    encoder = RfwFormats.Binary.BlobEncoder.write_signature(encoder, @data_blob_signature)
    encoder = RfwFormats.Binary.BlobEncoder.write_value(encoder, value)
    RfwFormats.Binary.BlobEncoder.get_bytes(encoder)
  end

  @doc """
  Decodes a Remote Flutter Widgets binary data blob into a value.
  """
  @spec decode_data_blob(binary()) :: any()
  def decode_data_blob(bytes) do
    {:ok, decoder} = RfwFormats.Binary.BlobDecoder.new(bytes)

    with {:ok, decoder} <-
           RfwFormats.Binary.BlobDecoder.expect_signature(decoder, @data_blob_signature),
         {:ok, {value, decoder}} <- RfwFormats.Binary.BlobDecoder.read_value(decoder) do
      if RfwFormats.Binary.BlobDecoder.finished?(decoder) do
        value
      else
        raise RuntimeError, "Unexpected trailing bytes after value."
      end
    else
      {:error, error} -> raise RuntimeError, error
    end
  end

  @doc """
  Encodes a `RemoteWidgetLibrary` into a binary library blob.
  """
  @spec encode_library_blob(RemoteWidgetLibrary.t()) :: binary()
  def encode_library_blob(library) do
    encoder = RfwFormats.Binary.BlobEncoder.new()
    encoder = RfwFormats.Binary.BlobEncoder.write_signature(encoder, @library_blob_signature)
    encoder = RfwFormats.Binary.BlobEncoder.write_library(encoder, library)
    RfwFormats.Binary.BlobEncoder.get_bytes(encoder)
  end

  @doc """
  Decodes a Remote Flutter Widgets binary library blob into a `RemoteWidgetLibrary`.
  """
  @spec decode_library_blob(binary()) :: RemoteWidgetLibrary.t()
  def decode_library_blob(bytes) do
    {:ok, decoder} = RfwFormats.Binary.BlobDecoder.new(bytes)

    with {:ok, decoder} <-
           RfwFormats.Binary.BlobDecoder.expect_signature(decoder, @library_blob_signature),
         {:ok, {library, decoder}} <- RfwFormats.Binary.BlobDecoder.read_library(decoder) do
      if RfwFormats.Binary.BlobDecoder.finished?(decoder) do
        library
      else
        raise RuntimeError, "Unexpected trailing bytes after constructors."
      end
    else
      {:error, error} -> raise RuntimeError, error
    end
  end
end

defmodule RfwFormats.Binary.BlobEncoder do
  @moduledoc false

  alias RfwFormats.Model.{
    RemoteWidgetLibrary,
    Import,
    LibraryName,
    WidgetDeclaration,
    ConstructorCall,
    Switch,
    Loop,
    ArgsReference,
    DataReference,
    LoopReference,
    StateReference,
    EventHandler,
    SetStateHandler,
    WidgetBuilderDeclaration,
    WidgetBuilderArgReference
  }

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

  defstruct [:bytes]

  @type t :: %__MODULE__{
          bytes: binary()
        }

  @spec new() :: t()
  def new(), do: %__MODULE__{bytes: <<>>}

  @spec write_signature(t(), binary()) :: t()
  def write_signature(encoder, signature) when is_binary(signature) do
    %{encoder | bytes: encoder.bytes <> signature}
  end

  @spec write_value(t(), any()) :: t()
  def write_value(encoder, value) do
    write_value(encoder, value, &write_value/2)
  end

  @spec write_library(t(), RemoteWidgetLibrary.t()) :: t()
  def write_library(encoder, %RemoteWidgetLibrary{imports: imports, widgets: widgets}) do
    encoder
    |> write_import_list(imports)
    |> write_declaration_list(widgets)
  end

  @spec get_bytes(t()) :: binary()
  def get_bytes(%__MODULE__{bytes: bytes}), do: bytes

  defp write_value(encoder, value, recurse) do
    cond do
      value == true ->
        write_byte(encoder, @ms_true)

      value == false ->
        write_byte(encoder, @ms_false)

      is_integer(value) ->
        encoder |> write_byte(@ms_int64) |> write_int64(value)

      is_float(value) ->
        encoder |> write_byte(@ms_binary64) |> write_binary64(value)

      is_binary(value) ->
        encoder |> write_byte(@ms_string) |> write_string(value)

      is_list(value) ->
        encoder
        |> write_byte(@ms_list)
        |> write_int64(length(value))
        |> write_list(value, recurse)

      is_map(value) ->
        encoder
        |> write_byte(@ms_map)
        |> write_int64(map_size(value))
        |> write_map(value, recurse)

      true ->
        raise "Unsupported value type: #{inspect(value)}"
    end
  end

  defp write_import_list(encoder, imports) do
    encoder
    |> write_int64(length(imports))
    |> write_list(imports, &write_import/2)
  end

  defp write_import(encoder, %Import{name: %LibraryName{parts: parts}}) do
    encoder
    |> write_int64(length(parts))
    |> write_list(parts, &write_string/2)
  end

  defp write_declaration_list(encoder, widgets) do
    encoder
    |> write_int64(length(widgets))
    |> write_list(widgets, &write_declaration/2)
  end

  defp write_declaration(
         %WidgetDeclaration{name: name, initial_state: initial_state, root: root},
         encoder
       ) do
    encoder
    |> write_string(name)
    |> write_initial_state(initial_state)
    |> write_root(root)
  end

  defp write_initial_state(encoder, nil) do
    write_map(encoder, %{}, &write_argument/2)
  end

  defp write_initial_state(encoder, initial_state) when is_map(initial_state) do
    write_map(encoder, initial_state, &write_argument/2)
  end

  defp write_root(encoder, %ConstructorCall{} = root) do
    write_argument(encoder, root)
  end

  defp write_root(encoder, %Switch{} = root) do
    write_argument(encoder, root)
  end

  defp write_argument(encoder, %ConstructorCall{name: name, arguments: arguments}) do
    encoder
    |> write_byte(@ms_widget)
    |> write_string(name)
    |> write_map(arguments, &write_argument/2)
  end

  defp write_argument(encoder, %Switch{input: input, outputs: outputs}) do
    encoder
    |> write_byte(@ms_switch)
    |> write_argument(input)
    |> write_switch_outputs(outputs)
  end

  defp write_argument(encoder, %Loop{input: input, output: output}) do
    encoder
    |> write_byte(@ms_loop)
    |> write_argument(input)
    |> write_argument(output)
  end

  defp write_argument(encoder, %ArgsReference{parts: parts}) do
    encoder
    |> write_byte(@ms_args_reference)
    |> write_part_list(parts)
  end

  defp write_argument(encoder, %DataReference{parts: parts}) do
    encoder
    |> write_byte(@ms_data_reference)
    |> write_part_list(parts)
  end

  defp write_argument(encoder, %LoopReference{loop: loop, parts: parts}) do
    encoder
    |> write_byte(@ms_loop_reference)
    |> write_int64(loop)
    |> write_part_list(parts)
  end

  defp write_argument(encoder, %StateReference{parts: parts}) do
    encoder
    |> write_byte(@ms_state_reference)
    |> write_part_list(parts)
  end

  defp write_argument(encoder, %EventHandler{
         event_name: event_name,
         event_arguments: event_arguments
       }) do
    encoder
    |> write_byte(@ms_event)
    |> write_string(event_name)
    |> write_map(event_arguments, &write_argument/2)
  end

  defp write_argument(encoder, %SetStateHandler{
         state_reference: %StateReference{parts: parts},
         value: value
       }) do
    encoder
    |> write_byte(@ms_set_state)
    |> write_part_list(parts)
    |> write_argument(value)
  end

  defp write_argument(encoder, %WidgetBuilderDeclaration{
         argument_name: argument_name,
         widget: widget
       }) do
    encoder
    |> write_byte(@ms_widget_builder)
    |> write_string(argument_name)
    |> write_argument(widget)
  end

  defp write_argument(encoder, %WidgetBuilderArgReference{
         argument_name: argument_name,
         parts: parts
       }) do
    encoder
    |> write_byte(@ms_widget_builder_arg_reference)
    |> write_string(argument_name)
    |> write_part_list(parts)
  end

  defp write_argument(encoder, value), do: write_value(encoder, value)

  defp write_switch_outputs(encoder, outputs) do
    encoder
    |> write_int64(map_size(outputs))
    |> write_map(outputs, fn encoder, {key, value} ->
      encoder
      |> write_switch_key(key)
      |> write_argument(value)
    end)
  end

  defp write_switch_key(encoder, nil) do
    write_byte(encoder, @ms_default)
  end

  defp write_switch_key(encoder, key) do
    write_argument(encoder, key)
  end

  defp write_part_list(encoder, parts) do
    encoder
    |> write_int64(length(parts))
    |> write_list(parts, &write_part/2)
  end

  defp write_part(encoder, part) when is_binary(part) do
    encoder
    |> write_byte(@ms_string)
    |> write_string(part)
  end

  defp write_part(encoder, part) when is_integer(part) do
    encoder
    |> write_byte(@ms_int64)
    |> write_int64(part)
  end

  defp write_byte(%__MODULE__{bytes: bytes} = encoder, byte) when is_integer(byte) do
    %{encoder | bytes: bytes <> <<byte::unsigned-integer-size(8)>>}
  end

  defp write_int64(%__MODULE__{bytes: bytes} = encoder, value) when is_integer(value) do
    %{encoder | bytes: bytes <> <<value::little-signed-integer-size(64)>>}
  end

  defp write_binary64(%__MODULE__{bytes: bytes} = encoder, value) when is_float(value) do
    %{encoder | bytes: bytes <> <<value::little-float-size(64)>>}
  end

  defp write_string(encoder, value) when is_binary(value) do
    encoder
    |> write_int64(byte_size(value))
    |> Map.update!(:bytes, &(&1 <> value))
  end

  defp write_list(encoder, list, write_fn) do
    Enum.reduce(list, encoder, fn item, acc -> write_fn.(acc, item) end)
  end

  defp write_map(encoder, map, write_fn) do
    Enum.reduce(map, encoder, fn {k, v}, acc ->
      acc
      |> write_string(k)
      |> write_fn.(v)
    end)
  end
end

defmodule RfwFormats.Binary.BlobDecoder do
  @moduledoc false

  alias RfwFormats.Model.{
    RemoteWidgetLibrary,
    Import,
    LibraryName,
    WidgetDeclaration,
    ConstructorCall,
    Switch,
    Loop,
    ArgsReference,
    DataReference,
    LoopReference,
    StateReference,
    EventHandler,
    SetStateHandler,
    WidgetBuilderDeclaration,
    WidgetBuilderArgReference
  }

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

  defstruct [:bytes, :cursor]

  @type t :: %__MODULE__{
          bytes: binary(),
          cursor: non_neg_integer()
        }

  @spec new(binary()) :: {:ok, t()} | {:error, String.t()}
  def new(bytes) when is_binary(bytes) do
    {:ok, %__MODULE__{bytes: bytes, cursor: 0}}
  end

  @spec finished?(t()) :: boolean()
  def finished?(%__MODULE__{bytes: bytes, cursor: cursor}) do
    cursor == byte_size(bytes)
  end

  @spec expect_signature(t(), binary()) :: {:ok, t()} | {:error, String.t()}
  def expect_signature(decoder, signature) do
    case read_bytes(decoder, byte_size(signature)) do
      {:ok, {read_sig, decoder}} ->
        if read_sig == signature do
          {:ok, decoder}
        else
          {:error,
           "File signature mismatch. Expected #{inspect(signature, base: :hex)}, but found #{inspect(read_sig, base: :hex)}."}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @spec read_library(t()) :: {:ok, {RemoteWidgetLibrary.t(), t()}} | {:error, String.t()}
  def read_library(decoder) do
    with {:ok, {imports, decoder}} <- read_import_list(decoder),
         {:ok, {widgets, decoder}} <- read_declaration_list(decoder) do
      {:ok, {%RemoteWidgetLibrary{imports: imports, widgets: widgets}, decoder}}
    end
  end

  @spec read_value(t()) :: {:ok, {any(), t()}} | {:error, String.t()}
  def read_value(decoder) do
    with {:ok, {type, decoder}} <- read_byte(decoder) do
      parse_value(decoder, type, &read_value/1)
    end
  end

  @spec read_import_list(t()) :: {:ok, {[Import.t()], t()}} | {:error, String.t()}
  defp read_import_list(decoder) do
    with {:ok, {count, decoder}} <- read_int64(decoder) do
      read_list(decoder, count, &read_import/1)
    end
  end

  @spec read_declaration_list(t()) :: {:ok, {[WidgetDeclaration.t()], t()}} | {:error, String.t()}
  defp read_declaration_list(decoder) do
    with {:ok, {count, decoder}} <- read_int64(decoder) do
      read_list(decoder, count, &read_declaration/1)
    end
  end

  @spec read_list(t(), non_neg_integer(), (t() -> {:ok, {any(), t()}} | {:error, String.t()})) ::
          {:ok, {[any()], t()}} | {:error, String.t()}
  defp read_list(decoder, count, read_item_func) do
    Enum.reduce_while(1..count, {:ok, {[], decoder}}, fn _, {:ok, {acc, dec}} ->
      case read_item_func.(dec) do
        {:ok, {item, new_dec}} -> {:cont, {:ok, {[item | acc], new_dec}}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, {list, decoder}} -> {:ok, {Enum.reverse(list), decoder}}
      {:error, error} -> {:error, error}
    end
  end

  @spec read_import(t()) :: {:ok, {Import.t(), t()}} | {:error, String.t()}
  defp read_import(decoder) do
    with {:ok, {part_count, decoder}} <- read_int64(decoder),
         {:ok, {parts, decoder}} <- read_list(decoder, part_count, &read_string/1) do
      {:ok, {%Import{name: %LibraryName{parts: parts}}, decoder}}
    end
  end

  @spec read_declaration(t()) :: {:ok, {WidgetDeclaration.t(), t()}} | {:error, String.t()}
  defp read_declaration(decoder) do
    with {:ok, {name, decoder}} <- read_string(decoder),
         {:ok, {initial_state, decoder}} <- read_map(decoder, &read_value/1),
         {:ok, {root, decoder}} <- read_argument(decoder) do
      {:ok, {%WidgetDeclaration{name: name, initial_state: initial_state, root: root}, decoder}}
    end
  end

  @spec parse_value(t(), byte(), (t() -> {:ok, {any(), t()}} | {:error, String.t()})) ::
          {:ok, {any(), t()}} | {:error, String.t()}
  defp parse_value(decoder, type, read_node) do
    case type do
      @ms_false ->
        {:ok, {false, decoder}}

      @ms_true ->
        {:ok, {true, decoder}}

      @ms_int64 ->
        read_int64(decoder)

      @ms_binary64 ->
        read_binary64(decoder)

      @ms_string ->
        read_string(decoder)

      @ms_list ->
        with {:ok, {count, decoder}} <- read_int64(decoder) do
          read_list(decoder, count, read_node)
        end

      @ms_map ->
        read_map(decoder, read_node)

      _ ->
        {:error, "Unrecognized data type 0x#{Integer.to_string(type, 16)} while decoding blob."}
    end
  end

  @spec parse_argument(t(), byte()) :: {:ok, {any(), t()}} | {:error, String.t()}
  defp parse_argument(decoder, type) do
    case type do
      @ms_loop ->
        with {:ok, {input, decoder}} <- read_argument(decoder),
             {:ok, {output, decoder}} <- read_argument(decoder) do
          {:ok, {%Loop{input: input, output: output}, decoder}}
        end

      @ms_switch ->
        read_switch(decoder)

      @ms_widget ->
        read_widget(decoder)

      @ms_args_reference ->
        with {:ok, {parts, decoder}} <- read_part_list(decoder) do
          {:ok, {%ArgsReference{parts: parts}, decoder}}
        end

      @ms_data_reference ->
        with {:ok, {parts, decoder}} <- read_part_list(decoder) do
          {:ok, {%DataReference{parts: parts}, decoder}}
        end

      @ms_loop_reference ->
        with {:ok, {loop_index, decoder}} <- read_int64(decoder),
             {:ok, {parts, decoder}} <- read_part_list(decoder) do
          {:ok, {%LoopReference{loop: loop_index, parts: parts}, decoder}}
        end

      @ms_state_reference ->
        with {:ok, {parts, decoder}} <- read_part_list(decoder) do
          {:ok, {%StateReference{parts: parts}, decoder}}
        end

      @ms_event ->
        with {:ok, {event_name, decoder}} <- read_string(decoder),
             {:ok, {event_arguments, decoder}} <- read_map(decoder, &read_argument/1) do
          {:ok,
           {%EventHandler{event_name: event_name, event_arguments: event_arguments}, decoder}}
        end

      @ms_set_state ->
        with {:ok, {parts, decoder}} <- read_part_list(decoder),
             {:ok, {value, decoder}} <- read_argument(decoder) do
          {:ok,
           {%SetStateHandler{state_reference: %StateReference{parts: parts}, value: value},
            decoder}}
        end

      @ms_widget_builder ->
        read_widget_builder(decoder)

      @ms_widget_builder_arg_reference ->
        with {:ok, {argument_name, decoder}} <- read_string(decoder),
             {:ok, {parts, decoder}} <- read_part_list(decoder) do
          {:ok, {%WidgetBuilderArgReference{argument_name: argument_name, parts: parts}, decoder}}
        end

      _ ->
        if type in [@ms_false, @ms_true, @ms_int64, @ms_binary64, @ms_string, @ms_list, @ms_map] do
          parse_value(decoder, type, &read_argument/1)
        else
          {:error, "Unrecognized data type 0x#{Integer.to_string(type, 16)} while decoding blob."}
        end
    end
  end

  @spec read_argument(t()) :: {:ok, {any(), t()}} | {:error, String.t()}
  defp read_argument(decoder) do
    with {:ok, {type, decoder}} <- read_byte(decoder) do
      parse_argument(decoder, type)
    end
  end

  @spec read_widget(t()) :: {:ok, {ConstructorCall.t(), t()}} | {:error, String.t()}
  defp read_widget(decoder) do
    with {:ok, {name, decoder}} <- read_string(decoder),
         {:ok, {arguments, decoder}} <- read_map(decoder, &read_argument/1) do
      {:ok, {%ConstructorCall{name: name, arguments: arguments}, decoder}}
    end
  end

  @spec read_widget_builder(t()) ::
          {:ok, {WidgetBuilderDeclaration.t(), t()}} | {:error, String.t()}
  defp read_widget_builder(decoder) do
    with {:ok, {argument_name, decoder}} <- read_string(decoder),
         {:ok, {widget, decoder}} <- read_argument(decoder) do
      {:ok, {%WidgetBuilderDeclaration{argument_name: argument_name, widget: widget}, decoder}}
    end
  end

  @spec read_switch(t()) :: {:ok, {Switch.t(), t()}} | {:error, String.t()}
  defp read_switch(decoder) do
    with {:ok, {input, decoder}} <- read_argument(decoder),
         {:ok, {count, decoder}} <- read_int64(decoder),
         {:ok, {outputs, decoder}} <-
           read_list(decoder, count, fn dec ->
             with {:ok, {key, dec}} <- read_switch_key(dec),
                  {:ok, {value, dec}} <- read_argument(dec) do
               {:ok, {{key, value}, dec}}
             end
           end) do
      {:ok, {%Switch{input: input, outputs: Map.new(outputs)}, decoder}}
    end
  end

  @spec read_switch_key(t()) :: {:ok, {any(), t()}} | {:error, String.t()}
  defp read_switch_key(decoder) do
    with {:ok, {type, decoder}} <- read_byte(decoder) do
      if type == @ms_default do
        {:ok, {nil, decoder}}
      else
        # Unread the byte we just read
        decoder = %{decoder | cursor: decoder.cursor - 1}
        read_argument(decoder)
      end
    end
  end

  @spec read_map(t(), (t() -> {:ok, {any(), t()}} | {:error, String.t()})) ::
          {:ok, {map(), t()}} | {:error, String.t()}
  defp read_map(decoder, read_value_func) do
    with {:ok, {count, decoder}} <- read_int64(decoder),
         {:ok, {entries, decoder}} <-
           read_list(decoder, count, fn dec ->
             with {:ok, {key, dec}} <- read_string(dec),
                  {:ok, {value, dec}} <- read_value_func.(dec) do
               {:ok, {{key, value}, dec}}
             end
           end) do
      {:ok, {Map.new(entries), decoder}}
    end
  end

  @spec read_part_list(t()) :: {:ok, {[any()], t()}} | {:error, String.t()}
  defp read_part_list(decoder) do
    with {:ok, {count, decoder}} <- read_int64(decoder) do
      read_list(decoder, count, &read_part/1)
    end
  end

  @spec read_part(t()) :: {:ok, {String.t() | integer(), t()}} | {:error, String.t()}
  defp read_part(decoder) do
    with {:ok, {type, decoder}} <- read_byte(decoder) do
      case type do
        @ms_string ->
          read_string(decoder)

        @ms_int64 ->
          read_int64(decoder)

        _ ->
          {:error, "Invalid reference type 0x#{Integer.to_string(type, 16)} while decoding blob."}
      end
    end
  end

  @spec read_byte(t()) :: {:ok, {byte(), t()}} | {:error, String.t()}
  defp read_byte(%__MODULE__{bytes: bytes, cursor: cursor} = decoder) do
    if cursor + 1 > byte_size(bytes) do
      {:error, "Could not read byte at offset #{cursor}: unexpected end of file."}
    else
      <<byte::unsigned-integer-size(8)>> = binary_part(bytes, cursor, 1)
      {:ok, {byte, %{decoder | cursor: cursor + 1}}}
    end
  end

  @spec read_int64(t()) :: {:ok, {integer(), t()}} | {:error, String.t()}
  defp read_int64(%__MODULE__{bytes: bytes, cursor: cursor} = decoder) do
    if cursor + 8 > byte_size(bytes) do
      {:error, "Could not read int64 at offset #{cursor}: unexpected end of file."}
    else
      <<int::little-signed-integer-size(64)>> = binary_part(bytes, cursor, 8)
      {:ok, {int, %{decoder | cursor: cursor + 8}}}
    end
  end

  @spec read_binary64(t()) :: {:ok, {float(), t()}} | {:error, String.t()}
  defp read_binary64(%__MODULE__{bytes: bytes, cursor: cursor} = decoder) do
    if cursor + 8 > byte_size(bytes) do
      {:error, "Could not read binary64 at offset #{cursor}: unexpected end of file."}
    else
      <<float::little-float-size(64)>> = binary_part(bytes, cursor, 8)
      {:ok, {float, %{decoder | cursor: cursor + 8}}}
    end
  end

  @spec read_string(t()) :: {:ok, {String.t(), t()}} | {:error, String.t()}
  defp read_string(decoder) do
    with {:ok, {length, decoder}} <- read_int64(decoder),
         {:ok, {data, decoder}} <- read_bytes(decoder, length) do
      {:ok, {data, decoder}}
    end
  end

  @spec read_bytes(t(), non_neg_integer()) :: {:ok, {binary(), t()}} | {:error, String.t()}
  defp read_bytes(%__MODULE__{bytes: bytes, cursor: cursor} = decoder, length) do
    if cursor + length > byte_size(bytes) do
      {:error, "Could not read #{length} bytes at offset #{cursor}: unexpected end of file."}
    else
      data = binary_part(bytes, cursor, length)
      {:ok, {data, %{decoder | cursor: cursor + length}}}
    end
  end
end
