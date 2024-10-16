defmodule RfwFormats.Text do
  @moduledoc """
  Provides functions for parsing Remote Flutter Widgets text data files and library files.
  """

  import NimbleParsec

  alias RfwFormats.Model

  # Helpers

  whitespace = ascii_char([?\s, ?\n, ?\r, ?\t]) |> repeat()

  identifier =
    ascii_char([?a..?z, ?A..?Z, ?_])
    |> repeat(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_]))
    |> reduce({List, :to_string, []})

  integer =
    optional(ascii_char([?-]))
    |> ascii_string([?0..?9], min: 1)
    |> reduce({List, :to_string, []})
    |> map({String, :to_integer, []})

  float =
    optional(ascii_char([?-]))
    |> ascii_string([?0..?9], min: 1)
    |> string(".")
    |> ascii_string([?0..?9], min: 1)
    |> optional(
      choice([
        string("e"),
        string("E")
      ])
      |> optional(ascii_char([?+, ?-]))
      |> ascii_string([?0..?9], min: 1)
    )
    |> reduce({List, :to_string, []})
    |> map({String, :to_float, []})

  string_literal =
    ignore(ascii_char([?"]))
    |> repeat(
      lookahead_not(ascii_char([?"]))
      |> choice([
        string("\\\"") |> replace(?"),
        utf8_char([])
      ])
    )
    |> ignore(ascii_char([?"]))
    |> reduce({List, :to_string, []})

  true_literal = string("true") |> replace(true)
  false_literal = string("false") |> replace(false)
  null_literal = string("null") |> replace(Model.missing())

  boolean = choice([true_literal, false_literal])

  value =
    choice([
      boolean,
      null_literal,
      float,
      integer,
      string_literal,
      parsec(:list),
      parsec(:map)
    ])

  list =
    ignore(string("["))
    |> ignore(whitespace)
    |> optional(
      parsec(:value)
      |> repeat(
        ignore(whitespace)
        |> ignore(string(","))
        |> ignore(whitespace)
        |> parsec(:value)
      )
    )
    |> ignore(whitespace)
    |> ignore(string("]"))

  map =
    ignore(string("{"))
    |> ignore(whitespace)
    |> optional(
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
    |> ignore(whitespace)
    |> ignore(string("}"))
    |> reduce({Enum, :into, [%{}]})

  defcombinatorp(:value, value)
  defcombinatorp(:list, list)
  defcombinatorp(:map, map)

  defparsecp(
    :do_parse_data_file,
    ignore(whitespace)
    |> concat(map)
    |> ignore(whitespace)
    |> eos()
  )

  # Library parsing

  import_statement =
    ignore(string("import"))
    |> ignore(whitespace)
    |> times(
      choice([identifier, string_literal])
      |> ignore(optional(string("."))),
      min: 1
    )
    |> reduce({List, :to_string, []})
    |> ignore(string(";"))
    |> map({:create_import, []})

  widget_declaration =
    ignore(string("widget"))
    |> ignore(whitespace)
    |> concat(identifier)
    |> ignore(whitespace)
    |> optional(map)
    |> ignore(whitespace)
    |> ignore(string("="))
    |> ignore(whitespace)
    |> choice([
      parsec(:constructor_call),
      parsec(:switch_statement)
    ])
    |> ignore(string(";"))
    |> map({:create_widget_declaration, []})

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
    |> ignore(whitespace)
    |> ignore(string(")"))
    |> map({:create_constructor_call, []})

  constructor_argument =
    identifier
    |> ignore(string(":"))
    |> ignore(whitespace)
    |> parsec(:value)

  switch_statement =
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
      |> ignore(whitespace),
      min: 1
    )
    |> ignore(string("}"))
    |> map({:create_switch, []})

  defcombinatorp(:constructor_call, constructor_call)
  defcombinatorp(:constructor_argument, constructor_argument)
  defcombinatorp(:switch_statement, switch_statement)

  library =
    ignore(whitespace)
    |> repeat(import_statement |> ignore(whitespace))
    |> repeat(widget_declaration |> ignore(whitespace))
    |> eos()

  defparsecp(:do_parse_library_file, library)

  @doc """
  Parse a Remote Flutter Widgets text data file.
  """
  def parse_data_file(input) do
    case do_parse_data_file(input) do
      {:ok, [result], "", _, _, _} ->
        result

      {:error, reason, rest, _, line, col} ->
        raise __MODULE__.ParserException, {reason, rest, line, col}
    end
  end

  @doc """
  Parses a Remote Flutter Widgets text library file.
  """
  def parse_library_file(input, _opts \\ []) do
    case do_parse_library_file(input) do
      {:ok, [imports, widgets], "", _, _, _} ->
        Model.new_remote_widget_library(imports, widgets)

      {:error, reason, rest, _, line, col} ->
        raise __MODULE__.ParserException, {reason, rest, line, col}
    end
  end

  # Helper functions to create Model structs

  defp create_import(parts) do
    library_name = Model.new_library_name(String.split(parts, "."))
    Model.new_import(library_name)
  end

  defp create_widget_declaration([name, initial_state, root]) do
    Model.new_widget_declaration(name, initial_state || %{}, root)
  end

  defp create_constructor_call([name, arguments]) do
    Model.new_constructor_call(name, arguments || %{})
  end

  defp create_switch([input, outputs]) do
    Model.new_switch(input, Map.new(outputs))
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
      "#{message} at line #{line}, column #{column}. Remaining input: #{inspect(rest)}"
    end
  end
end
