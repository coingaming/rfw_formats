defmodule ElixirAdvancedWeb.RfwTemplatesController do
  use ElixirAdvancedWeb, :controller
  alias RfwFormats.{Text, Binary}

  @templates_dir Path.join([
    :code.priv_dir(:elixir_advanced),
    "..",
    "lib",
    "elixir_advanced_web",
    "rfw_templates"
  ])

  @template_names ["counter", "counter2"]

  @templates Map.new(@template_names, fn name ->
    template_content =
      @templates_dir
      |> Path.join("#{name}.rfwtxt")
      |> File.read!()
      |> Text.parse_library_file()
      |> Binary.encode_library_blob()
      |> Base.encode64()

    {name, template_content}
  end)

  def widget_templates(conn, _params) do
    templates = [
      %{
        "path" => "/counter",
        "isShellRoute" => true,
        "label" => "Gallery",
        "iconHex" => "0xe332",
        "fontFamily" => "MaterialIcons",
        "template" => @templates["counter"],
        "routes" => [
          %{
            "path" => "/counter/counter2",
            "template" => @templates["counter2"]
          }
        ]
      }
    ]

    conn
    |> put_resp_content_type("application/json")
    |> json(templates)
  end
end
