Mix.install([
  {:phoenix_playground, "~> 0.1.7"},
  {:rfw_formats, git: "https://github.com/coingaming/rfw_formats.git"}
])

defmodule CounterLive do
  use Phoenix.LiveView

  @topic "counter"

  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(PhoenixPlayground.PubSub, @topic)
    {:ok, assign(socket, val: Counter.State.get_count())}
  end

  def handle_event("inc", _, socket) do
    new_val = Counter.State.incr()
    Phoenix.PubSub.broadcast(PhoenixPlayground.PubSub, @topic, {:count_update, new_val})
    {:noreply, assign(socket, :val, new_val)}
  end

  def handle_event("dec", _, socket) do
    new_val = Counter.State.decr()
    Phoenix.PubSub.broadcast(PhoenixPlayground.PubSub, @topic, {:count_update, new_val})
    {:noreply, assign(socket, :val, new_val)}
  end

  def handle_info({:count_update, count}, socket) do
    {:noreply, assign(socket, :val, count)}
  end

  def render(assigns) do
    ~H"""
    <div class="text-center">
      <h1 class="text-4xl font-bold text-center">Counter: <%= @val %></h1>
      <button phx-click="dec" class="text-6xl pb-2 w-20 rounded-lg bg-red-500 hover:bg-red-600">
        -
      </button>
      <button phx-click="inc" class="text-6xl pb-2 w-20 rounded-lg bg-green-500 hover:bg-green-600">
        +
      </button>
    </div>
    """
  end
end

defmodule Counter.State do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def get_count do
    Agent.get(__MODULE__, & &1)
  end

  def incr do
    Agent.update(__MODULE__, &(&1 + 1))
    get_count()
  end

  def decr do
    Agent.update(__MODULE__, &(&1 - 1))
    get_count()
  end
end

defmodule Counter.Controller do
  use Phoenix.Controller
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
                            fontFamily: "MaterialIcons",
                          ),
                        ),
                        SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: event "increment" {},
                          child: Icon(
                            icon: 0xe047,
                            fontFamily: "MaterialIcons",
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

  def widget_definition(conn, _params) do
    conn
    |> put_resp_content_type("application/octet-stream")
    |> send_resp(200, @binary_blob)
  end
end

defmodule Counter.Channel do
  use Phoenix.Channel

  @topic "counter"

  def join("counter:lobby", _message, socket) do
    Phoenix.PubSub.subscribe(PhoenixPlayground.PubSub, @topic)
    {:ok, %{count: Counter.State.get_count()}, socket}
  end

  def handle_in("inc", _payload, socket) do
    new_count = Counter.State.incr()
    Phoenix.PubSub.broadcast(PhoenixPlayground.PubSub, @topic, {:count_update, new_count})
    {:reply, {:ok, %{count: new_count}}, socket}
  end

  def handle_in("dec", _payload, socket) do
    new_count = Counter.State.decr()
    Phoenix.PubSub.broadcast(PhoenixPlayground.PubSub, @topic, {:count_update, new_count})
    {:reply, {:ok, %{count: new_count}}, socket}
  end

  def handle_info({:count_update, count}, socket) do
    push(socket, "count_update", %{count: count})
    {:noreply, socket}
  end
end

defmodule Counter.Socket do
  use Phoenix.Socket

  channel "counter:*", Counter.Channel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end

defmodule Counter.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :put_root_layout, html: {PhoenixPlayground.Layout, :root}
  end

  pipeline :api do
    plug :accepts, ["json", "bin"]
  end

  scope "/" do
    pipe_through :browser
    live("/", CounterLive)
  end

  scope "/api", Counter do
    pipe_through :api

    get "/widget-definition", Controller, :widget_definition
  end
end

defmodule Counter.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_playground

  plug Plug.Logger
  socket "/live", Phoenix.LiveView.Socket

  socket "/socket", Counter.Socket,
    websocket: [
      connect_info: [:peer_data, :x_headers, :uri],
      check_origin: false
    ],
    longpoll: false

  plug Plug.Static, from: {:phoenix, "priv/static"}, at: "/assets/phoenix"
  plug Plug.Static, from: {:phoenix_live_view, "priv/static"}, at: "/assets/phoenix_live_view"
  # Comment out following three lines when benchmarking /api endpoint response time
  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
  plug Phoenix.LiveReloader
  plug Phoenix.CodeReloader, reloader: &PhoenixPlayground.CodeReloader.reload/2
  plug Counter.Router
end

PhoenixPlayground.start(
  endpoint: Counter.Endpoint,
  child_specs: [Counter.State]
)
