# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

# Allowed origins are read from the CORS_ORIGINS env var as a comma-separated
# list (e.g. "https://app.example.com,https://admin.example.com").
# In development, localhost origins are permitted automatically.

allowed_origins = if Rails.env.production?
  ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip).reject(&:blank?)
else
  [ /\Ahttp:\/\/localhost(:\d+)?\z/, /\Ahttp:\/\/127\.0\.0\.1(:\d+)?\z/ ]
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "/api/*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [],
      max_age: 600
  end
end
