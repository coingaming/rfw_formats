defmodule RfwFormats.Text do
  @moduledoc """
  Provides functions for parsing Remote Flutter Widgets text data files and library files.
  """

  import NimbleParsec

  alias RfwFormats.{Model, OrderedMap}

  @reserved_words ~w(args data event false set state true)

  defp check_reserved_word(identifier, {line, _} = _location, rest) do
    if identifier in @reserved_words do
      raise __MODULE__.Error, {"#{identifier} is a reserved word", rest, line}
    end
  end

  defmodule Context do
    defstruct loop_vars: [], scope_type: nil, widget_args: []

    def new do
      %__MODULE__{}
    end

    def push_loop_var(%__MODULE__{} = ctx, var_name) do
      %__MODULE__{ctx | loop_vars: [var_name | ctx.loop_vars]}
    end

    def pop_loop_var(%__MODULE__{} = ctx) do
      %__MODULE__{ctx | loop_vars: tl(ctx.loop_vars)}
    end

    def get_loop_var_index(ctx, var_name) do
      # Find the index of the variable in the loop_vars list
      case Enum.find_index(ctx.loop_vars, &(&1 == var_name)) do
        nil -> {:error, :variable_not_found}
        index -> {:ok, index}
      end
    end
  end

  defmodule Error do
    defexception [:message, :rest, :line]

    @impl true
    def message(%{message: message}), do: message

    def exception({message, rest, line}) do
      %__MODULE__{
        message: "#{message} at line #{line}",
        rest: rest,
        line: line
      }
    end

    def exception({message, rest, _context, {line, _}, _}) do
      %__MODULE__{
        message: "#{message} at line #{line}",
        rest: rest,
        line: line
      }
    end
  end

  # Line Comment: // comment until end of line
  line_comment =
    ignore(string("//"))
    |> repeat(lookahead_not(ascii_char([?\n])) |> utf8_char([]))
    |> optional(ascii_char([?\n]))
    |> label("line comment")

  # Block Comment: /* comment */
  block_comment =
    ignore(string("/*"))
    |> repeat(lookahead_not(string("*/")) |> utf8_char([]))
    |> ignore(string("*/"))
    |> label("block comment")

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
        |> ascii_string([?0..?9, ?a..?f, ?A..?F], min: 1)
        |> label("hexadecimal number"),
        ascii_string([?0..?9], min: 1)
        |> lookahead_not(ascii_char([?., ?e, ?E]))
      ])
    )
    |> reduce({List, :to_string, []})
    |> map({:parse_integer, []})
    |> label("integer")

  defp parse_integer("0x" <> hex), do: String.to_integer(hex, 16)
  defp parse_integer(str), do: String.to_integer(str)

  identifier =
    ascii_char([?a..?z, ?A..?Z, ?_])
    |> repeat(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))
    |> reduce({List, :to_string, []})
    |> label("identifier")

  float =
    optional(ascii_char([?-]))
    |> ascii_string([?0..?9], min: 1)
    |> choice([
      string(".")
      |> ascii_string([?0..?9], min: 1)
      |> optional(
        choice([string("e"), string("E")])
        |> optional(ascii_char([?+, ?-]))
        |> ascii_string([?0..?9], min: 1)
      ),
      choice([string("e"), string("E")])
      |> optional(ascii_char([?+, ?-]))
      |> ascii_string([?0..?9], min: 1)
    ])
    |> reduce({List, :to_string, []})
    |> map({:parse_float, []})
    |> label("float")

  defp parse_float(str) do
    {float, ""} = Float.parse(str)
    float
  end

  string_escape_sequence =
    choice([
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
    |> label("escape sequence")

  defp parse_unicode_escape(hex) do
    # Convert hex string to integer, handling both uppercase and lowercase
    code_point =
      hex
      |> String.downcase()
      |> String.to_integer(16)

    cond do
      code_point <= 0xD7FF ->
        <<code_point::utf8>>

      code_point <= 0xFFFF ->
        <<code_point::16>>

      true ->
        raise "Invalid code point in Unicode escape sequence: #{hex}"
    end
  end

  double_string_literal =
    ignore(ascii_char([?"]))
    |> repeat(
      lookahead_not(ascii_char([?"]))
      |> parsec(:string_escape_sequence)
    )
    |> ignore(ascii_char([?"]))
    |> reduce({:erlang, :list_to_binary, []})
    |> label("double quoted string")

  single_string_literal =
    ignore(ascii_char([?']))
    |> repeat(
      lookahead_not(ascii_char([?']))
      |> parsec(:string_escape_sequence)
    )
    |> ignore(ascii_char([?']))
    |> reduce({:erlang, :list_to_binary, []})
    |> label("single quoted string")

  string_literal =
    choice([
      double_string_literal,
      single_string_literal
    ])

  true_literal = string("true") |> replace(true) |> label("true")
  false_literal = string("false") |> replace(false) |> label("false")
  null_literal = string("null") |> replace(:__null__) |> label("null")

  boolean = choice([true_literal, false_literal]) |> label("boolean")

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
    |> label("dot separated parts")

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
        lookahead_not(string("null"))
        |> parsec(:value)
        |> repeat(
          ignore(whitespace)
          |> ignore(string(","))
          |> ignore(whitespace)
          |> lookahead_not(string("null"))
          |> parsec(:value)
        )
        |> optional(
          ignore(whitespace)
          |> ignore(string(","))
          |> ignore(whitespace)
        )
      )
    )
    |> ignore(whitespace)
    |> ignore(string("]"))
    |> label("list")

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
        |> optional(
          ignore(whitespace)
          |> ignore(string(","))
          |> ignore(whitespace)
        )
      )
    )
    |> ignore(whitespace)
    |> ignore(string("}"))
    |> map({:create_map, []})
    |> label("map")

  defp create_map([]), do: OrderedMap.new()

  defp create_map(pairs) do
    chunked = Enum.chunk_every(pairs, 2)

    Enum.reduce(chunked, OrderedMap.new(), fn pair, acc ->
      case pair do
        [_k, :__null__] -> acc
        [k, v] -> OrderedMap.put(acc, k, v)
      end
    end)
  end

  loop =
    ignore(string("...for"))
    |> ignore(whitespace)
    |> unwrap_and_tag(identifier, :loop_var)
    |> ignore(whitespace)
    |> ignore(string("in"))
    |> ignore(whitespace)
    |> lookahead_not(string("null"))
    |> tag(parsec(:value), :input)
    |> ignore(string(":"))
    |> ignore(whitespace)
    |> post_traverse({:push_loop_var, []})
    |> tag(parsec(:value), :output)
    |> post_traverse({:pop_loop_var, []})
    |> wrap()
    |> map({:create_loop, []})
    |> label("loop")

  loop_var =
    identifier
    |> unwrap_and_tag(:var_name)
    |> optional(
      dot_separated_parts
      |> unwrap_and_tag(:parts)
    )
    |> post_traverse({:check_loop_var, []})
    |> label("loop variable")

  defp push_loop_var(rest, args, context, location, _offset) do
    var_name = Keyword.get(args, :loop_var)
    check_reserved_word(var_name, location, rest)

    ctx =
      case context do
        %Context{} -> context
        _ -> Context.new()
      end

    context = Context.push_loop_var(ctx, var_name)
    {rest, args, context}
  end

  defp pop_loop_var(rest, args, context, _line, _offset) do
    ctx =
      case context do
        %Context{} -> Context.pop_loop_var(context)
        _ -> Context.new()
      end

    {rest, args, ctx}
  end

  defp check_loop_var(rest, parsed, context, _location, _offset) do
    var_name = Keyword.get(parsed, :var_name)
    raw_parts = Keyword.get(parsed, :parts, [])
    parts = List.flatten([raw_parts])

    ctx =
      case context do
        %Context{} -> context
        _ -> Context.new()
      end

    cond do
      ctx.scope_type == :widget_builder && var_name in (ctx.widget_args || []) ->
        ref = Model.new_widget_builder_arg_reference(var_name, parts)
        {rest, [ref], ctx}

      true ->
        case Enum.find_index(ctx.loop_vars, fn var -> var == var_name end) do
          nil ->
            {rest, [var_name], ctx}

          index ->
            final_index = if var_name == hd(ctx.loop_vars), do: 0, else: index

            loop_ref = Model.new_loop_reference(final_index, parts)
            {rest, [loop_ref], ctx}
        end
    end
  end

  defp create_loop([{:loop_var, _identifier}, {:input, [input]}, {:output, [output]}]) do
    Model.new_loop(input, output)
  end

  switch =
    ignore(string("switch"))
    |> ignore(whitespace)
    |> lookahead_not(string("null"))
    |> unwrap_and_tag(parsec(:value), :input)
    |> ignore(whitespace)
    |> ignore(string("{"))
    |> ignore(whitespace)
    |> tag(
      times(
        choice([
          ignore(string("default"))
          |> replace(nil),
          parsec(:value)
        ])
        |> ignore(whitespace)
        |> ignore(string(":"))
        |> ignore(whitespace)
        |> lookahead_not(string("null"))
        |> parsec(:value)
        |> wrap()
        |> ignore(whitespace)
        |> optional(ignore(string(",")))
        |> ignore(whitespace),
        min: 1
      ),
      :cases
    )
    |> post_traverse({:validate_switch_cases_traverse, []})
    |> ignore(whitespace)
    |> ignore(string("}"))
    |> wrap()
    |> map({:create_switch, []})
    |> label("switch statement")

  defp validate_switch_cases_traverse(
         rest,
         [{:cases, cases}, {:input, input}],
         context,
         {line, _col},
         _offset
       ) do
    Enum.reduce(cases, {false, MapSet.new()}, fn [key, _value], {has_default, keys} ->
      cond do
        key == nil and has_default ->
          raise __MODULE__.Error, {"Switch has multiple default cases", rest, line}

        key == nil ->
          {true, keys}

        MapSet.member?(keys, key) ->
          raise __MODULE__.Error,
                {"Switch has duplicate cases for key #{inspect(key)}", rest, line}

        true ->
          {has_default, MapSet.put(keys, key)}
      end
    end)

    {rest, [{:cases, cases}, {:input, input}], context}
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
    |> label("args reference")

  defp create_args_reference([_ | parts]) do
    Model.new_args_reference(List.flatten(parts))
  end

  data_reference =
    string("data")
    |> concat(dot_separated_parts)
    |> wrap()
    |> map({:create_data_reference, []})
    |> label("data reference")

  defp create_data_reference([_ | parts]) do
    Model.new_data_reference(List.flatten(parts))
  end

  state_reference =
    string("state")
    |> concat(dot_separated_parts)
    |> wrap()
    |> map({:create_state_reference, []})
    |> label("state reference")

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
    |> label("event handler")

  defp create_event_handler([event_name, event_arguments]) when is_binary(event_name) do
    # Adding spec and guard to ensure local return
    processed_args = process_widget_builder_refs(event_arguments)
    Model.new_event_handler(event_name, processed_args)
  end

  set_state_handler =
    ignore(string("set"))
    |> ignore(whitespace)
    |> concat(state_reference)
    |> ignore(whitespace)
    |> ignore(string("="))
    |> ignore(whitespace)
    |> lookahead_not(string("null"))
    |> parsec(:value)
    |> wrap()
    |> map({:create_set_state_handler, []})
    |> label("set state handler")

  defp create_set_state_handler([state_reference, value]) do
    Model.new_set_state_handler(state_reference, value)
  end

  import_statement =
    ignore(string("import"))
    |> ignore(whitespace)
    |> wrap(
      times(
        choice([identifier, string_literal])
        |> label("string or identifier")
        |> ignore(optional(string("."))),
        min: 1
      )
    )
    |> ignore(string(";"))
    |> map({:create_import, []})
    |> label("import statement")

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
    |> label("constructor call or switch statement")

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
    |> label("widget declaration")

  defp create_widget_declaration([name, initial_state, root]) do
    Model.new_widget_declaration(name, initial_state, root)
  end

  defp assemble_widget_declaration_args([name, initial_state_list, root]) do
    initial_state =
      case initial_state_list do
        [state] -> state
        nil -> nil
      end

    [name, initial_state, root]
  end

  defp assemble_widget_declaration_args([name, root]) do
    [name, nil, root]
  end

  widget_builder =
    ignore(string("("))
    |> ignore(whitespace)
    |> concat(identifier)
    |> post_traverse({:push_widget_arg, []})
    |> ignore(string(")"))
    |> ignore(whitespace)
    |> ignore(string("=>"))
    |> ignore(whitespace)
    |> lookahead_not(string("null"))
    |> parsec(:value)
    |> post_traverse({:validate_widget_builder_value, []})
    |> post_traverse({:pop_widget_arg, []})
    |> ignore(whitespace)
    |> optional(ignore(string(",")))
    |> ignore(whitespace)
    |> wrap()
    |> map({:create_widget_builder, []})
    |> label("widget builder")

  defp process_widget_builder_refs(%OrderedMap{map: map, keys: keys}) do
    processed_map =
      Map.new(map, fn
        {k, %{scope_type: :widget_builder, var_name: name, parts: parts}} ->
          {k, Model.new_widget_builder_arg_reference(name, parts)}

        {k, v} ->
          {k, v}
      end)

    %OrderedMap{
      map: processed_map,
      keys: keys
    }
  end

  defp process_widget_builder_refs(other), do: other

  defp validate_widget_builder_value(rest, [value | _] = args, context, {line, _}, _offset) do
    case value do
      %Model.ConstructorCall{} ->
        {rest, args, context}

      %Model.Switch{} ->
        {rest, args, context}

      _ ->
        raise __MODULE__.Error, {
          "Expecting a switch or constructor call got #{inspect(value)}",
          rest,
          line
        }
    end
  end

  defp push_widget_arg(rest, [arg_name], context, location, _offset) do
    check_reserved_word(arg_name, location, rest)

    ctx =
      case context do
        %Context{} ->
          %Context{
            context
            | scope_type: :widget_builder,
              widget_args: [arg_name | context.widget_args || []],
              # Preserve existing loop vars
              loop_vars: context.loop_vars
          }

        _ ->
          %Context{
            scope_type: :widget_builder,
            widget_args: [arg_name],
            loop_vars: []
          }
      end

    {rest, [arg_name], ctx}
  end

  defp pop_widget_arg(rest, args, context, _line, _offset) do
    {rest, args, Map.update(context, :widget_args, [], &tl(&1))}
  end

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
      |> optional(
        ignore(whitespace)
        |> ignore(string(","))
        |> ignore(whitespace)
      )
    )
    |> reduce({:assemble_constructor_call_args, []})
    |> ignore(whitespace)
    |> ignore(string(")"))
    |> map({:create_constructor_call, []})
    |> label("constructor call")

  defp assemble_constructor_call_args([name | args]) do
    args =
      Enum.flat_map(args, fn
        [key, value] -> [key, value]
        other -> other
      end)

    [name | args]
  end

  defp create_constructor_call([name | args]) do
    arguments = create_map(args)
    Model.new_constructor_call(name, arguments)
  end

  constructor_argument =
    identifier
    |> ignore(string(":"))
    |> ignore(whitespace)
    |> lookahead_not(string("null"))
    |> parsec(:value)
    |> wrap()
    |> ignore(whitespace)
    |> label("constructor argument")

  library =
    ignore(whitespace)
    |> repeat(import_statement |> ignore(whitespace))
    |> repeat(widget_declaration |> ignore(whitespace))
    |> ignore(whitespace)
    |> post_traverse({:build_library, []})

  defp build_library(rest, parts, context, _line, _offset) do
    parts = Enum.reverse(parts)

    parts =
      Enum.filter(parts, fn
        %Model.Import{} -> true
        %Model.WidgetDeclaration{} -> true
        _ -> false
      end)

    {imports, widgets} =
      Enum.split_with(parts, fn
        %Model.Import{} -> true
        _ -> false
      end)

    result = Model.new_remote_widget_library(imports, widgets)
    {rest, [result], context}
  end

  defcombinatorp(:value, value)
  defcombinatorp(:string_escape_sequence, string_escape_sequence)
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
  )

  defp handle_parse_result({:ok, [result], "", _, _, _}, _) do
    result
  end

  defp handle_parse_result({:error, message, rest, context, location, offset}, _) do
    raise Error, {message, rest, context, location, offset}
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
