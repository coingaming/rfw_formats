defmodule RfwFormats.Model do
  @moduledoc """
  Defines data structures for Remote Flutter Widgets.
  """

  @type missing :: :__missing__

  @missing :__missing__

  @doc """
  Returns a missing value.
  """
  @spec missing() :: missing()
  def missing, do: @missing

  @doc """
  Checks if a value is considered missing.
  """
  @spec is_missing?(any()) :: boolean()
  def is_missing?(value), do: value == @missing

  @type dynamic_map :: %{required(String.t()) => dynamic_value()}
  @type dynamic_list :: [dynamic_value()]
  @type dynamic_value ::
          dynamic_map()
          | dynamic_list()
          | integer()
          | float()
          | boolean()
          | String.t()
          | blob_node()

  @type blob_node :: any()

  defprotocol BlobNode do
    @fallback_to_any true
    def associate_source(node, source_range)
    def propagate_source(node, original)
    def source(node)
  end

  defimpl BlobNode, for: Any do
    def associate_source(node, source_range), do: Map.put(node, :__source__, source_range)

    def propagate_source(node, original),
      do: Map.put(node, :__source__, BlobNode.source(original))

    def source(node), do: Map.get(node, :__source__)
  end

  defmodule SourceLocation do
    @moduledoc "Represents a location in a source file"
    defstruct [:source, :offset]

    @type t :: %__MODULE__{
            source: any(),
            offset: integer()
          }

    def new(source, offset), do: %__MODULE__{source: source, offset: offset}

    def compare(%__MODULE__{source: source1, offset: offset1}, %__MODULE__{
          source: source2,
          offset: offset2
        }) do
      cond do
        source1 != source2 -> raise "Cannot compare locations from different sources."
        offset1 < offset2 -> :lt
        offset1 > offset2 -> :gt
        true -> :eq
      end
    end

    def to_string(%__MODULE__{source: source, offset: offset}) do
      "#{source}@#{offset}"
    end
  end

  defmodule SourceRange do
    @moduledoc "Represents a range in a source file"
    defstruct [:start, :end]

    @type t :: %__MODULE__{
            start: SourceLocation.t(),
            end: SourceLocation.t()
          }

    def new(start, finish) do
      if SourceLocation.compare(start, finish) != :lt do
        raise "The start location must be before the end location."
      end

      %__MODULE__{start: start, end: finish}
    end

    def to_string(%__MODULE__{start: start, end: finish}) do
      "#{start.source}@#{start.offset}..#{finish.offset}"
    end
  end

  defmodule LibraryName do
    @moduledoc """
    Represents the name of a widgets library in the RFW package.
    """
    @enforce_keys [:parts]
    defstruct [:parts]

    @type t :: %__MODULE__{
            parts: [String.t()]
          }

    def new(parts), do: %__MODULE__{parts: parts}

    def to_string(%__MODULE__{parts: parts}), do: Enum.join(parts, ".")

    def compare(%__MODULE__{parts: parts1}, %__MODULE__{parts: parts2}) do
      cond do
        parts1 == parts2 ->
          :eq

        Enum.count(parts1) < Enum.count(parts2) ->
          :lt

        Enum.count(parts1) > Enum.count(parts2) ->
          :gt

        true ->
          Enum.zip(parts1, parts2)
          |> Enum.reduce_while(:eq, fn {p1, p2}, _acc ->
            case compare_strings(p1, p2) do
              :eq -> {:cont, :eq}
              other -> {:halt, other}
            end
          end)
      end
    end

    defp compare_strings(s1, s2) do
      cond do
        s1 == s2 -> :eq
        String.to_charlist(s1) < String.to_charlist(s2) -> :lt
        true -> :gt
      end
    end
  end

  defmodule FullyQualifiedWidgetName do
    @moduledoc """
    Represents a fully qualified widget name, including its library name.
    """
    @enforce_keys [:library, :widget]
    defstruct [:library, :widget]

    @type t :: %__MODULE__{
            library: LibraryName.t(),
            widget: String.t()
          }

    def new(library, widget), do: %__MODULE__{library: library, widget: widget}

    def compare(%__MODULE__{library: lib1, widget: widget1}, %__MODULE__{
          library: lib2,
          widget: widget2
        }) do
      case LibraryName.compare(lib1, lib2) do
        :eq -> compare_strings(widget1, widget2)
        other -> other
      end
    end

    def to_string(%__MODULE__{library: library, widget: widget}) do
      "#{LibraryName.to_string(library)}:#{widget}"
    end

    defp compare_strings(s1, s2) do
      cond do
        s1 == s2 -> :eq
        String.to_charlist(s1) < String.to_charlist(s2) -> :lt
        true -> :gt
      end
    end
  end

  defmodule Missing do
    @moduledoc """
    Represents a missing value in the data structure.
    """
    defstruct []
    @type t :: %__MODULE__{}
  end

  defmodule Loop do
    @moduledoc """
    Represents a loop construct in Remote Flutter Widgets.
    """
    @enforce_keys [:input, :output]
    defstruct [:input, :output, :__source__]

    @type t :: %__MODULE__{
            input: any(),
            output: any(),
            __source__: SourceRange.t() | nil
          }
  end

  defmodule Switch do
    @moduledoc """
    Represents a switch construct in Remote Flutter Widgets.
    """
    @enforce_keys [:input, :outputs]
    defstruct [:input, :outputs, :__source__]

    @type t :: %__MODULE__{
            input: any(),
            outputs: %{required(any()) => any()},
            __source__: SourceRange.t() | nil
          }
  end

  defmodule ConstructorCall do
    @moduledoc """
    Represents a constructor call in Remote Flutter Widgets.
    """
    @enforce_keys [:name, :arguments]
    defstruct [:name, :arguments, :__source__]

    @type t :: %__MODULE__{
            name: String.t(),
            arguments: RfwFormats.Model.dynamic_map(),
            __source__: SourceRange.t() | nil
          }
  end

  defmodule WidgetBuilderDeclaration do
    @moduledoc """
    Represents a widget builder declaration in Remote Flutter Widgets.
    """
    @enforce_keys [:argument_name, :widget]
    defstruct [:argument_name, :widget, :__source__]

    @type t :: %__MODULE__{
            argument_name: String.t(),
            widget: RfwFormats.Model.blob_node(),
            __source__: SourceRange.t() | nil
          }
  end

  defprotocol Reference do
    @doc """
    Constructs a reference from a list of parts.
    """
    def construct_reference(reference, parts)
  end

  defmodule BoundArgsReference do
    @moduledoc """
    Represents a bound reference to arguments.
    """
    @enforce_keys [:arguments, :parts]
    defstruct [:arguments, :parts, :__source__]

    @type t :: %__MODULE__{
            arguments: any(),
            parts: [any()],
            __source__: SourceRange.t() | nil
          }
  end

  defimpl Reference, for: BoundArgsReference do
    def construct_reference(reference, parts), do: %{reference | parts: reference.parts ++ parts}
  end

  defmodule ArgsReference do
    @moduledoc """
    Represents an unbound reference to arguments.
    """
    @enforce_keys [:parts]
    defstruct [:parts, :__source__]

    @type t :: %__MODULE__{
            parts: [any()],
            __source__: SourceRange.t() | nil
          }

    def bind(args_ref, arguments) do
      %BoundArgsReference{
        arguments: arguments,
        parts: args_ref.parts,
        __source__: args_ref.__source__
      }
    end
  end

  defimpl Reference, for: ArgsReference do
    def construct_reference(reference, parts), do: %{reference | parts: reference.parts ++ parts}
  end

  defmodule DataReference do
    @moduledoc """
    Represents a reference to the DynamicContent data.
    """
    @enforce_keys [:parts]
    defstruct [:parts, :__source__]

    @type t :: %__MODULE__{
            parts: [any()],
            __source__: SourceRange.t() | nil
          }
  end

  defimpl Reference, for: DataReference do
    def construct_reference(reference, parts), do: %{reference | parts: reference.parts ++ parts}
  end

  defmodule WidgetBuilderArgReference do
    @moduledoc """
    Represents a reference to the single argument of type DynamicMap passed into the widget builder.
    """
    @enforce_keys [:argument_name, :parts]
    defstruct [:argument_name, :parts, :__source__]

    @type t :: %__MODULE__{
            argument_name: String.t(),
            parts: [any()],
            __source__: SourceRange.t() | nil
          }
  end

  defimpl Reference, for: WidgetBuilderArgReference do
    def construct_reference(reference, parts), do: %{reference | parts: reference.parts ++ parts}
  end

  defmodule BoundLoopReference do
    @moduledoc """
    Represents a bound reference to a Loop.
    """
    @enforce_keys [:value, :parts]
    defstruct [:value, :parts, :__source__]

    @type t :: %__MODULE__{
            value: any(),
            parts: [any()],
            __source__: SourceRange.t() | nil
          }
  end

  defimpl Reference, for: BoundLoopReference do
    def construct_reference(reference, parts), do: %{reference | parts: reference.parts ++ parts}
  end

  defmodule LoopReference do
    @moduledoc """
    Represents an unbound reference to a Loop.
    """
    @enforce_keys [:loop, :parts]
    defstruct [:loop, :parts, :__source__]

    @type t :: %__MODULE__{
            loop: integer(),
            parts: [any()],
            __source__: SourceRange.t() | nil
          }

    def bind(loop_ref, value) do
      %BoundLoopReference{value: value, parts: loop_ref.parts, __source__: loop_ref.__source__}
    end
  end

  defimpl Reference, for: LoopReference do
    def construct_reference(reference, parts), do: %{reference | parts: reference.parts ++ parts}
  end

  defmodule BoundStateReference do
    @moduledoc """
    Represents a bound reference to a remote widget's state.
    """
    @enforce_keys [:depth, :parts]
    defstruct [:depth, :parts, :__source__]

    @type t :: %__MODULE__{
            depth: integer(),
            parts: [any()],
            __source__: SourceRange.t() | nil
          }
  end

  defimpl Reference, for: BoundStateReference do
    def construct_reference(reference, parts), do: %{reference | parts: reference.parts ++ parts}
  end

  defmodule StateReference do
    @moduledoc """
    Represents an unbound reference to a remote widget's state.
    """
    @enforce_keys [:parts]
    defstruct [:parts, :__source__]

    @type t :: %__MODULE__{
            parts: [any()],
            __source__: SourceRange.t() | nil
          }

    def bind(state_ref, depth) do
      %BoundStateReference{depth: depth, parts: state_ref.parts, __source__: state_ref.__source__}
    end
  end

  defimpl Reference, for: StateReference do
    def construct_reference(reference, parts), do: %{reference | parts: reference.parts ++ parts}
  end

  defmodule EventHandler do
    @moduledoc """
    Represents an event handler in Remote Flutter Widgets.
    """
    @enforce_keys [:event_name, :event_arguments]
    defstruct [:event_name, :event_arguments, :__source__]

    @type t :: %__MODULE__{
            event_name: String.t(),
            event_arguments: RfwFormats.Model.dynamic_map(),
            __source__: SourceRange.t() | nil
          }
  end

  defmodule SetStateHandler do
    @moduledoc """
    Represents a state setter in Remote Flutter Widgets.
    """
    @enforce_keys [:state_reference, :value]
    defstruct [:state_reference, :value, :__source__]

    @type t :: %__MODULE__{
            state_reference: StateReference.t() | BoundStateReference.t(),
            value: any(),
            __source__: SourceRange.t() | nil
          }
  end

  defmodule Import do
    @moduledoc """
    Represents a library import.
    """
    @enforce_keys [:name]
    defstruct [:name]

    @type t :: %__MODULE__{
            name: LibraryName.t()
          }
  end

  defmodule WidgetDeclaration do
    @moduledoc """
    Represents a widget declaration in a remote widget library.
    """
    @enforce_keys [:name, :root]
    defstruct [:name, :initial_state, :root, :__source__]

    @type t :: %__MODULE__{
            name: String.t(),
            initial_state: RfwFormats.Model.dynamic_map() | nil,
            root: ConstructorCall.t() | Switch.t(),
            __source__: SourceRange.t() | nil
          }
  end

  defmodule RemoteWidgetLibrary do
    @moduledoc """
    Represents a remote widget library.
    """
    @enforce_keys [:imports, :widgets]
    defstruct [:imports, :widgets]

    @type t :: %__MODULE__{
            imports: [Import.t()],
            widgets: [WidgetDeclaration.t()]
          }
  end

  # Implement BlobNode protocol for all relevant structs
  defimpl BlobNode,
    for: [
      Loop,
      Switch,
      ConstructorCall,
      WidgetBuilderDeclaration,
      BoundArgsReference,
      ArgsReference,
      DataReference,
      WidgetBuilderArgReference,
      BoundLoopReference,
      LoopReference,
      BoundStateReference,
      StateReference,
      EventHandler,
      SetStateHandler,
      WidgetDeclaration
    ] do
    def associate_source(node, source_range), do: Map.put(node, :__source__, source_range)

    def propagate_source(node, original),
      do: Map.put(node, :__source__, BlobNode.source(original))

    def source(node), do: Map.get(node, :__source__)
  end

  @doc """
  Creates a deep clone of a data structure.
  """
  @spec deep_clone(any()) :: any()
  def deep_clone(value) when is_struct(value) do
    struct(value.__struct__, Map.new(value, fn {k, v} -> {k, deep_clone(v)} end))
  end

  def deep_clone(value) when is_map(value) do
    Map.new(value, fn {k, v} -> {k, deep_clone(v)} end)
  end

  def deep_clone(value) when is_list(value) do
    Enum.map(value, &deep_clone/1)
  end

  def deep_clone(value)
      when is_integer(value) or is_float(value) or is_boolean(value) or is_binary(value) or
             is_atom(value) do
    value
  end

  def deep_clone(value) when is_function(value) do
    value
  end

  @doc """
  Creates a new FullyQualifiedWidgetName.
  """
  @spec new_fully_qualified_widget_name(LibraryName.t(), String.t()) ::
          FullyQualifiedWidgetName.t()
  def new_fully_qualified_widget_name(library, widget) do
    %FullyQualifiedWidgetName{library: library, widget: widget}
  end

  @doc """
  Creates a new Loop.
  """
  @spec new_loop(any(), any()) :: Loop.t()
  def new_loop(input, output) do
    %Loop{input: input, output: output}
  end

  @doc """
  Creates a new Switch.
  """
  @spec new_switch(any(), %{required(any()) => any()}) :: Switch.t()
  def new_switch(input, outputs) do
    %Switch{input: input, outputs: outputs}
  end

  @doc """
  Creates a new ConstructorCall.
  """
  @spec new_constructor_call(String.t(), dynamic_map()) :: ConstructorCall.t()
  def new_constructor_call(name, arguments) do
    %ConstructorCall{name: name, arguments: arguments}
  end

  @doc """
  Creates a new WidgetBuilderDeclaration.
  """
  @spec new_widget_builder_declaration(String.t(), blob_node()) :: WidgetBuilderDeclaration.t()
  def new_widget_builder_declaration(argument_name, widget) do
    %WidgetBuilderDeclaration{argument_name: argument_name, widget: widget}
  end

  @doc """
  Creates a new ArgsReference.
  """
  @spec new_args_reference([any()]) :: ArgsReference.t()
  def new_args_reference(parts) do
    %ArgsReference{parts: parts}
  end

  @doc """
  Creates a new DataReference.
  """
  @spec new_data_reference([any()]) :: DataReference.t()
  def new_data_reference(parts) do
    %DataReference{parts: parts}
  end

  @doc """
  Creates a new WidgetBuilderArgReference.
  """
  @spec new_widget_builder_arg_reference(String.t(), [any()]) :: WidgetBuilderArgReference.t()
  def new_widget_builder_arg_reference(argument_name, parts) do
    %WidgetBuilderArgReference{argument_name: argument_name, parts: parts}
  end

  @doc """
  Creates a new LoopReference.
  """
  @spec new_loop_reference(integer(), [any()]) :: LoopReference.t()
  def new_loop_reference(loop, parts) do
    %LoopReference{loop: loop, parts: parts}
  end

  @doc """
  Creates a new StateReference.
  """
  @spec new_state_reference([any()]) :: StateReference.t()
  def new_state_reference(parts) do
    %StateReference{parts: parts}
  end

  @doc """
  Creates a new EventHandler.
  """
  @spec new_event_handler(String.t(), dynamic_map()) :: EventHandler.t()
  def new_event_handler(event_name, event_arguments) do
    %EventHandler{event_name: event_name, event_arguments: event_arguments}
  end

  @doc """
  Creates a new SetStateHandler.
  """
  @spec new_set_state_handler(StateReference.t() | BoundStateReference.t(), any()) ::
          SetStateHandler.t()
  def new_set_state_handler(state_reference, value) do
    %SetStateHandler{state_reference: state_reference, value: value}
  end

  @doc """
  Creates a new Import.
  """
  @spec new_import(LibraryName.t()) :: Import.t()
  def new_import(name) do
    %Import{name: name}
  end

  @doc """
  Creates a new WidgetDeclaration.
  """
  @spec new_widget_declaration(String.t(), dynamic_map() | nil, ConstructorCall.t() | Switch.t()) ::
          WidgetDeclaration.t()
  def new_widget_declaration(name, initial_state, root) do
    %WidgetDeclaration{name: name, initial_state: initial_state, root: root}
  end

  @doc """
  Creates a new RemoteWidgetLibrary.
  """
  @spec new_remote_widget_library([Import.t()], [WidgetDeclaration.t()]) ::
          RemoteWidgetLibrary.t()
  def new_remote_widget_library(imports, widgets) do
    %RemoteWidgetLibrary{imports: imports, widgets: widgets}
  end

  @doc """
  Creates a new LibraryName.
  """
  @spec new_library_name([String.t()]) :: LibraryName.t()
  def new_library_name(parts) do
    %LibraryName{parts: parts}
  end

  @doc """
  Compares two LibraryNames.
  """
  @spec compare_library_names(LibraryName.t(), LibraryName.t()) :: :lt | :eq | :gt
  def compare_library_names(lib1, lib2) do
    LibraryName.compare(lib1, lib2)
  end

  @doc """
  Compares two FullyQualifiedWidgetNames.
  """
  @spec compare_fully_qualified_widget_names(
          FullyQualifiedWidgetName.t(),
          FullyQualifiedWidgetName.t()
        ) :: :lt | :eq | :gt
  def compare_fully_qualified_widget_names(fqwn1, fqwn2) do
    FullyQualifiedWidgetName.compare(fqwn1, fqwn2)
  end

  @doc """
  Converts a LibraryName to a string.
  """
  @spec library_name_to_string(LibraryName.t()) :: String.t()
  def library_name_to_string(library_name) do
    LibraryName.to_string(library_name)
  end

  @doc """
  Converts a FullyQualifiedWidgetName to a string.
  """
  @spec fully_qualified_widget_name_to_string(FullyQualifiedWidgetName.t()) :: String.t()
  def fully_qualified_widget_name_to_string(fqwn) do
    FullyQualifiedWidgetName.to_string(fqwn)
  end

  @doc """
  Creates a new BoundArgsReference.
  """
  @spec new_bound_args_reference(any(), [any()]) :: BoundArgsReference.t()
  def new_bound_args_reference(arguments, parts) do
    %BoundArgsReference{arguments: arguments, parts: parts}
  end

  @doc """
  Creates a new BoundLoopReference.
  """
  @spec new_bound_loop_reference(any(), [any()]) :: BoundLoopReference.t()
  def new_bound_loop_reference(value, parts) do
    %BoundLoopReference{value: value, parts: parts}
  end

  @doc """
  Creates a new BoundStateReference.
  """
  @spec new_bound_state_reference(integer(), [any()]) :: BoundStateReference.t()
  def new_bound_state_reference(depth, parts) do
    %BoundStateReference{depth: depth, parts: parts}
  end

  defimpl String.Chars, for: Missing do
    def to_string(_), do: "<missing>"
  end
end
