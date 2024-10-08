defmodule RfwFormats.Binary do
  @moduledoc """
  Provides functions to encode and decode Remote Flutter Widgets data and library blobs.
  """

  alias RfwFormats.Model
  require Logger

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

  @doc """
  Encodes a value into a Remote Flutter Widgets binary data blob.
  """
  @spec encode_data_blob(any()) :: binary()
  def encode_data_blob(value) do
    encoder = %{bytes: @data_blob_signature}
    encoder = write_value(encoder, value)
    encoder.bytes
  end

  @doc """
  Decodes a Remote Flutter Widgets binary data blob into a value.
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
  """
  @spec encode_library_blob(Model.RemoteWidgetLibrary.t()) :: binary()
  def encode_library_blob(library) do
    encoder = %{bytes: @library_blob_signature}
    encoder = write_library(encoder, library)
    Logger.debug("Encoded library blob: #{inspect(encoder.bytes, limit: :infinity)}")
    encoder.bytes
  end

  @doc """
  Decodes a Remote Flutter Widgets binary library blob into a `RemoteWidgetLibrary`.
  """
  @spec decode_library_blob(binary()) :: Model.RemoteWidgetLibrary.t()
  def decode_library_blob(bytes) do
    Logger.debug("Decoding library blob: #{inspect(bytes, limit: :infinity)}")

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

  defp write_byte(encoder, byte) do
    %{encoder | bytes: <<encoder.bytes::binary, byte>>}
  end

  defp write_int64(encoder, value) do
    %{encoder | bytes: <<encoder.bytes::binary, value::little-signed-integer-size(64)>>}
  end

  defp write_float64(encoder, value) do
    %{encoder | bytes: <<encoder.bytes::binary, value::little-float-size(64)>>}
  end

  defp write_string(encoder, value) do
    encoder = write_int64(encoder, byte_size(value))
    %{encoder | bytes: <<encoder.bytes::binary, value::binary>>}
  end

  defp write_value(encoder, value) do
    Logger.debug("Writing value: #{inspect(value)}")

    case value do
      %Model.RemoteWidgetLibrary{} ->
        write_library(encoder, value)

      %Model.WidgetDeclaration{} ->
        write_widget_declaration(encoder, value)

      %Model.ConstructorCall{} ->
        write_constructor_call(encoder, value)

      %Model.Import{} ->
        write_import(encoder, value)

      %Model.Loop{} ->
        write_loop(encoder, value)

      %Model.Switch{} ->
        write_switch(encoder, value)

      %Model.ArgsReference{} ->
        write_args_reference(encoder, value)

      %Model.DataReference{} ->
        write_data_reference(encoder, value)

      %Model.StateReference{} ->
        write_state_reference(encoder, value)

      %Model.LoopReference{} ->
        write_loop_reference(encoder, value)

      %Model.EventHandler{} ->
        write_event_handler(encoder, value)

      %Model.SetStateHandler{} ->
        write_set_state_handler(encoder, value)

      %Model.WidgetBuilderDeclaration{} ->
        write_widget_builder_declaration(encoder, value)

      %Model.WidgetBuilderArgReference{} ->
        write_widget_builder_arg_reference(encoder, value)

      true ->
        write_byte(encoder, @ms_true)

      false ->
        write_byte(encoder, @ms_false)

      v when is_list(v) ->
        write_list(encoder, v)

      v when is_map(v) ->
        write_map(encoder, v)

      v when is_integer(v) ->
        encoder
        |> write_byte(@ms_int64)
        |> write_int64(v)

      v when is_float(v) ->
        encoder
        |> write_byte(@ms_binary64)
        |> write_float64(v)

      v when is_binary(v) ->
        encoder
        |> write_byte(@ms_string)
        |> write_string(v)

      nil ->
        write_map(encoder, %{})

      _ ->
        raise ArgumentError, "Unsupported value type: #{inspect(value)}"
    end
  end

  defp write_list(encoder, list) do
    encoder
    |> write_byte(@ms_list)
    |> write_int64(length(list))
    |> (fn e -> Enum.reduce(list, e, &write_value(&2, &1)) end).()
  end

  defp write_map(encoder, map) do
    encoder
    |> write_byte(@ms_map)
    |> write_int64(map_size(map))
    |> (fn e ->
          Enum.reduce(map, e, fn {k, v}, acc ->
            acc
            |> write_string(to_string(k))
            |> write_value(v)
          end)
        end).()
  end

  defp write_widget_builder_arg_reference(encoder, %Model.WidgetBuilderArgReference{
         argument_name: arg_name,
         parts: parts
       }) do
    encoder
    |> write_byte(@ms_widget_builder_arg_reference)
    |> write_string(arg_name)
    |> write_parts(parts)
  end

  defp write_widget_builder_declaration(encoder, %Model.WidgetBuilderDeclaration{
         argument_name: arg_name,
         widget: widget
       }) do
    encoder
    |> write_byte(@ms_widget_builder)
    |> write_string(arg_name)
    |> write_value(widget)
  end

  defp write_loop(encoder, %Model.Loop{input: input, output: output}) do
    encoder
    |> write_byte(@ms_loop)
    |> write_value(input)
    |> write_value(output)
  end

  defp write_loop_reference(encoder, %Model.LoopReference{loop: loop, parts: parts}) do
    encoder
    |> write_byte(@ms_loop_reference)
    |> write_int64(loop)
    |> write_parts(parts)
  end

  defp write_event_handler(encoder, %Model.EventHandler{event_name: name, event_arguments: args}) do
    encoder
    |> write_byte(@ms_event)
    |> write_string(name)
    |> write_map(args)
  end

  defp write_set_state_handler(encoder, %Model.SetStateHandler{state_reference: ref, value: value}) do
    encoder
    |> write_byte(@ms_set_state)
    |> write_value(ref)
    |> write_value(value)
  end

  defp write_constructor_call(encoder, %Model.ConstructorCall{name: name, arguments: arguments}) do
    encoder
    |> write_byte(@ms_widget)
    |> write_string(name)
    |> write_map(arguments)
  end

  defp write_switch(encoder, %Model.Switch{input: input, outputs: outputs}) do
    encoder
    |> write_byte(@ms_switch)
    |> write_value(input)
    |> write_switch_outputs(outputs)
  end

  defp write_args_reference(encoder, %Model.ArgsReference{parts: parts}) do
    encoder
    |> write_byte(@ms_args_reference)
    |> write_parts(parts)
  end

  defp write_data_reference(encoder, %Model.DataReference{parts: parts}) do
    encoder
    |> write_byte(@ms_data_reference)
    |> write_parts(parts)
  end

  defp write_state_reference(encoder, %Model.StateReference{parts: parts}) do
    encoder
    |> write_byte(@ms_state_reference)
    |> write_parts(parts)
  end

  defp write_parts(encoder, parts) do
    encoder
    |> write_int64(length(parts))
    |> (fn e ->
          Enum.reduce(parts, e, fn part, acc ->
            case part do
              part when is_binary(part) or is_integer(part) ->
                write_value(acc, part)

              _ ->
                raise ArgumentError, "Unexpected type #{inspect(part)} while encoding blob."
            end
          end)
        end).()
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

  defp write_library(encoder, %Model.RemoteWidgetLibrary{imports: imports, widgets: widgets}) do
    encoder
    |> write_int64(length(imports))
    |> (fn e -> Enum.reduce(imports, e, &write_import(&2, &1)) end).()
    |> write_int64(length(widgets))
    |> (fn e -> Enum.reduce(widgets, e, &write_widget_declaration(&2, &1)) end).()
  end

  defp write_widget_declaration(encoder, %Model.WidgetDeclaration{
         name: name,
         initial_state: initial_state,
         root: root
       }) do
    encoder
    |> write_string(name)
    |> write_value(initial_state || %{})
    |> write_value(root)
  end

  defp write_import(encoder, %Model.Import{name: %Model.LibraryName{parts: parts}}) do
    encoder
    |> write_int64(length(parts))
    |> (fn e -> Enum.reduce(parts, e, &write_string(&2, &1)) end).()
  end

  defp read_byte(decoder) do
    case read_bytes(decoder, 1) do
      {:ok, {<<byte>>, decoder}} -> {:ok, {byte, decoder}}
      error -> error
    end
  end

  defp read_int64(decoder) do
    case read_bytes(decoder, 8) do
      {:ok, {<<value::little-signed-integer-size(64)>>, decoder}} -> {:ok, {value, decoder}}
      error -> error
    end
  end

  defp read_float64(decoder) do
    case read_bytes(decoder, 8) do
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
      Logger.debug("Reading value of type: #{type}")

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

  defp read_n_values(decoder, n, acc) do
    with {:ok, {value, decoder}} <- read_value(decoder) do
      read_n_values(decoder, n - 1, [value | acc])
    end
  end

  defp read_map(decoder) do
    with {:ok, {length, decoder}} <- read_int64(decoder) do
      read_n_pairs(decoder, length, %{})
    end
  end

  defp read_n_pairs(decoder, 0, acc), do: {:ok, {acc, decoder}}

  defp read_n_pairs(decoder, n, acc) do
    with {:ok, {key, decoder}} <- read_string(decoder),
         {:ok, {value, decoder}} <- read_value(decoder) do
      read_n_pairs(decoder, n - 1, Map.put(acc, key, value))
    end
  end

  defp read_loop(decoder) do
    with {:ok, {input, decoder}} <- read_value(decoder),
         {:ok, {output, decoder}} <- read_value(decoder) do
      {:ok, {%Model.Loop{input: input, output: output}, decoder}}
    end
  end

  defp read_constructor_call(decoder) do
    with {:ok, {name, decoder}} <- read_string(decoder),
         {:ok, {arguments, decoder}} <- read_map(decoder) do
      {:ok, {%Model.ConstructorCall{name: name, arguments: arguments}, decoder}}
    end
  end

  defp read_reference(decoder) do
    with {:ok, {parts, decoder}} <- read_list(decoder) do
      {:ok, {parts, decoder}}
    end
  end

  defp read_args_reference(decoder) do
    with {:ok, {parts, decoder}} <- read_reference(decoder) do
      {:ok, {%Model.ArgsReference{parts: parts}, decoder}}
    end
  end

  defp read_data_reference(decoder) do
    with {:ok, {parts, decoder}} <- read_reference(decoder) do
      {:ok, {%Model.DataReference{parts: parts}, decoder}}
    end
  end

  defp read_loop_reference(decoder) do
    with {:ok, {loop, decoder}} <- read_int64(decoder),
         {:ok, {parts, decoder}} <- read_reference(decoder) do
      {:ok, {%Model.LoopReference{loop: loop, parts: parts}, decoder}}
    end
  end

  defp read_state_reference(decoder) do
    with {:ok, {parts, decoder}} <- read_reference(decoder) do
      {:ok, {%Model.StateReference{parts: parts}, decoder}}
    end
  end

  defp read_event_handler(decoder) do
    with {:ok, {name, decoder}} <- read_string(decoder),
         {:ok, {arguments, decoder}} <- read_map(decoder) do
      {:ok, {%Model.EventHandler{event_name: name, event_arguments: arguments}, decoder}}
    end
  end

  defp read_switch(decoder) do
    with {:ok, {input, decoder}} <- read_value(decoder),
         {:ok, {outputs, decoder}} <- read_switch_outputs(decoder) do
      {:ok, {%Model.Switch{input: input, outputs: outputs}, decoder}}
    end
  end

  defp read_switch_outputs(decoder) do
    with {:ok, {length, decoder}} <- read_int64(decoder) do
      read_n_switch_cases(decoder, length, %{})
    end
  end

  defp read_n_switch_cases(decoder, 0, acc), do: {:ok, {acc, decoder}}

  defp read_n_switch_cases(decoder, n, acc) do
    with {:ok, {key, decoder}} <- read_switch_key(decoder),
         {:ok, {value, decoder}} <- read_value(decoder) do
      read_n_switch_cases(decoder, n - 1, Map.put(acc, key, value))
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
    with {:ok, {state_reference, decoder}} <- read_value(decoder),
         {:ok, {value, decoder}} <- read_value(decoder) do
      {:ok,
       {%Model.SetStateHandler{
          state_reference: state_reference,
          value: value
        }, decoder}}
    end
  end

  defp read_widget_builder_declaration(decoder) do
    with {:ok, {arg_name, decoder}} <- read_string(decoder),
         {:ok, {widget, decoder}} <- read_value(decoder) do
      case widget do
        %Model.ConstructorCall{} ->
          {:ok,
           {%Model.WidgetBuilderDeclaration{argument_name: arg_name, widget: widget}, decoder}}

        %Model.Switch{} ->
          {:ok,
           {%Model.WidgetBuilderDeclaration{argument_name: arg_name, widget: widget}, decoder}}

        _ ->
          {:error, "Invalid widget type in widget builder declaration"}
      end
    end
  end

  defp read_widget_builder_arg_reference(decoder) do
    with {:ok, {arg_name, decoder}} <- read_string(decoder),
         {:ok, {parts, decoder}} <- read_reference(decoder) do
      {:ok, {%Model.WidgetBuilderArgReference{argument_name: arg_name, parts: parts}, decoder}}
    end
  end

  defp read_library(decoder) do
    with {:ok, {imports, decoder}} <- read_import_list(decoder),
         {:ok, {widgets, decoder}} <- read_declaration_list(decoder) do
      library = %Model.RemoteWidgetLibrary{imports: imports, widgets: widgets}
      Logger.debug("Read library: #{inspect(library, pretty: true)}")
      {:ok, {library, decoder}}
    end
  end

  defp read_import_list(decoder) do
    with {:ok, {length, decoder}} <- read_int64(decoder) do
      read_n_imports(decoder, length, [])
    end
  end

  defp read_n_imports(decoder, 0, acc), do: {:ok, {Enum.reverse(acc), decoder}}

  defp read_n_imports(decoder, n, acc) do
    with {:ok, {import, decoder}} <- read_import(decoder) do
      read_n_imports(decoder, n - 1, [import | acc])
    end
  end

  defp read_import(decoder) do
    with {:ok, {parts, decoder}} <- read_list(decoder) do
      {:ok, {%Model.Import{name: %Model.LibraryName{parts: parts}}, decoder}}
    end
  end

  defp read_declaration_list(decoder) do
    with {:ok, {length, decoder}} <- read_int64(decoder) do
      read_n_declarations(decoder, length, [])
    end
  end

  defp read_n_declarations(decoder, 0, acc), do: {:ok, {Enum.reverse(acc), decoder}}

  defp read_n_declarations(decoder, n, acc) do
    with {:ok, {declaration, decoder}} <- read_declaration(decoder) do
      read_n_declarations(decoder, n - 1, [declaration | acc])
    end
  end

  defp read_declaration(decoder) do
    with {:ok, {name, decoder}} <- read_string(decoder),
         {:ok, {initial_state, decoder}} <- read_map(decoder),
         {:ok, {root, decoder}} <- read_value(decoder) do
      {:ok,
       {%Model.WidgetDeclaration{name: name, initial_state: initial_state, root: root}, decoder}}
    end
  end

  defp read_bytes(%{bytes: bytes, cursor: cursor} = decoder, length) do
    if cursor + length > byte_size(bytes) do
      Logger.error(
        "Attempted to read #{length} bytes at offset #{cursor}, but only #{byte_size(bytes) - cursor} bytes available"
      )

      {:error, "Could not read #{length} bytes at offset #{cursor}: unexpected end of file."}
    else
      data = binary_part(bytes, cursor, length)
      {:ok, {data, %{decoder | cursor: cursor + length}}}
    end
  end
end
