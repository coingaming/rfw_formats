defmodule RfwFormats.Text do
  @moduledoc """
  Provides functions for parsing Remote Flutter Widgets text data files and library files.
  """

  import NimbleParsec

  alias RfwFormats.Model

  # Line Comment: // comment until end of line
  line_comment =
    ignore(string("//"))
    |> repeat(lookahead_not(ascii_char([?\n])) |> utf8_char([]))
    |> optional(ascii_char([?\n]))

  # Block Comment: /* comment */
  block_comment =
    ignore(string("/*"))
    |> repeat(lookahead_not(string("*/")) |> utf8_char([]))
    |> ignore(string("*/"))

  # Basic whitespace characters
  whitespace_char = ascii_char([?\s, ?\n, ?\r, ?\t])

  # Combined whitespace including comments
  whitespace =
    repeat(
      choice([
        whitespace_char,
        line_comment,
        block_comment
      ])
    )

  integer =
    optional(ascii_char([?-]))
    |> concat(
      choice([
        string("0x")
        |> ascii_string([?0..?9, ?a..?f, ?A..?F], min: 1),
        ascii_string([?0..?9], min: 1)
        |> lookahead_not(ascii_char([?., ?e, ?E]))
      ])
    )
    |> reduce({List, :to_string, []})
    |> map({:parse_integer, []})

  defp parse_integer("0x" <> hex), do: String.to_integer(hex, 16)
  defp parse_integer(str), do: String.to_integer(str)

  identifier =
    ascii_char([?a..?z, ?A..?Z, ?_])
    |> repeat(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))
    |> reduce({List, :to_string, []})

  float =
    optional(ascii_char([?-]))
    |> ascii_string([?0..?9], min: 1)
    |> choice([
      # Decimal point and fractional part, with optional exponent
      string(".")
      |> ascii_string([?0..?9], min: 1)
      |> optional(
        choice([string("e"), string("E")])
        |> optional(ascii_char([?+, ?-]))
        |> ascii_string([?0..?9], min: 1)
      ),
      # Exponent without decimal point
      choice([string("e"), string("E")])
      |> optional(ascii_char([?+, ?-]))
      |> ascii_string([?0..?9], min: 1)
    ])
    |> reduce({List, :to_string, []})
    |> map({:parse_float, []})

  defp parse_float(str) do
    {float, ""} = Float.parse(str)
    float
  end

  double_string_literal =
    ignore(ascii_char([?"]))
    |> repeat(
      lookahead_not(ascii_char([?"]))
      |> choice([
        ignore(string("\\u"))
        |> utf8_string([?0..?9, ?a..?f, ?A..?F], 4)
        |> map({:parse_unicode_escape, []}),
        string("\\\"") |> replace(?"),
        string("\\\\") |> replace(?\\),
        string("\\/") |> replace(?/),
        string("\\'") |> replace(?'),
        string("\\b") |> replace(?\b),
        string("\\f") |> replace(?\f),
        string("\\n") |> replace(?\n),
        string("\\r") |> replace(?\r),
        string("\\t") |> replace(?\t),
        utf8_char([])
      ])
    )
    |> ignore(ascii_char([?"]))
    |> reduce({:erlang, :list_to_binary, []})

  single_string_literal =
    ignore(ascii_char([?']))
    |> repeat(
      lookahead_not(ascii_char([?']))
      |> choice([
        ignore(string("\\u"))
        |> utf8_string([?0..?9, ?a..?f, ?A..?F], 4)
        |> map({:parse_unicode_escape, []}),
        string("\\\"") |> replace(?"),
        string("\\\\") |> replace(?\\),
        string("\\/") |> replace(?/),
        string("\\'") |> replace(?'),
        string("\\b") |> replace(?\b),
        string("\\f") |> replace(?\f),
        string("\\n") |> replace(?\n),
        string("\\r") |> replace(?\r),
        string("\\t") |> replace(?\t),
        utf8_char([])
      ])
    )
    |> ignore(ascii_char([?']))
    |> reduce({:erlang, :list_to_binary, []})

  # Combined String Literal Combinator
  string_literal =
    choice([
      double_string_literal,
      single_string_literal
    ])

  true_literal = string("true") |> replace(true)
  false_literal = string("false") |> replace(false)
  null_literal = string("null") |> replace(:__null__)

  boolean = choice([true_literal, false_literal])

  value =
    choice([
      boolean,
      null_literal,
      integer,
      float,
      string_literal,
      parsec(:list),
      parsec(:map),
      parsec(:loop),
      parsec(:switch),
      parsec(:args_reference),
      parsec(:data_reference),
      parsec(:state_reference),
      parsec(:event_handler),
      parsec(:set_state_handler),
      parsec(:widget_builder)
    ])

  list =
    ignore(string("["))
    |> ignore(whitespace)
    |> wrap(
      optional(
        parsec(:value)
        |> repeat(
          ignore(whitespace)
          |> ignore(string(","))
          |> ignore(whitespace)
          |> parsec(:value)
        )
      )
    )
    |> ignore(whitespace)
    |> ignore(string("]"))

  map =
    ignore(string("{"))
    |> ignore(whitespace)
    |> wrap(
      optional(
        choice([string_literal, identifier])
        |> ignore(whitespace)
        |> ignore(string(":"))
        |> ignore(whitespace)
        |> parsec(:value)
        |> repeat(
          ignore(whitespace)
          |> ignore(string(","))
          |> ignore(whitespace)
          |> choice([string_literal, identifier])
          |> ignore(whitespace)
          |> ignore(string(":"))
          |> ignore(whitespace)
          |> parsec(:value)
        )
      )
    )
    |> ignore(whitespace)
    |> ignore(string("}"))
    |> map({:create_map, []})

  defp create_map([]), do: %{}

  defp create_map(pairs) do
    Enum.chunk_every(pairs, 2)
    |> Enum.reduce(%{}, fn
      [_k, :__null__], acc -> acc
      [k, v], acc -> Map.put(acc, k, wrap_value(k, v))
    end)
  end

  # Helper to wrap certain values in lists when needed
  defp wrap_value(_key, %Model.Loop{} = v), do: [v]
  defp wrap_value(_key, v), do: v

  loop =
    ignore(string("...for"))
    |> ignore(whitespace)
    |> concat(identifier)
    |> ignore(whitespace)
    |> ignore(string("in"))
    |> ignore(whitespace)
    |> parsec(:value)
    |> ignore(string(":"))
    |> ignore(whitespace)
    |> parsec(:value)
    |> wrap()
    |> map({:create_loop, []})

  defp create_loop([_identifier, input, output]) do
    Model.new_loop(input, output)
  end

  dot_separated_parts =
    times(
      ignore(string("."))
      |> choice([
        integer,
        string_literal,
        identifier
      ]),
      min: 1
    )

  switch =
    ignore(string("switch"))
    |> ignore(whitespace)
    |> parsec(:value)
    |> ignore(whitespace)
    |> ignore(string("{"))
    |> ignore(whitespace)
    |> times(
      choice([
        ignore(string("default"))
        |> replace(nil),
        parsec(:value)
      ])
      |> ignore(string(":"))
      |> ignore(whitespace)
      |> parsec(:value)
      |> ignore(whitespace)
      |> optional(string(",")),
      min: 1
    )
    |> ignore(string("}"))
    |> map({:create_switch, []})

  defp create_switch([input | cases]) do
    Model.new_switch(input, create_map(cases))
  end

  args_reference =
    string("args")
    |> concat(dot_separated_parts)
    |> map({:create_args_reference, []})

  defp create_args_reference([_ | parts]) do
    Model.new_args_reference(parts)
  end

  data_reference =
    string("data")
    |> concat(dot_separated_parts)
    |> map({:create_data_reference, []})

  defp create_data_reference([_ | parts]) do
    Model.new_data_reference(parts)
  end

  state_reference =
    string("state")
    |> concat(dot_separated_parts)
    |> wrap()
    |> map({:create_state_reference, []})

  defp create_state_reference([_ | parts]) do
    Model.new_state_reference(parts)
  end

  event_handler =
    ignore(string("event"))
    |> ignore(whitespace)
    |> concat(string_literal)
    |> ignore(whitespace)
    |> concat(map)
    |> wrap()
    |> map({:create_event_handler, []})

  defp create_event_handler([event_name, event_arguments]) do
    Model.new_event_handler(event_name, event_arguments)
  end

  set_state_handler =
    ignore(string("set"))
    |> ignore(whitespace)
    |> concat(state_reference)
    |> ignore(whitespace)
    |> ignore(string("="))
    |> ignore(whitespace)
    |> parsec(:value)
    |> wrap()
    |> map({:create_set_state_handler, []})

  defp create_set_state_handler([state_reference, value]) do
    Model.new_set_state_handler(state_reference, value)
  end

  import_statement =
    ignore(string("import"))
    |> ignore(whitespace)
    |> wrap(
      times(
        choice([identifier, string_literal])
        |> ignore(optional(string("."))),
        min: 1
      )
    )
    |> ignore(string(";"))
    |> map({:create_import, []})

  defp create_import(parts) do
    parts = Enum.filter(parts, &(&1 != nil))
    library_name = Model.new_library_name(parts)
    Model.new_import(library_name)
  end

  widget_declaration =
    ignore(string("widget"))
    |> ignore(whitespace)
    |> concat(identifier)
    |> ignore(whitespace)
    |> optional(
      map
      |> wrap()
    )
    |> ignore(whitespace)
    |> ignore(string("="))
    |> ignore(whitespace)
    |> choice([
      parsec(:constructor_call),
      parsec(:switch)
    ])
    |> ignore(string(";"))
    |> reduce({:assemble_widget_declaration_args, []})
    |> map({:create_widget_declaration, []})

  defp create_widget_declaration([name, initial_state, root]) do
    Model.new_widget_declaration(name, initial_state, root)
  end

  defp assemble_widget_declaration_args([name, initial_state_list, root]) do
    initial_state =
      case initial_state_list do
        [state] -> state
        nil -> %{}
      end

    [name, initial_state, root]
  end

  defp assemble_widget_declaration_args([name, root]) do
    [name, %{}, root]
  end

  widget_builder =
    ignore(string("Builder"))
    |> ignore(whitespace)
    |> ignore(string("("))
    |> ignore(whitespace)
    |> ignore(string("builder"))
    |> ignore(whitespace)
    |> ignore(string(":"))
    |> ignore(whitespace)
    |> ignore(string("("))
    |> concat(identifier)
    |> ignore(string(")"))
    |> ignore(whitespace)
    |> ignore(string("=>"))
    |> ignore(whitespace)
    |> parsec(:value)
    |> ignore(whitespace)
    |> ignore(string(")"))
    |> map({:create_widget_builder, []})

  defp create_widget_builder([arg_name, body]) do
    Model.new_widget_builder_declaration(arg_name, body)
  end

  constructor_call =
    identifier
    |> ignore(string("("))
    |> ignore(whitespace)
    |> optional(
      parsec(:constructor_argument)
      |> repeat(
        ignore(whitespace)
        |> ignore(string(","))
        |> ignore(whitespace)
        |> parsec(:constructor_argument)
      )
    )
    |> reduce({:assemble_constructor_call_args, []})
    |> ignore(whitespace)
    |> ignore(string(")"))
    |> map({:create_constructor_call, []})

  defp create_constructor_call([name | args]) do
    arguments = create_map(args)
    Model.new_constructor_call(name, arguments)
  end

  constructor_argument =
    identifier
    |> ignore(string(":"))
    |> ignore(whitespace)
    |> parsec(:value)
    |> wrap()
    |> reduce({List, :flatten, []})

  defp assemble_constructor_call_args([name]) do
    [name]
  end

  defp assemble_constructor_call_args([name, args]) do
    args = List.flatten(args)
    [name | args]
  end

  library =
    ignore(whitespace)
    |> wrap(repeat(import_statement |> ignore(whitespace)))
    |> wrap(repeat(widget_declaration |> ignore(whitespace)))
    |> ignore(whitespace)
    |> eos()

  defcombinatorp(:value, value)
  defcombinatorp(:list, list)
  defcombinatorp(:map, map)
  defcombinatorp(:loop, loop)
  defcombinatorp(:switch, switch)
  defcombinatorp(:args_reference, args_reference)
  defcombinatorp(:data_reference, data_reference)
  defcombinatorp(:state_reference, state_reference)
  defcombinatorp(:event_handler, event_handler)
  defcombinatorp(:set_state_handler, set_state_handler)
  defcombinatorp(:widget_builder, widget_builder)
  defcombinatorp(:constructor_call, constructor_call)
  defcombinatorp(:constructor_argument, constructor_argument)

  defparsecp(:do_parse_library_file, library)

  defparsecp(
    :do_parse_data_file,
    ignore(whitespace)
    |> concat(map)
    |> ignore(whitespace)
    |> eos()
  )

  defp parse_unicode_escape(hex) do
    code_point = String.to_integer(hex, 16)

    cond do
      # Code points up to U+D7FF are valid Unicode scalar values and can be encoded as UTF-8
      code_point <= 0xD7FF ->
        <<code_point::utf8>>

      # Code points from U+D800 to U+FFFF should be output as 16-bit code units
      code_point <= 0xFFFF ->
        <<code_point::16>>

      # Code points above U+FFFF are invalid in this context
      true ->
        raise "Invalid code point in Unicode escape sequence: #{hex}"
    end
  end

  @doc """
  Parse a Remote Flutter Widgets text data file.
  """
  @spec parse_data_file(binary()) :: Model.dynamic_map() | no_return()
  def parse_data_file(input) do
    case do_parse_data_file(input) do
      {:ok, [result], "", _, {_, _}, _} ->
        result

      {:error, reason, rest, _, {line, col}, _} ->
        raise __MODULE__.ParserException, {reason, rest, line, col}

      other ->
        raise __MODULE__.ParserException, {"Unexpected parser result", inspect(other), 0, 0}
    end
  end

  @doc """
  Parses a Remote Flutter Widgets text library file.
  """
  @spec parse_library_file(binary(), keyword()) :: Model.RemoteWidgetLibrary.t() | no_return()
  def parse_library_file(input, _opts \\ []) do
    case do_parse_library_file(input) do
      {:ok, [imports, widgets], "", _, {_, _}, _} ->
        Model.new_remote_widget_library(imports, widgets)

      {:error, reason, rest, _, {line, col}, _} ->
        raise __MODULE__.ParserException, {reason, rest, line, col}

      other ->
        raise __MODULE__.ParserException, {"Unexpected parser result", inspect(other), 0, 0}
    end
  end

  defmodule ParserException do
    defexception [:message, :rest, :line, :column]

    @impl true
    def exception({message, rest, line, column}) do
      %__MODULE__{
        message: message,
        rest: rest,
        line: line,
        column: column
      }
    end

    @impl true
    def message(%{message: message, rest: rest, line: line, column: column}) do
      "#{inspect(message)} at line #{line}, column #{column}. Remaining input: #{inspect(rest)}"
    end
  end
end
