# RfwFormats

RfwFormats is an Elixir implementation of Flutter's Remote Flutter Widgets (RFW) format parser. This library enables parsing and handling of both text and binary formats used in Remote Flutter Widgets, making it possible to work with Flutter widget definitions in Elixir applications.

## Features

* Parse RFW text format library and data files
* Encode and decode RFW binary format data and library blobs
* Full compatibility with Flutter's RFW specification
* Built with NimbleParsec for efficient text parsing

## Installation

Add `rfw_formats` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rfw_formats, "~> 0.1.0"}
  ]
end
```

## Usage

The most common use-case is parsing a widget template from text format and converting it to binary format for use with Flutter:

```elixir
alias RfwFormats.{Text, Binary}

# Parse a widget template from text format
template = Text.parse_library_file("""
import core.widgets;

widget myButton = ElevatedButton(
  onPressed: callback,
  child: Text("Click me")
);
""")

# Convert the template to binary format for Flutter
binary_blob = Binary.encode_library_blob(template)
```

### Additional Functions

The library also provides functions for working with data files and direct binary manipulation:

```elixir
# Parse data files
data = Text.parse_data_file("""
{
  "title": "Hello",
  "count": 42
}
""")

# Work with binary data blobs
encoded_data = Binary.encode_data_blob(data)
decoded_data = Binary.decode_data_blob(encoded_data)

# Work with binary library blobs
decoded_library = Binary.decode_library_blob(binary_blob)
```

