defmodule ElixirAdvancedWeb.RfwTemplatesController do
  use ElixirAdvancedWeb, :controller
  alias RfwFormats.{Text, Binary}

  # Parse the template at compile time
  @template Text.parse_library_file("""
            import widgets;
            import material;

            widget root = Scaffold(
              appBar: AppBar(
                title: Text(text: "Counter Example"),
                centerTitle: true,
                backgroundColor: 0xFF7B68EE,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: "center",
                  children: [
                    Text(text: ["Counter: ", data.state],
                      style: {
                        fontSize: 20.0,
                      },
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: "center",
                      children: [
                        ElevatedButton(
                          onPressed: event "decrement" {},
                          child: Icon(
                            icon: 0xe516,
                            fontFamily: 'MaterialIcons',
                          ),
                        ),
                        SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: event "increment" {},
                          child: Icon(
                            icon: 0xe047,
                            fontFamily: 'MaterialIcons',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
            """)

  # Encode the binary blob at compile time
  @binary_blob Binary.encode_library_blob(@template)

  def widget_template(conn, _params) do
    conn
    |> put_resp_content_type("application/octet-stream")
    |> send_resp(200, @binary_blob)
  end
end
