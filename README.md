# RfwFormats

RfwFormats is an Elixir implementation of Flutter's Remote Flutter Widgets (RFW) template parser and binary converter.

## Features

* Parse RFW text format library templates and data files
* Encode and decode RFW binary format data and library blobs
* Full compatibility with Flutter's RFW specification

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
