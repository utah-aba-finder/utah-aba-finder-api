class MemoryMonitor
  WARNING_THRESHOLD_MB = 800  # 800MB for Standard-2X dyno
  CRITICAL_THRESHOLD_MB = 1000  # 1000MB critical threshold
  
  def self.log_memory_usage(context = "Unknown")
    if Rails.env.production?
      memory_mb = current_memory_usage
      Rails.logger.info "🧠 Memory usage (#{context}): #{memory_mb.round(2)} MB"
      
      # Warn if memory usage is high
      if memory_mb > CRITICAL_THRESHOLD_MB
        Rails.logger.error "🚨 CRITICAL: Memory usage is very high: #{memory_mb.round(2)} MB"
        # Could trigger alerts here (email, Slack, etc.)
      elsif memory_mb > WARNING_THRESHOLD_MB
        Rails.logger.warn "⚠️  WARNING: High memory usage detected: #{memory_mb.round(2)} MB"
      end
      
      memory_mb
    else
      0
    end
  rescue => e
    Rails.logger.warn "MemoryMonitor error: #{e.message}"
    0
  end
  
  def self.current_memory_usage
    `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  rescue => e
    Rails.logger.warn "Could not get memory usage: #{e.message}"
    0
  end
  
  def self.check_memory_before_action(controller, action)
    log_memory_usage("#{controller}##{action}")
  end
  
  def self.memory_status
    memory_mb = current_memory_usage
    {
      usage_mb: memory_mb.round(2),
      status: case
              when memory_mb > CRITICAL_THRESHOLD_MB then "critical"
              when memory_mb > WARNING_THRESHOLD_MB then "warning"
              else "ok"
              end,
      threshold_warning: WARNING_THRESHOLD_MB,
      threshold_critical: CRITICAL_THRESHOLD_MB
    }
  rescue => e
    { status: "unknown", error: e.message }
  end
end
