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

  defp string_to_integer(str), do: String.to_integer(str)

  dot_separated_parts =
    times(
      ignore(string("."))
      |> choice([
        ascii_string([?0..?9], min: 1) |> map({:string_to_integer, []}),
        string_literal,
        identifier
      ]),
      min: 1
    )

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
      parsec(:widget_builder),
      parsec(:constructor_call),
      parsec(:loop_var)
    ])

  list =
    ignore(string("["))
    |> ignore(whitespace)
    |> wrap(
      optional(
        choice([
          # Reference existing loop combinator
          parsec(:loop) |> map({:wrap_loop_in_list, []}),
          parsec(:value)
        ])
        |> debug()
        |> repeat(
          ignore(whitespace)
          |> ignore(string(","))
          |> ignore(whitespace)
          |> choice([
            # Reference existing loop combinator
            parsec(:loop) |> map({:wrap_loop_in_list, []}),
            parsec(:value)
          ])
        )
        |> optional(ignore(string(",")))
      )
    )
    |> debug()
    |> ignore(whitespace)
    |> ignore(string("]"))
    |> map({:process_list_values, []})
    |> debug()

  defp wrap_loop_in_list(loop), do: [loop]

  defp process_list_values(nil), do: []
  defp process_list_values(values) when is_list(values), do: values

  map =
    ignore(string("{"))
    |> ignore(whitespace)
    |> wrap(
      optional(
        choice([string_literal, identifier])
        |> debug()
        |> ignore(whitespace)
        |> ignore(string(":"))
        |> ignore(whitespace)
        |> parsec(:value)
        |> debug()
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

  defp wrap_map_value(_key, value) when is_list(value), do: value
  defp wrap_map_value(_key, %Model.Loop{} = loop), do: [loop]
  defp wrap_map_value(_key, v), do: v

  defp create_map([]), do: %{}

  defp create_map(pairs) do
    Enum.chunk_every(pairs, 2)
    |> Enum.reduce(%{}, fn
      [_k, :__null__], acc -> acc
      [k, v], acc -> Map.put(acc, k, wrap_map_value(k, v))
    end)
  end

  loop_var =
    identifier
    |> unwrap_and_tag(:var_name)
    |> optional(
      dot_separated_parts
      |> unwrap_and_tag(:parts)
    )
    |> post_traverse({:check_loop_var, []})

  defp check_loop_var(rest, parsed, context, _line, _offset) do
    var_name = Keyword.get(parsed, :var_name)
    raw_parts = Keyword.get(parsed, :parts, [])
    parts = if is_list(raw_parts), do: raw_parts, else: [raw_parts]

    cond do
      # Check loop variables first
      index = Enum.find_index(Map.get(context, :loop_vars, []), &(&1 == var_name)) ->
        loop_ref = Model.new_loop_reference(index, parts)
        {rest, [loop_ref], context}

      # Then check widget builder arguments
      var_name in Map.get(context, :widget_args, []) ->
        builder_ref = Model.new_widget_builder_arg_reference(var_name, parts)
        {rest, [builder_ref], context}

      true ->
        {rest, [var_name], context}
    end
  end

  loop =
    ignore(string("...for"))
    |> pre_traverse(:push_loop_context)
    |> ignore(whitespace)
    |> unwrap_and_tag(identifier, :loop_var)
    |> debug()
    |> ignore(whitespace)
    |> ignore(string("in"))
    |> ignore(whitespace)
    |> unwrap_and_tag(parsec(:value), :input)
    |> debug()
    |> ignore(string(":"))
    |> ignore(whitespace)
    |> unwrap_and_tag(parsec(:value), :output)
    |> debug()
    |> post_traverse(:create_loop_with_context)
    |> debug()
    |> post_traverse(:pop_loop_context)
    |> debug()

  defp push_loop_context(rest, args, context, _line, _offset) do
    {rest, args, Map.put(context, :in_loop, true)}
  end

  defp pop_loop_context(rest, args, context, _line, _offset) do
    {rest, args, Map.delete(context, :in_loop)}
  end

  defp create_loop_with_context(rest, args, context, _line, _offset) do
    loop = Model.new_loop(Keyword.get(args, :input), Keyword.get(args, :output))

    result =
      case Map.get(context, :in_loop) do
        true -> [loop]
        _ -> loop
      end

    {rest, [result], context}
  end

  switch =
    ignore(string("switch"))
    |> pre_traverse(:push_switch_context)
    |> ignore(whitespace)
    |> unwrap_and_tag(parsec(:value), :input)
    |> ignore(whitespace)
    |> ignore(string("{"))
    |> ignore(whitespace)
    |> tag(
      times(
        choice([
          ignore(string("default")) |> replace(nil),
          parsec(:value)
        ])
        |> ignore(whitespace)
        |> ignore(string(":"))
        |> ignore(whitespace)
        |> parsec(:value)
        |> post_traverse(:validate_case_value)
        |> wrap()
        |> ignore(whitespace)
        |> optional(ignore(string(",")))
        |> ignore(whitespace),
        min: 1
      ),
      :cases
    )
    |> post_traverse(:pop_switch_context)
    |> ignore(whitespace)
    |> ignore(string("}"))
    |> wrap()
    |> map({:create_switch, []})

  defp push_switch_context(rest, args, context, _line, _offset) do
    updated_context = Map.put(context, :in_switch, true)
    {rest, args, updated_context}
  end

  defp pop_switch_context(rest, args, context, _line, _offset) do
    updated_context = Map.delete(context, :in_switch)
    {rest, args, updated_context}
  end

  defp validate_case_value(rest, [value, case_key], context, line, _offset) do
    case {Map.get(context, :in_widget_builder, false), value} do
      # In widget builder context, enforce widget rules
      {true, %Model.ConstructorCall{}} ->
        {rest, [value, case_key], context}

      {true, %Model.Switch{}} ->
        {rest, [value, case_key], context}

      {true, %Model.WidgetBuilderDeclaration{}} ->
        {rest, [value, case_key], context}

      {true, other} ->
        raise __MODULE__.ParserException,
              {"Invalid widget builder value: #{inspect(other)}", rest, line}

      # Outside widget builder context, allow any value
      {false, _} ->
        {rest, [value, case_key], context}
    end
  end

  defp create_switch(input: input, cases: cases) do
    Model.new_switch(input, create_map(List.flatten(cases)))
  end

  args_reference =
    string("args")
    |> unwrap_and_tag(:args)
    |> concat(dot_separated_parts)
    |> wrap()
    |> map({:create_args_reference, []})

  defp create_args_reference([_ | parts]) do
    Model.new_args_reference(List.flatten(parts))
  end

  data_reference =
    string("data")
    |> concat(dot_separated_parts)
    |> wrap()
    |> map({:create_data_reference, []})

  defp create_data_reference([_ | parts]) do
    Model.new_data_reference(List.flatten(parts))
  end

  state_reference =
    string("state")
    |> concat(dot_separated_parts)
    |> wrap()
    |> map({:create_state_reference, []})

  defp create_state_reference([_ | parts]) do
    Model.new_state_reference(List.flatten(parts))
  end

  event_handler =
    ignore(string("event"))
    |> ignore(whitespace)
    |> concat(string_literal)
    |> ignore(whitespace)
    |> concat(map)
    |> wrap()
    |> map({:create_event_handler, []})

  defp create_event_handler([event_name, event_arguments]) when is_binary(event_name) do
    validated_args = validate_event_arguments(event_arguments)
    Model.new_event_handler(event_name, validated_args)
  end

  defp validate_event_arguments(%{} = args) do
    Enum.reduce(args, %{}, fn
      {key, value}, acc when is_binary(key) ->
        Map.put(acc, key, validate_event_argument_value(value))

      {key, _}, _acc ->
        raise __MODULE__.ParserException,
              {"Event argument key must be a string: #{inspect(key)}", "", 0}
    end)
  end

  defp validate_event_argument_value(value) when is_number(value), do: value
  defp validate_event_argument_value(value) when is_binary(value), do: value
  defp validate_event_argument_value(value) when is_boolean(value), do: value
  defp validate_event_argument_value(%Model.ArgsReference{} = ref), do: ref
  defp validate_event_argument_value(%Model.DataReference{} = ref), do: ref
  defp validate_event_argument_value(%Model.StateReference{} = ref), do: ref
  defp validate_event_argument_value(%Model.LoopReference{} = ref), do: ref
  defp validate_event_argument_value(%Model.WidgetBuilderArgReference{} = ref), do: ref

  defp validate_event_argument_value(invalid) do
    raise __MODULE__.ParserException, {"Invalid event argument value: #{inspect(invalid)}", "", 0}
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

  widget_root =
    choice([
      parsec(:constructor_call),
      parsec(:switch)
    ])

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
    |> concat(widget_root)
    |> reduce({:assemble_widget_declaration_args, []})
    |> map({:create_widget_declaration, []})
    |> ignore(whitespace)
    |> ignore(string(";"))
    |> ignore(whitespace)

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
    ignore(string("("))
    |> ignore(whitespace)
    |> concat(identifier)
    |> debug()
    |> post_traverse({:push_widget_arg, []})
    |> ignore(string(")"))
    |> ignore(whitespace)
    |> ignore(string("=>"))
    |> ignore(whitespace)
    |> parsec(:value)
    |> debug()
    |> post_traverse({:validate_widget_builder_value, []})
    |> post_traverse({:pop_widget_arg, []})
    |> ignore(whitespace)
    |> optional(ignore(string(",")))
    |> ignore(whitespace)
    |> wrap()
    |> map({:create_widget_builder, []})

  defp validate_widget_builder_value(rest, [value | _] = args, context, {line, _}, _offset) do
    case value do
      %Model.ConstructorCall{} ->
        {rest, args, context}

      %Model.Switch{} ->
        {rest, args, context}

      _ ->
        raise __MODULE__.ParserException,
              {"Expecting a switch or constructor call got #{inspect(value)} at line #{line}.",
               rest, line}
    end
  end

  defp push_widget_arg(rest, [arg_name], context, {line, _col}, _offset) do
    if arg_name in ["args", "data", "event", "false", "set", "state", "true"] do
      error_msg = transform_error("#{arg_name} is a reserved word", rest, {line, 0})
      raise __MODULE__.ParserException, {error_msg, rest, line}
    end

    {rest, [arg_name], Map.update(context, :widget_args, [arg_name], &[arg_name | &1])}
  end

  defp pop_widget_arg(rest, args, context, _line, _offset) do
    {rest, args, Map.update(context, :widget_args, [], &tl(&1))}
  end

  defp create_widget_builder([arg_name, body]) do
    Model.new_widget_builder_declaration(arg_name, body)
  end

  constructor_call =
    identifier
    |> debug()
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
      |> debug()
      |> ignore(whitespace)
    )
    |> reduce({:assemble_constructor_call_args, []})
    |> ignore(whitespace)
    |> ignore(string(")"))
    |> map({:create_constructor_call, []})

  defp create_constructor_call([name | args]) do
    arguments =
      args
      |> Enum.chunk_every(2)
      |> Enum.map(fn [k, v] -> {k, v} end)
      |> Enum.into(%{})

    Model.new_constructor_call(name, arguments)
  end

  constructor_argument =
    identifier
    |> ignore(string(":"))
    |> ignore(whitespace)
    |> parsec(:value)
    |> wrap()
    |> ignore(whitespace)

  defp assemble_constructor_call_args([name | args]) when is_list(args) do
    [name | List.flatten(args)]
  end

  library =
    ignore(whitespace)
    |> repeat(import_statement |> ignore(whitespace))
    |> repeat(widget_declaration |> ignore(whitespace))
    |> ignore(whitespace)
    |> post_traverse({:build_library, []})
    |> eos()

  defp build_library(rest, parts, context, _line, _offset) do
    {imports, rest_parts} =
      Enum.split_while(parts, fn
        %Model.Import{} -> true
        _ -> false
      end)

    widgets = rest_parts
    result = Model.new_remote_widget_library(imports, widgets)
    {rest, [result], context}
  end

  defcombinatorp(:value, value)
  defcombinatorp(:list, list)
  defcombinatorp(:map, map)
  defcombinatorp(:loop, loop)
  defcombinatorp(:loop_var, loop_var)
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

  defmodule ParserException do
    defexception [:message, :rest, :line]

    @impl true
    def exception({message, rest, line}) do
      %__MODULE__{
        message: message,
        rest: rest,
        line: line
      }
    end

    @impl true
    def message(%{message: message}), do: message
  end

  # Error handling utilities
  defp format_found_token(<<>>) do
    "<EOF>"
  end

  defp format_found_token(rest) do
    case String.split(rest, "\n") do
      [first | _] -> String.slice(first, 0, 10)
      [] -> ""
    end
  end

  defp extract_context(message) do
    cond do
      String.contains?(message, "after") ->
        "after " <> (String.split(message, "after ") |> List.last())

      String.contains?(message, "inside") ->
        "inside " <> (String.split(message, "inside ") |> List.last())

      String.contains?(message, "in") ->
        "in " <> (String.split(message, "in ") |> List.last())

      true ->
        ""
    end
  end

  defp format_unexpected_char_error(rest) do
    <<char::utf8, _::binary>> = rest
    code = Integer.to_string(char, 16) |> String.upcase() |> String.pad_leading(4, "0")
    {code, <<char::utf8>>}
  end

  defp extract_expected(message) do
    String.replace(message, "expected ", "")
  end

  # Main error transformation
  @semantic_errors [
    "args is a reserved word",
    "Switch has duplicate cases for key 0",
    "Switch has multiple default cases"
  ]

  defp transform_error(message, rest, {line, _col}) when is_binary(message) do
    found_token = format_found_token(rest)

    base_message =
      cond do
        # Keyword errors (import/widget)
        String.contains?(message, "string \"import\" or string \"widget\"") ->
          "Expected keywords \"import\" or \"widget\", or end of file but found #{found_token}"

        # Expected vs found pattern
        String.contains?(message, "expected") ->
          "Expected #{extract_expected(message)} but found #{found_token}"

        # Unexpected character with context
        String.starts_with?(message, "unexpected character") ->
          {code, char} = format_unexpected_char_error(rest)
          context = extract_context(message)
          "Unexpected character U+#{code} (\"#{char}\") #{context}"

        # End of file errors
        String.contains?(message, "end of file") ->
          context =
            case String.split(message, "end of file") do
              [_, ctx] -> String.trim(ctx)
              _ -> ""
            end

          "Unexpected end of file #{context}"

        # Semantic errors
        message in @semantic_errors ->
          "#{message}"

        # Default case
        true ->
          "#{message}"
      end

    "#{base_message} at line #{line}."
  end

  # Unified parse result handler
  defp handle_parse_result(parse_result, parser_type) do
    case parse_result do
      {:ok, [result], "", _, {_, _}, _} ->
        result

      {:ok, _results, rest, _context, {line, _}, _} when parser_type == :library ->
        error_msg = transform_error("expected end of file", rest, {line, 0})
        raise ParserException, {error_msg, rest, line}

      {:error, reason, rest, _, {line, _}, _} ->
        error_msg = transform_error(reason, rest, {line, 0})
        raise ParserException, {error_msg, rest, line}

      _ ->
        raise ParserException, {"Unexpected parser result", "", 0}
    end
  end

  @doc """
  Parse a Remote Flutter Widgets text data file.
  """
  @spec parse_data_file(binary()) :: Model.dynamic_map() | no_return()
  def parse_data_file(input) do
    input
    |> do_parse_data_file()
    |> handle_parse_result(:data)
  end

  @doc """
  Parses a Remote Flutter Widgets text library file.
  """
  @spec parse_library_file(binary(), keyword()) :: Model.RemoteWidgetLibrary.t() | no_return()
  def parse_library_file(input, _opts \\ []) do
    input
    |> do_parse_library_file()
    |> handle_parse_result(:library)
  end
end
