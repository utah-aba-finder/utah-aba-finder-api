class HealthController < ApplicationController
  skip_before_action :authenticate_client
  
  def show
    checks = {
      status: "ok",
      timestamp: Time.current.iso8601,
      version: Rails.application.config.version || "unknown"
    }
    
    # Database health check
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      db_size = ActiveRecord::Base.connection.execute(
        "SELECT pg_size_pretty(pg_database_size(current_database())) as size"
      ).first["size"]
      
      checks[:database] = {
        status: "ok",
        size: db_size,
        connection_pool: {
          size: ActiveRecord::Base.connection_pool.size,
          checked_out: ActiveRecord::Base.connection_pool.checked_out,
          available: ActiveRecord::Base.connection_pool.available_count
        }
      }
    rescue => e
      checks[:database] = {
        status: "error",
        error: e.message
      }
      checks[:status] = "degraded"
    end
    
    # Memory check
    begin
      if Rails.env.production?
        memory_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
        checks[:memory] = {
          status: memory_mb > 1000 ? "warning" : "ok",
          usage_mb: memory_mb.round(2),
          threshold_mb: 1000
        }
        checks[:status] = "degraded" if memory_mb > 1000
      end
    rescue => e
      checks[:memory] = {
        status: "unknown",
        error: e.message
      }
    end
    
    # Storage check (if using Active Storage)
    begin
      if defined?(ActiveStorage)
        checks[:storage] = {
          status: "ok",
          configured: true
        }
      end
    rescue => e
      checks[:storage] = {
        status: "error",
        error: e.message
      }
    end
    
    # Response time check
    checks[:response_time_ms] = ((Time.current - Time.parse(checks[:timestamp])) * 1000).round(2)
    
    status_code = checks[:status] == "ok" ? :ok : :service_unavailable
    render json: checks, status: status_code
  end
  
  def detailed
    # More detailed health check for monitoring systems
    checks = {
      status: "ok",
      timestamp: Time.current.iso8601,
      environment: Rails.env,
      version: Rails.application.config.version || "unknown"
    }
    
    # Database detailed check
    begin
      db_info = ActiveRecord::Base.connection.execute(
        "SELECT 
          pg_size_pretty(pg_database_size(current_database())) as db_size,
          (SELECT count(*) FROM providers) as providers_count,
          (SELECT count(*) FROM users) as users_count,
          (SELECT count(*) FROM locations) as locations_count,
          (SELECT count(*) FROM provider_assignments) as assignments_count
        "
      ).first
      
      checks[:database] = {
        status: "ok",
        size: db_info["db_size"],
        tables: {
          providers: db_info["providers_count"].to_i,
          users: db_info["users_count"].to_i,
          locations: db_info["locations_count"].to_i,
          assignments: db_info["assignments_count"].to_i
        },
        connection_pool: {
          size: ActiveRecord::Base.connection_pool.size,
          checked_out: ActiveRecord::Base.connection_pool.checked_out,
          available: ActiveRecord::Base.connection_pool.available_count,
          max: ActiveRecord::Base.connection_pool.instance_variable_get(:@size)
        }
      }
      
      # Check for large tables
      large_tables = ActiveRecord::Base.connection.execute(
        "SELECT 
          schemaname,
          tablename,
          pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
          pg_total_relation_size(schemaname||'.'||tablename) AS size_bytes
        FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
        LIMIT 10
        "
      ).to_a
      
      checks[:database][:largest_tables] = large_tables.map do |row|
        {
          table: row["tablename"],
          size: row["size"],
          size_bytes: row["size_bytes"].to_i
        }
      end
      
    rescue => e
      checks[:database] = {
        status: "error",
        error: e.message
      }
      checks[:status] = "error"
    end
    
    # Memory check
    begin
      if Rails.env.production?
        memory_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
        checks[:memory] = {
          status: memory_mb > 1000 ? "warning" : "ok",
          usage_mb: memory_mb.round(2),
          threshold_mb: 1000,
          percentage: (memory_mb / 1024.0 * 100).round(2) # Assuming 1GB limit
        }
        checks[:status] = "degraded" if memory_mb > 1000
      end
    rescue => e
      checks[:memory] = {
        status: "unknown",
        error: e.message
      }
    end
    
    status_code = checks[:status] == "ok" ? :ok : :service_unavailable
    render json: checks, status: status_code
  end
end
