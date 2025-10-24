class MemoryMonitor
  def self.log_memory_usage(context = "Unknown")
    if Rails.env.production?
      memory_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
      Rails.logger.info "🧠 Memory usage (#{context}): #{memory_mb.round(2)} MB"
      
      # Warn if memory usage is high
      if memory_mb > 800  # 800MB threshold for Standard-2X dyno
        Rails.logger.warn "⚠️  High memory usage detected: #{memory_mb.round(2)} MB"
      end
    end
  end
  
  def self.check_memory_before_action(controller, action)
    log_memory_usage("#{controller}##{action}")
  end
end
