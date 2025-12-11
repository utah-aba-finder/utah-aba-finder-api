namespace :monitoring do
  desc "Check database health and size"
  task :check_database => :environment do
    puts "🔍 Checking database health..."
    
    begin
      size = DatabaseMonitor.database_size
      puts "✅ Database size: #{size}"
      
      pool_status = DatabaseMonitor.connection_pool_status
      puts "📊 Connection pool: #{pool_status[:available]}/#{pool_status[:max]} available"
      
      if DatabaseMonitor.warn_if_large
        puts "⚠️  WARNING: Database is getting large!"
      end
      
      largest = DatabaseMonitor.largest_tables(5)
      puts "\n📋 Largest tables:"
      largest.each do |table|
        puts "  - #{table[:table]}: #{table[:size]}"
      end
      
    rescue => e
      puts "❌ Error checking database: #{e.message}"
      exit 1
    end
  end
  
  desc "Check memory usage"
  task :check_memory => :environment do
    if Rails.env.production?
      memory_mb = `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
      puts "🧠 Memory usage: #{memory_mb.round(2)} MB"
      
      if memory_mb > 1000
        puts "⚠️  WARNING: High memory usage detected!"
        exit 1
      else
        puts "✅ Memory usage is within acceptable limits"
      end
    else
      puts "ℹ️  Memory check only runs in production"
    end
  end
  
  desc "Run all health checks"
  task :health_check => :environment do
    puts "🏥 Running comprehensive health checks...\n\n"
    
    Rake::Task["monitoring:check_database"].invoke
    puts "\n"
    Rake::Task["monitoring:check_memory"].invoke
    
    puts "\n✅ All health checks completed"
  end
end
