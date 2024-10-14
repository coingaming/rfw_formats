defmodule RfwFormats.Text do
  @moduledoc """
  Provides functions for parsing Remote Flutter Widgets text data files and library files.
  """

  alias RfwFormats.Model

  defmodule Token do
    @type t :: %__MODULE__{
            line: integer(),
            column: integer(),
            start: integer(),
            end: integer()
          }
    defstruct [:line, :column, :start, :end]

    def to_string(%__MODULE__{} = token), do: inspect(token)
  end

  defmodule SymbolToken do
    @type t :: %__MODULE__{
            symbol: integer(),
            line: integer(),
            column: integer(),
            start: integer(),
            end: integer()
          }
    defstruct [:symbol, :line, :column, :start, :end]

    def to_string(%__MODULE__{symbol: symbol}), do: <<symbol::utf8>>

    # Define the symbol functions
    # Use an atom or appropriate value
    def triple_dot, do: :triple_dot
    def open_brace, do: ?{
    def close_brace, do: ?}
    # ASCII code for ':'
    def colon, do: ?:
    # ASCII code for ','
    def comma, do: ?,
    def open_bracket, do: ?[
    def close_bracket, do: ?]
    def dot, do: ?.
    def equals, do: ?=
    def greater_than, do: ?>
    def open_paren, do: ?(
    def close_paren, do: ?)
    def semicolon, do: ?;
  end

  defmodule IntegerToken do
    @type t :: %__MODULE__{
            value: integer(),
            line: integer(),
            column: integer(),
            start: integer(),
            end: integer()
          }
    defstruct [:value, :line, :column, :start, :end]

    def to_string(%__MODULE__{value: value}), do: Integer.to_string(value)
  end

  defmodule DoubleToken do
    @type t :: %__MODULE__{
            value: float(),
            line: integer(),
            column: integer(),
            start: integer(),
            end: integer()
          }
    defstruct [:value, :line, :column, :start, :end]

    def to_string(%__MODULE__{value: value}), do: Float.to_string(value)
  end

  defmodule IdentifierToken do
    @type t :: %__MODULE__{
            value: String.t(),
            line: integer(),
            column: integer(),
            start: integer(),
            end: integer()
          }
    defstruct [:value, :line, :column, :start, :end]

    def to_string(%__MODULE__{value: value}), do: value
  end

  defmodule StringToken do
    @type t :: %__MODULE__{
            value: String.t(),
            line: integer(),
            column: integer(),
            start: integer(),
            end: integer()
          }
    defstruct [:value, :line, :column, :start, :end]

    def to_string(%__MODULE__{value: value}), do: "\"#{value}\""
  end

  defmodule EofToken do
    @type t :: %__MODULE__{
            line: integer(),
            column: integer(),
            start: integer(),
            end: integer()
          }
    defstruct [:line, :column, :start, :end]

    def to_string(_), do: "<EOF>"
  end

  defmodule ParserException do
    @type t :: %__MODULE__{
            message: String.t(),
            line: integer(),
            column: integer()
          }
    defstruct [:message, :line, :column]

    def new(message, line, column) do
      %__MODULE__{message: message, line: line, column: column}
    end

    def from_token(message, token) do
      new(message, token.line, token.column)
    end

    def expected(what, token) do
      new("Expected #{what} but found #{Token.to_string(token)}", token.line, token.column)
    end

    def unexpected(token) do
      new("Unexpected #{Token.to_string(token)}", token.line, token.column)
    end

    def to_string(%__MODULE__{message: message, line: line, column: column}) do
      "#{message} at line #{line} column #{column}."
    end
  end

  @doc """
  Parse a Remote Flutter Widgets text data file.

  This data is usually used in conjunction with DynamicContent.

  Parsing this format is about ten times slower than parsing the binary
  variant; see decodeDataBlob. As such it is strongly discouraged,
  especially in resource-constrained contexts like mobile applications.
  """
  @spec parse_data_file(String.t()) :: Model.dynamic_map()
  def parse_data_file(file) do
    parser = __MODULE__.Parser.new(tokenize(file), nil)
    __MODULE__.Parser.read_data_file(parser)
  end

  @doc """
  Parses a Remote Flutter Widgets text library file.

  Remote widget libraries are usually used in conjunction with a Runtime.

  Parsing this format is about ten times slower than parsing the binary
  variant; see decodeLibraryBlob. As such it is strongly discouraged,
  especially in resource-constrained contexts like mobile applications.
  """
  @spec parse_library_file(String.t(), keyword()) :: Model.RemoteWidgetLibrary.t()
  def parse_library_file(file, opts \\ []) do
    source_identifier = Keyword.get(opts, :source_identifier)
    parser = __MODULE__.Parser.new(tokenize(file), source_identifier)
    __MODULE__.Parser.read_library_file(parser)
  end

  defp describe_rune(current) when current >= 0 and current < 0x10FFFF do
    if current > 0x20 do
      "U+#{Integer.to_string(current, 16) |> String.pad_leading(4, "0")} (\"#{<<current::utf8>>}}\")"
    else
      "U+#{Integer.to_string(current, 16) |> String.pad_leading(4, "0")}"
    end
  end

  defp handle_number_end(rest, index, line, column, buffer, buffer2, tokens) do
    value = List.to_string(buffer)

    {parsed_value, _} =
      if String.contains?(value, ".") or String.contains?(value, "e") or
           String.contains?(value, "E") do
        Float.parse(value)
      else
        Integer.parse(value)
      end

    new_token =
      case parsed_value do
        int when is_integer(int) ->
          %IntegerToken{
            value: int,
            line: line,
            column: column - String.length(value),
            start: index - String.length(value),
            end: index
          }

        float when is_float(float) ->
          %DoubleToken{
            value: float,
            line: line,
            column: column - String.length(value),
            start: index - String.length(value),
            end: index
          }
      end

    tokenize_impl(rest, index, line, column, [], buffer2, :main, tokens ++ [new_token])
  end

  defmodule TokenizerMode do
    @type t ::
            :main
            | :minus
            | :zero
            | :minus_integer
            | :integer
            | :integer_only
            | :numeric_dot
            | :fraction
            | :e
            | :negative_exponent
            | :exponent
            | :x
            | :hex
            | :dot1
            | :dot2
            | :identifier
            | :quote
            | :double_quote
            | :quote_escape
            | :quote_escape_unicode1
            | :quote_escape_unicode2
            | :quote_escape_unicode3
            | :quote_escape_unicode4
            | :double_quote_escape
            | :double_quote_escape_unicode1
            | :double_quote_escape_unicode2
            | :double_quote_escape_unicode3
            | :double_quote_escape_unicode4
            | :end_quote
            | :slash
            | :comment
            | :block_comment
            | :block_comment_end
  end

  def tokenize(file) do
    characters = String.to_charlist(file)
    tokenize_impl(characters, 0, 1, 0, [], [], :main, [])
  end

  defp tokenize_impl(chars, index, line, column, buffer, buffer2, mode, tokens) do
    case {chars, mode} do
      {[current | rest], :main} ->
        case current do
          0x0A ->
            tokenize_impl(rest, index + 1, line + 1, 0, [], buffer2, :main, tokens)

          0x20 ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :main, tokens)

          symbol
          when symbol in [0x28, 0x29, 0x2C, 0x3A, 0x3B, 0x3D, 0x3E, 0x5B, 0x5D, 0x7B, 0x7D] ->
            new_token = %SymbolToken{
              symbol: symbol,
              line: line,
              column: column,
              start: index,
              end: index + 1
            }

            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              [],
              buffer2,
              :main,
              tokens ++ [new_token]
            )

          0x22 ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :double_quote, tokens)

          0x27 ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :quote, tokens)

          0x2D ->
            tokenize_impl(rest, index + 1, line, column + 1, [current], buffer2, :minus, tokens)

          0x2E ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :dot1, tokens)

          0x2F ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :slash, tokens)

          0x30 ->
            tokenize_impl(rest, index + 1, line, column + 1, [current], buffer2, :zero, tokens)

          digit when digit in 0x31..0x39 ->
            tokenize_impl(rest, index + 1, line, column + 1, [digit], buffer2, :integer, tokens)

          alpha when alpha in ?A..?Z or alpha in ?a..?z or alpha == ?_ ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              [alpha],
              buffer2,
              :identifier,
              tokens
            )

          _ ->
            raise ParserException.new(
                    "Unexpected character #{describe_rune(current)}",
                    line,
                    column
                  )
        end

      {[current | rest], :minus} ->
        case current do
          digit when digit in 0x30..0x39 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :minus_integer,
              tokens
            )

          _ ->
            raise ParserException.new(
                    "Unexpected character #{describe_rune(current)} after minus sign (expected digit)",
                    line,
                    column
                  )
        end

      {[current | rest], :zero} ->
        case current do
          0x2E ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :numeric_dot,
              tokens
            )

          digit when digit in 0x30..0x39 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :integer,
              tokens
            )

          0x45 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :e,
              tokens
            )

          0x65 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :e,
              tokens
            )

          0x58 ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :x, tokens)

          0x78 ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :x, tokens)

          _ ->
            handle_number_end(rest, index, line, column, buffer, buffer2, tokens)
        end

      {[current | rest], :minus_integer} ->
        case current do
          0x2E ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :numeric_dot,
              tokens
            )

          digit when digit in 0x30..0x39 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :integer,
              tokens
            )

          0x45 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :e,
              tokens
            )

          0x65 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :e,
              tokens
            )

          _ ->
            handle_number_end(rest, index, line, column, buffer, buffer2, tokens)
        end

      {[current | rest], :integer} ->
        case current do
          0x2E ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :numeric_dot,
              tokens
            )

          digit when digit in 0x30..0x39 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :integer,
              tokens
            )

          0x45 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :e,
              tokens
            )

          0x65 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :e,
              tokens
            )

          _ ->
            handle_number_end(rest, index, line, column, buffer, buffer2, tokens)
        end

      {[current | rest], :numeric_dot} ->
        case current do
          digit when digit in 0x30..0x39 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :fraction,
              tokens
            )

          _ ->
            raise ParserException.new(
                    "Unexpected character #{describe_rune(current)} in fraction component",
                    line,
                    column
                  )
        end

      {[current | rest], :fraction} ->
        case current do
          digit when digit in 0x30..0x39 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :fraction,
              tokens
            )

          0x45 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :e,
              tokens
            )

          0x65 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :e,
              tokens
            )

          _ ->
            handle_number_end(rest, index, line, column, buffer, buffer2, tokens)
        end

      {[current | rest], :e} ->
        case current do
          0x2D ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :negative_exponent,
              tokens
            )

          digit when digit in 0x30..0x39 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :exponent,
              tokens
            )

          _ ->
            raise ParserException.new(
                    "Unexpected character #{describe_rune(current)} after exponent separator",
                    line,
                    column
                  )
        end

      {[current | rest], :negative_exponent} ->
        case current do
          digit when digit in 0x30..0x39 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :exponent,
              tokens
            )

          _ ->
            raise ParserException.new(
                    "Unexpected character #{describe_rune(current)} in exponent",
                    line,
                    column
                  )
        end

      {[current | rest], :exponent} ->
        case current do
          digit when digit in 0x30..0x39 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :exponent,
              tokens
            )

          _ ->
            handle_number_end(rest, index, line, column, buffer, buffer2, tokens)
        end

      {[current | rest], :x} ->
        case current do
          hex when hex in 0x30..0x39 or hex in ?A..?F or hex in ?a..?f ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :hex,
              tokens
            )

          _ ->
            raise ParserException.new(
                    "Unexpected character #{describe_rune(current)} after 0x prefix",
                    line,
                    column
                  )
        end

      {[current | rest], :hex} ->
        case current do
          hex when hex in 0x30..0x39 or hex in ?A..?F or hex in ?a..?f ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :hex,
              tokens
            )

          _ ->
            handle_number_end(rest, index, line, column, buffer, buffer2, tokens)
        end

      {[current | rest], :dot1} ->
        case current do
          0x2E ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :dot2, tokens)

          digit when digit in 0x30..0x39 ->
            new_token = %SymbolToken{
              symbol: 0x2E,
              line: line,
              column: column - 1,
              start: index - 1,
              end: index
            }

            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              [digit],
              buffer2,
              :integer_only,
              tokens ++ [new_token]
            )

          _ ->
            new_token = %SymbolToken{
              symbol: 0x2E,
              line: line,
              column: column - 1,
              start: index - 1,
              end: index
            }

            tokenize_impl(
              [current | rest],
              index,
              line,
              column,
              [],
              buffer2,
              :main,
              tokens ++ [new_token]
            )
        end

      {[current | rest], :dot2} ->
        case current do
          0x2E ->
            new_token = %SymbolToken{
              symbol: SymbolToken.triple_dot(),
              line: line,
              column: column - 2,
              start: index - 2,
              end: index + 1
            }

            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              [],
              buffer2,
              :main,
              tokens ++ [new_token]
            )

          _ ->
            raise ParserException.new(
                    "Unexpected character #{describe_rune(current)} inside \"...\" symbol",
                    line,
                    column
                  )
        end

      {[current | rest], :identifier} ->
        case current do
          char when char in ?A..?Z or char in ?a..?z or char in 0x30..0x39 or char == ?_ ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [char],
              buffer2,
              :identifier,
              tokens
            )

          _ ->
            value = List.to_string(buffer)

            new_token = %IdentifierToken{
              value: value,
              line: line,
              column: column - String.length(value),
              start: index - String.length(value),
              end: index
            }

            tokenize_impl(
              [current | rest],
              index,
              line,
              column,
              [],
              buffer2,
              :main,
              tokens ++ [new_token]
            )
        end

      {[current | rest], :quote} ->
        case current do
          0x27 ->
            value = List.to_string(buffer)

            new_token = %StringToken{
              value: value,
              line: line,
              column: column - String.length(value) - 1,
              start: index - String.length(value) - 1,
              end: index + 1
            }

            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              [],
              buffer2,
              :end_quote,
              tokens ++ [new_token]
            )

          0x5C ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer,
              buffer2,
              :quote_escape,
              tokens
            )

          0x0A ->
            raise ParserException.new("Unexpected end of line inside string", line, column)

          _ ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :quote,
              tokens
            )
        end

      {[current | rest], :double_quote} ->
        case current do
          0x22 ->
            value = List.to_string(buffer)

            new_token = %StringToken{
              value: value,
              line: line,
              column: column - String.length(value) - 1,
              start: index - String.length(value) - 1,
              end: index + 1
            }

            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              [],
              buffer2,
              :end_quote,
              tokens ++ [new_token]
            )

          0x5C ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer,
              buffer2,
              :double_quote_escape,
              tokens
            )

          0x0A ->
            raise ParserException.new("Unexpected end of line inside string", line, column)

          _ ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [current],
              buffer2,
              :double_quote,
              tokens
            )
        end

      {[current | rest], quote_escape}
      when quote_escape in [:quote_escape, :double_quote_escape] ->
        case current do
          char when char in [0x22, 0x27, 0x5C, 0x2F] ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [char],
              buffer2,
              if(quote_escape == :quote_escape, do: :quote, else: :double_quote),
              tokens
            )

          0x62 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [0x08],
              buffer2,
              if(quote_escape == :quote_escape, do: :quote, else: :double_quote),
              tokens
            )

          0x66 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [0x0C],
              buffer2,
              if(quote_escape == :quote_escape, do: :quote, else: :double_quote),
              tokens
            )

          0x6E ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [0x0A],
              buffer2,
              if(quote_escape == :quote_escape, do: :quote, else: :double_quote),
              tokens
            )

          0x72 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [0x0D],
              buffer2,
              if(quote_escape == :quote_escape, do: :quote, else: :double_quote),
              tokens
            )

          0x74 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer ++ [0x09],
              buffer2,
              if(quote_escape == :quote_escape, do: :quote, else: :double_quote),
              tokens
            )

          0x75 ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              buffer,
              [],
              if(quote_escape == :quote_escape,
                do: :quote_escape_unicode1,
                else: :double_quote_escape_unicode1
              ),
              tokens
            )

          _ ->
            raise ParserException.new(
                    "Unexpected character #{describe_rune(current)} after backslash in string",
                    line,
                    column
                  )
        end

      {[current | rest], unicode_escape}
      when unicode_escape in [
             :quote_escape_unicode1,
             :quote_escape_unicode2,
             :quote_escape_unicode3,
             :quote_escape_unicode4,
             :double_quote_escape_unicode1,
             :double_quote_escape_unicode2,
             :double_quote_escape_unicode3,
             :double_quote_escape_unicode4
           ] ->
        case current do
          hex when hex in 0x30..0x39 or hex in ?A..?F or hex in ?a..?f ->
            buffer2 = buffer2 ++ [current]

            next_mode =
              case unicode_escape do
                :quote_escape_unicode1 -> :quote_escape_unicode2
                :quote_escape_unicode2 -> :quote_escape_unicode3
                :quote_escape_unicode3 -> :quote_escape_unicode4
                :quote_escape_unicode4 -> :quote
                :double_quote_escape_unicode1 -> :double_quote_escape_unicode2
                :double_quote_escape_unicode2 -> :double_quote_escape_unicode3
                :double_quote_escape_unicode3 -> :double_quote_escape_unicode4
                :double_quote_escape_unicode4 -> :double_quote
              end

            if next_mode in [:quote, :double_quote] do
              {codepoint, _} = List.to_string(buffer2) |> Integer.parse(16)

              tokenize_impl(
                rest,
                index + 1,
                line,
                column + 1,
                buffer ++ [codepoint],
                [],
                next_mode,
                tokens
              )
            else
              tokenize_impl(rest, index + 1, line, column + 1, buffer, buffer2, next_mode, tokens)
            end

          _ ->
            raise ParserException.new(
                    "Unexpected character #{describe_rune(current)} in Unicode escape",
                    line,
                    column
                  )
        end

      {[current | rest], :end_quote} ->
        case current do
          0x0A ->
            tokenize_impl(rest, index + 1, line + 1, 0, [], buffer2, :main, tokens)

          0x20 ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :main, tokens)

          symbol when symbol in [0x28, 0x29, 0x2C, 0x3A, 0x3B, 0x3D, 0x5B, 0x5D, 0x7B, 0x7D] ->
            new_token = %SymbolToken{
              symbol: symbol,
              line: line,
              column: column,
              start: index,
              end: index + 1
            }

            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              [],
              buffer2,
              :main,
              tokens ++ [new_token]
            )

          0x2E ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :dot1, tokens)

          _ ->
            raise ParserException.new(
                    "Unexpected character #{describe_rune(current)} after end quote",
                    line,
                    column
                  )
        end

      {[current | rest], :slash} ->
        case current do
          0x2A ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :block_comment, tokens)

          0x2F ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :comment, tokens)

          _ ->
            raise ParserException.new(
                    "Unexpected character #{describe_rune(current)} inside comment delimiter",
                    line,
                    column
                  )
        end

      {[current | rest], :comment} ->
        case current do
          0x0A -> tokenize_impl(rest, index + 1, line + 1, 0, [], buffer2, :main, tokens)
          _ -> tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :comment, tokens)
        end

      {[current | rest], :block_comment} ->
        case current do
          0x2A ->
            tokenize_impl(
              rest,
              index + 1,
              line,
              column + 1,
              [],
              buffer2,
              :block_comment_end,
              tokens
            )

          0x0A ->
            tokenize_impl(rest, index + 1, line + 1, 0, [], buffer2, :block_comment, tokens)

          _ ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :block_comment, tokens)
        end

      {[current | rest], :block_comment_end} ->
        case current do
          0x2F ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :main, tokens)

          _ ->
            tokenize_impl(rest, index + 1, line, column + 1, [], buffer2, :block_comment, tokens)
        end

      {[], _} ->
        case mode do
          mode
          when mode in [
                 :quote,
                 :double_quote,
                 :quote_escape,
                 :double_quote_escape,
                 :quote_escape_unicode1,
                 :quote_escape_unicode2,
                 :quote_escape_unicode3,
                 :quote_escape_unicode4,
                 :double_quote_escape_unicode1,
                 :double_quote_escape_unicode2,
                 :double_quote_escape_unicode3,
                 :double_quote_escape_unicode4
               ] ->
            raise ParserException.new("Unexpected end of file inside string", line, column)

          :block_comment ->
            raise ParserException.new("Unexpected end of file in block comment", line, column)

          _ ->
            tokens
        end
    end
  end

  defmodule Parser do
    @reserved_words ~w(args data event false set state true)

    @type t :: %__MODULE__{
            source: Enumerable.t(),
            source_identifier: any(),
            previous_end: integer(),
            loop_identifiers: [String.t()]
          }
    defstruct [:source, :source_identifier, :previous_end, loop_identifiers: []]

    def new(source, source_identifier) do
      %__MODULE__{
        source: source,
        source_identifier: source_identifier,
        previous_end: 0,
        loop_identifiers: []
      }
    end

    def read_data_file(parser) do
      read_map(parser, extended: false)
    end

    defp check_is_not_reserved_word(identifier, identifier_token) do
      if identifier in @reserved_words do
        raise ParserException.from_token("#{identifier} is a reserved word", identifier_token)
      end
    end

    def read_library_file(parser) do
      imports = read_imports(parser)
      widgets = read_widget_declarations(parser)
      Model.new_remote_widget_library(imports, widgets)
    end

    defp read_map(parser, opts) do
      extended = Keyword.get(opts, :extended, false)
      widget_builder_scope = Keyword.get(opts, :widget_builder_scope, [])

      expect_symbol(parser, SymbolToken.open_brace())

      results =
        read_map_body(parser, extended: extended, widget_builder_scope: widget_builder_scope)

      expect_symbol(parser, SymbolToken.close_brace())
      results
    end

    defp read_map_body(parser, opts) do
      extended = Keyword.get(opts, :extended, false)
      widget_builder_scope = Keyword.get(opts, :widget_builder_scope, [])

      results = %{}
      read_map_body_impl(parser, results, extended, widget_builder_scope)
    end

    defp read_map_body_impl(parser, results, extended, widget_builder_scope) do
      case current_token(parser) do
        %SymbolToken{} ->
          results

        _ ->
          key = read_key(parser)

          if Map.has_key?(results, key) do
            raise ParserException.from_token(
                    "Duplicate key \"#{key}\" in map",
                    current_token(parser)
                  )
          end

          expect_symbol(parser, SymbolToken.colon())

          value =
            read_value(parser,
              extended: extended,
              null_ok: true,
              widget_builder_scope: widget_builder_scope
            )

          results = if value != Model.missing(), do: Map.put(results, key, value), else: results

          if found_symbol(parser, SymbolToken.comma()) do
            advance(parser)
            read_map_body_impl(parser, results, extended, widget_builder_scope)
          else
            results
          end
      end
    end

    defp read_list(parser, opts) do
      extended = Keyword.get(opts, :extended, false)
      widget_builder_scope = Keyword.get(opts, :widget_builder_scope, [])

      expect_symbol(parser, SymbolToken.open_bracket())
      results = read_list_body(parser, [], extended, widget_builder_scope)
      expect_symbol(parser, SymbolToken.close_bracket())
      results
    end

    defp read_list_body(parser, results, extended, widget_builder_scope) do
      if found_symbol(parser, SymbolToken.close_bracket()) do
        results
      else
        value =
          if extended && found_symbol(parser, SymbolToken.triple_dot()) do
            read_loop(parser, widget_builder_scope)
          else
            read_value(parser, extended: extended, widget_builder_scope: widget_builder_scope)
          end

        results = results ++ [value]

        if found_symbol(parser, SymbolToken.comma()) do
          advance(parser)
          read_list_body(parser, results, extended, widget_builder_scope)
        else
          if !found_symbol(parser, SymbolToken.close_bracket()) do
            raise ParserException.expected("comma", current_token(parser))
          end

          results
        end
      end
    end

    defp read_loop(parser, widget_builder_scope) do
      start = get_source_location(parser)
      advance(parser)
      expect_identifier(parser, "for")
      loop_identifier_token = current_token(parser)
      loop_identifier = read_identifier(parser)
      check_is_not_reserved_word(loop_identifier, loop_identifier_token)
      expect_identifier(parser, "in")
      collection = read_value(parser, extended: true, widget_builder_scope: widget_builder_scope)
      expect_symbol(parser, SymbolToken.colon())

      parser = %{parser | loop_identifiers: [loop_identifier | parser.loop_identifiers]}

      template =
        read_value(parser,
          extended: true,
          widget_builder_scope: widget_builder_scope ++ [loop_identifier]
        )

      parser = %{parser | loop_identifiers: tl(parser.loop_identifiers)}

      with_source_range(parser, Model.new_loop(collection, template), start)
    end

    def read_switch(parser, start, opts) do
      widget_builder_scope = Keyword.get(opts, :widget_builder_scope, [])

      value = read_value(parser, extended: true, widget_builder_scope: widget_builder_scope)
      cases = %{}
      expect_symbol(parser, SymbolToken.open_brace())
      cases = read_switch_cases(parser, cases, widget_builder_scope)
      expect_symbol(parser, SymbolToken.close_brace())
      with_source_range(parser, Model.new_switch(value, cases), start)
    end

    defp read_switch_cases(parser, cases, widget_builder_scope) do
      if !is_symbol_token?(current_token(parser)) do
        {key, value} =
          if found_identifier(parser, "default") do
            if Map.has_key?(cases, nil) do
              raise ParserException.from_token(
                      "Switch has multiple default cases",
                      current_token(parser)
                    )
            end

            advance(parser)
            {nil, read_switch_case_value(parser, widget_builder_scope)}
          else
            key = read_value(parser, extended: true, widget_builder_scope: widget_builder_scope)

            if Map.has_key?(cases, key) do
              raise ParserException.from_token(
                      "Switch has duplicate cases for key #{inspect(key)}",
                      current_token(parser)
                    )
            end

            {key, read_switch_case_value(parser, widget_builder_scope)}
          end

        cases = Map.put(cases, key, value)

        if found_symbol(parser, SymbolToken.comma()) do
          advance(parser)
          read_switch_cases(parser, cases, widget_builder_scope)
        else
          cases
        end
      else
        cases
      end
    end

    defp read_switch_case_value(parser, widget_builder_scope) do
      expect_symbol(parser, SymbolToken.colon())
      read_value(parser, extended: true, widget_builder_scope: widget_builder_scope)
    end

    defp read_parts(parser, opts \\ []) do
      optional = Keyword.get(opts, :optional, false)

      if optional && !found_symbol(parser, SymbolToken.dot()) do
        []
      else
        read_parts_impl(parser, [])
      end
    end

    defp read_parts_impl(parser, parts) do
      expect_symbol(parser, SymbolToken.dot())

      part =
        case current_token(parser) do
          %IntegerToken{value: value} -> value
          %StringToken{value: value} -> value
          %IdentifierToken{value: value} -> value
          _ -> raise ParserException.unexpected(current_token(parser))
        end

      advance(parser)

      parts = parts ++ [part]

      if found_symbol(parser, SymbolToken.dot()) do
        read_parts_impl(parser, parts)
      else
        parts
      end
    end

    defp read_value(parser, opts) do
      extended = Keyword.get(opts, :extended, false)
      null_ok = Keyword.get(opts, :null_ok, false)
      widget_builder_scope = Keyword.get(opts, :widget_builder_scope, [])

      case current_token(parser) do
        # Using the ASCII value for '['
        %SymbolToken{symbol: ?[} ->
          read_list(parser, extended: extended, widget_builder_scope: widget_builder_scope)

        # Using the ASCII value for '{'
        %SymbolToken{symbol: ?{} ->
          read_map(parser, extended: extended, widget_builder_scope: widget_builder_scope)

        # Using the ASCII value for '('
        %SymbolToken{symbol: ?(} ->
          read_widget_builder_declaration(parser, widget_builder_scope: widget_builder_scope)

        %IntegerToken{value: value} ->
          advance(parser)
          value

        %DoubleToken{value: value} ->
          advance(parser)
          value

        %StringToken{value: value} ->
          advance(parser)
          value

        %IdentifierToken{value: identifier} ->
          read_identifier_value(parser, identifier, extended, null_ok, widget_builder_scope)

        _ ->
          raise ParserException.unexpected(current_token(parser))
      end
    end

    defp read_identifier_value(parser, identifier, extended, null_ok, widget_builder_scope) do
      case identifier do
        "true" ->
          advance(parser)
          true

        "false" ->
          advance(parser)
          false

        "null" when null_ok ->
          advance(parser)
          Model.missing()

        _ when not extended ->
          raise ParserException.unexpected(current_token(parser))

        "event" ->
          read_event_handler(parser, widget_builder_scope)

        "args" ->
          read_args_reference(parser)

        "data" ->
          read_data_reference(parser)

        "state" ->
          read_state_reference(parser)

        "switch" ->
          read_switch_statement(parser, widget_builder_scope)

        "set" ->
          read_set_state_handler(parser, widget_builder_scope)

        _ ->
          cond do
            identifier in widget_builder_scope ->
              read_widget_builder_arg_reference(parser, identifier)

            identifier in parser.loop_identifiers ->
              read_loop_reference(parser, identifier)

            true ->
              read_constructor_call(parser, widget_builder_scope)
          end
      end
    end

    defp read_event_handler(parser, widget_builder_scope) do
      start = get_source_location(parser)
      advance(parser)
      event_name = read_string(parser)

      event_arguments =
        read_map(parser, extended: true, widget_builder_scope: widget_builder_scope)

      with_source_range(parser, Model.new_event_handler(event_name, event_arguments), start)
    end

    defp read_args_reference(parser) do
      start = get_source_location(parser)
      advance(parser)
      with_source_range(parser, Model.new_args_reference(read_parts(parser)), start)
    end

    defp read_data_reference(parser) do
      start = get_source_location(parser)
      advance(parser)
      with_source_range(parser, Model.new_data_reference(read_parts(parser)), start)
    end

    defp read_state_reference(parser) do
      start = get_source_location(parser)
      advance(parser)
      with_source_range(parser, Model.new_state_reference(read_parts(parser)), start)
    end

    defp read_switch_statement(parser, widget_builder_scope) do
      start = get_source_location(parser)
      advance(parser)
      read_switch(parser, start, widget_builder_scope: widget_builder_scope)
    end

    defp read_set_state_handler(parser, widget_builder_scope) do
      start = get_source_location(parser)
      advance(parser)
      inner_start = get_source_location(parser)
      expect_identifier(parser, "state")

      state_reference =
        with_source_range(parser, Model.new_state_reference(read_parts(parser)), inner_start)

      expect_symbol(parser, SymbolToken.equals())
      value = read_value(parser, extended: true, widget_builder_scope: widget_builder_scope)
      with_source_range(parser, Model.new_set_state_handler(state_reference, value), start)
    end

    defp read_widget_builder_arg_reference(parser, identifier) do
      start = get_source_location(parser)
      advance(parser)

      with_source_range(
        parser,
        Model.new_widget_builder_arg_reference(identifier, read_parts(parser)),
        start
      )
    end

    defp read_loop_reference(parser, identifier) do
      start = get_source_location(parser)
      advance(parser)

      loop_index = Enum.find_index(parser.loop_identifiers, &(&1 == identifier))

      with_source_range(
        parser,
        Model.new_loop_reference(loop_index, read_parts(parser, optional: true)),
        start
      )
    end

    defp read_constructor_call(parser, widget_builder_scope) do
      start = get_source_location(parser)
      name = read_identifier(parser)
      expect_symbol(parser, SymbolToken.open_paren())

      arguments =
        read_map_body(parser, extended: true, widget_builder_scope: widget_builder_scope)

      expect_symbol(parser, SymbolToken.close_paren())
      with_source_range(parser, Model.new_constructor_call(name, arguments), start)
    end

    defp read_widget_builder_declaration(parser, opts) do
      widget_builder_scope = Keyword.get(opts, :widget_builder_scope, [])

      expect_symbol(parser, SymbolToken.open_paren())
      argument_name_token = current_token(parser)
      argument_name = read_identifier(parser)
      check_is_not_reserved_word(argument_name, argument_name_token)
      expect_symbol(parser, SymbolToken.close_paren())
      expect_symbol(parser, SymbolToken.equals())
      expect_symbol(parser, SymbolToken.greater_than())
      value_token = current_token(parser)

      widget =
        read_value(parser,
          extended: true,
          widget_builder_scope: widget_builder_scope ++ [argument_name]
        )

      case widget do
        %Model.ConstructorCall{} ->
          :ok

        %Model.Switch{} ->
          :ok

        _ ->
          raise ParserException.from_token(
                  "Expecting a switch or constructor call got #{inspect(widget)}",
                  value_token
                )
      end

      Model.new_widget_builder_declaration(argument_name, widget)
    end

    defp read_widget_declaration(parser) do
      start = get_source_location(parser)
      expect_identifier(parser, "widget")
      name = read_identifier(parser)

      initial_state =
        if found_symbol(parser, SymbolToken.open_brace()),
          do: read_map(parser, extended: false),
          else: nil

      expect_symbol(parser, SymbolToken.equals())

      root =
        if found_identifier(parser, "switch") do
          switch_start = get_source_location(parser)
          advance(parser)
          read_switch(parser, switch_start, widget_builder_scope: [])
        else
          read_constructor_call(parser, [])
        end

      expect_symbol(parser, SymbolToken.semicolon())
      with_source_range(parser, Model.new_widget_declaration(name, initial_state, root), start)
    end

    defp read_widget_declarations(parser) do
      if found_identifier(parser, "widget") do
        [read_widget_declaration(parser) | read_widget_declarations(parser)]
      else
        []
      end
    end

    defp read_import(parser) do
      start = get_source_location(parser)
      expect_identifier(parser, "import")
      parts = read_import_parts(parser, [])
      expect_symbol(parser, SymbolToken.semicolon())
      with_source_range(parser, Model.new_import(Model.LibraryName.new(parts)), start)
    end

    defp read_import_parts(parser, parts) do
      part = read_key(parser)
      parts = parts ++ [part]

      if maybe_read_symbol(parser, SymbolToken.dot()) do
        read_import_parts(parser, parts)
      else
        parts
      end
    end

    defp read_imports(parser) do
      if found_identifier(parser, "import") do
        [read_import(parser) | read_imports(parser)]
      else
        []
      end
    end

    # Helper functions

    defp current_token(parser) do
      hd(parser.source)
    end

    defp advance(parser) do
      {[current], rest} = Enum.split(parser.source, 1)
      %{parser | source: rest, previous_end: current.end}
    end

    defp found_identifier(parser, identifier) do
      case current_token(parser) do
        %IdentifierToken{value: ^identifier} -> true
        _ -> false
      end
    end

    defp expect_identifier(parser, value) do
      case current_token(parser) do
        %IdentifierToken{value: ^value} ->
          advance(parser)

        _ ->
          raise ParserException.expected(value, current_token(parser))
      end
    end

    defp read_identifier(parser) do
      case current_token(parser) do
        %IdentifierToken{value: value} ->
          advance(parser)
          value

        _ ->
          raise ParserException.expected("identifier", current_token(parser))
      end
    end

    defp read_string(parser) do
      case current_token(parser) do
        %StringToken{value: value} ->
          advance(parser)
          value

        _ ->
          raise ParserException.expected("string", current_token(parser))
      end
    end

    defp found_symbol(parser, symbol) do
      case current_token(parser) do
        %SymbolToken{symbol: ^symbol} -> true
        _ -> false
      end
    end

    defp maybe_read_symbol(parser, symbol) do
      if found_symbol(parser, symbol) do
        advance(parser)
        true
      else
        false
      end
    end

    defp expect_symbol(parser, symbol) do
      case current_token(parser) do
        %SymbolToken{symbol: ^symbol} ->
          advance(parser)

        _ ->
          raise ParserException.expected("symbol \"#{<<symbol::utf8>>}\"", current_token(parser))
      end
    end

    defp read_key(parser) do
      case current_token(parser) do
        %IdentifierToken{} -> read_identifier(parser)
        %StringToken{} -> read_string(parser)
        _ -> raise ParserException.expected("identifier or string", current_token(parser))
      end
    end

    defp get_source_location(parser) do
      if parser.source_identifier do
        Model.SourceLocation.new(parser.source_identifier, current_token(parser).start)
      end
    end

    defp with_source_range(parser, node, start) do
      if parser.source_identifier && start do
        Model.BlobNode.associate_source(
          node,
          Model.SourceRange.new(
            start,
            Model.SourceLocation.new(parser.source_identifier, parser.previous_end)
          )
        )
      else
        node
      end
    end

    defp is_symbol_token?(token) do
      match?(%SymbolToken{}, token)
    end
  end
end
