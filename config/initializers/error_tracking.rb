# Error tracking and monitoring configuration
# This can be extended to integrate with services like Sentry, Rollbar, etc.

Rails.application.config.after_initialize do
  # Log unhandled exceptions
  if Rails.env.production?
    # Example: Integrate with error tracking service
    # require 'sentry-ruby'
    # Sentry.init do |config|
    #   config.dsn = ENV['SENTRY_DSN']
    #   config.environment = Rails.env
    # end
  end
end

# Global exception handler
module ErrorTracking
  def self.track(exception, context = {})
    Rails.logger.error "Error tracked: #{exception.class.name} - #{exception.message}"
    Rails.logger.error "Context: #{context.inspect}"
    Rails.logger.error exception.backtrace.join("\n")
    
    # Add integration with error tracking service here
    # Sentry.capture_exception(exception, extra: context) if defined?(Sentry)
  end
end
