defmodule ElixirAdvancedWeb.Router do
  use ElixirAdvancedWeb, :router

  import ElixirAdvancedWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ElixirAdvancedWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_api_user
  end

  pipeline :api_public do
    plug :accepts, ["json"]
  end

  # Public API routes (login, registration, rfw-templates, etc.)
  scope "/api", ElixirAdvancedWeb do
    pipe_through :api_public

    post "/users/log_in", UserSessionController, :create_api
    get "/rfw-templates", RfwTemplatesController, :widget_templates
  end

  # Protected API routes
  scope "/api", ElixirAdvancedWeb do
    pipe_through :api
  end

  # Public routes (login, registration, etc.)
  scope "/", ElixirAdvancedWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ElixirAdvancedWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/", UserLoginLive, :new
      live "/users/register", UserRegistrationLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
    get "/users/log_in", UserSessionController, :redirect_to_login
  end

  # Protected routes (require authentication)
  scope "/", ElixirAdvancedWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ElixirAdvancedWeb.UserAuth, :ensure_authenticated}] do
      live "/todos", TodosLive, :index
      live "/gallery", GalleryLive, :index
      live "/gallery/:id", PhotoLive, :show
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", ElixirAdvancedWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{ElixirAdvancedWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:elixir_advanced, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ElixirAdvancedWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
