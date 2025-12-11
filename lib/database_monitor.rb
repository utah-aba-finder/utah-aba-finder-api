class DatabaseMonitor
  def self.check_database_health
    {
      size: database_size,
      connection_pool: connection_pool_status,
      slow_queries: check_slow_queries,
      table_sizes: largest_tables(10)
    }
  end
  
  def self.database_size
    result = ActiveRecord::Base.connection.execute(
      "SELECT pg_size_pretty(pg_database_size(current_database())) as size"
    ).first
    result["size"]
  rescue => e
    "unknown (#{e.message})"
  end
  
  def self.connection_pool_status
    pool = ActiveRecord::Base.connection_pool
    {
      size: pool.size,
      checked_out: pool.checked_out,
      available: pool.available_count,
      max: pool.instance_variable_get(:@size) || 5
    }
  rescue => e
    { error: e.message }
  end
  
  def self.largest_tables(limit = 10)
    ActiveRecord::Base.connection.execute(
      "SELECT 
        tablename,
        pg_size_pretty(pg_total_relation_size('public.'||tablename)) AS size,
        pg_total_relation_size('public.'||tablename) AS size_bytes
      FROM pg_tables
      WHERE schemaname = 'public'
      ORDER BY pg_total_relation_size('public.'||tablename) DESC
      LIMIT #{limit}
      "
    ).to_a.map do |row|
      {
        table: row["tablename"],
        size: row["size"],
        size_bytes: row["size_bytes"].to_i
      }
    end
  rescue => e
    Rails.logger.error "Error checking table sizes: #{e.message}"
    []
  end
  
  def self.check_slow_queries
    # This would require pg_stat_statements extension
    # For now, return a placeholder
    { note: "Enable pg_stat_statements for query monitoring" }
  end
  
  def self.warn_if_large
    size_bytes = ActiveRecord::Base.connection.execute(
      "SELECT pg_database_size(current_database()) as size_bytes"
    ).first["size_bytes"].to_i
    
    # Warn if database is over 5GB
    if size_bytes > 5.gigabytes
      Rails.logger.warn "⚠️  Database size is large: #{ActiveSupport::NumberHelper.number_to_human_size(size_bytes)}"
      return true
    end
    false
  rescue => e
    Rails.logger.error "Error checking database size: #{e.message}"
    false
  end
end
