# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # When credentials are included, we cannot use wildcard '*'
    # Must specify exact origins
    allowed_origins = [
      'http://localhost:3000',  # Development frontend
      'https://autismserviceslocator.com',  # Production frontend
      'https://www.autismserviceslocator.com'  # Production frontend with www
    ]
    
    # Add custom frontend URL from env if present
    frontend_url = ENV['FRONTEND_URL'].presence
    allowed_origins << frontend_url if frontend_url
    
    origins allowed_origins

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true  # Must be true when frontend uses credentials: 'include'
  end
end
