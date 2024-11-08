defmodule RfwFormats do
  @moduledoc """
  RfwFormats is an Elixir implementation of Flutter's Remote Flutter Widgets (RFW) format parser.

  This library provides functionality to parse and handle both text and binary formats used in
  Remote Flutter Widgets, enabling Elixir applications to work with Flutter widget definitions.

  ## Main Components

  * `RfwFormats.Text` - Functions for parsing RFW text format library and data files
  * `RfwFormats.Binary` - Functions for encoding and decoding RFW binary format blobs
  * `RfwFormats.Model` - Data structures representing RFW components

  ## Common Use Case

  The most common use case is parsing a widget template from text format and converting it
  to binary format for use with Flutter:

      alias RfwFormats.{Text, Binary}

      # Parse a widget template from text format
      template = Text.parse_library_file(\"\"\"
      import core.widgets;

      widget myButton = ElevatedButton(
        onPressed: callback,
        child: Text("Click me")
      );
      \"\"\")

      # Convert the template to binary format for Flutter
      binary_blob = Binary.encode_library_blob(template)

  See the documentation for `RfwFormats.Text` and `RfwFormats.Binary` for more details
  on available functions and their usage.
  """
end
