# API Reliability and Monitoring Guide

This guide outlines the systems in place to ensure your API remains available and doesn't run out of resources.

## 🏥 Health Check Endpoints

### Basic Health Check
```
GET /health
```
Returns basic health status including database connectivity and memory usage.

### Detailed Health Check
```
GET /health/detailed
```
Returns comprehensive health information including:
- Database size and connection pool status
- Largest tables
- Memory usage
- Table row counts

## 📊 Monitoring Tools

### 1. Memory Monitoring
Memory usage is automatically logged for admin endpoints. The system warns when memory exceeds 800MB and alerts when it exceeds 1000MB.

**Check memory manually:**
```bash
heroku run rails monitoring:check_memory --app utah-aba-finder-api
```

### 2. Database Monitoring
Monitor database size and connection pool status.

**Check database health:**
```bash
heroku run rails monitoring:check_database --app utah-aba-finder-api
```

**Run all health checks:**
```bash
heroku run rails monitoring:health_check --app utah-aba-finder-api
```

## 🚨 Setting Up Alerts

### Heroku Metrics
1. Go to your Heroku dashboard
2. Navigate to Metrics tab
3. Set up alerts for:
   - Memory usage > 1000MB
   - Response time > 5 seconds
   - Error rate > 1%

### Database Alerts
Set up alerts in your database provider (Heroku Postgres) for:
- Database size approaching limits
- Connection pool exhaustion
- Slow queries

### Health Check Monitoring
Use a service like:
- **UptimeRobot** (free): Monitor `/health` endpoint every 5 minutes
- **Pingdom**: Monitor health endpoints
- **New Relic**: Full application monitoring

**Recommended UptimeRobot Setup:**
1. Create account at uptimerobot.com
2. Add monitor for: `https://utah-aba-finder-api-c9d143f02ce8.herokuapp.com/health`
3. Set alert contacts (email/SMS)
4. Monitor every 5 minutes

## 🛡️ Preventing Crashes

### 1. Error Handling
All controllers now have global error handling that:
- Logs errors with full context
- Returns user-friendly error messages
- Prevents sensitive information leakage

### 2. Database Connection Pooling
Connection pool is configured to match thread count:
- Default: 5 connections
- Adjust via `RAILS_MAX_THREADS` environment variable

### 3. Query Optimization
- Use `includes()` to prevent N+1 queries
- Pagination is implemented for large datasets
- Indexes are in place for frequently queried columns

### 4. Memory Management
- Pagination limits large result sets
- Memory monitoring warns before issues occur
- Large serializations are excluded from list endpoints

## 💾 Preventing Space Issues

### Database Size Monitoring
The system automatically checks database size. Monitor:
- Current size via `/health/detailed`
- Largest tables to identify growth patterns
- Set up alerts when approaching limits

### Recommended Limits
- **Warning**: Database > 4GB
- **Critical**: Database > 4.5GB (Heroku Standard-0 has 10GB limit)

### Cleanup Strategies
1. **Archive old data**: Move old records to archive tables
2. **Delete unused data**: Remove test data, old sessions
3. **Optimize indexes**: Remove unused indexes
4. **Vacuum database**: Run `VACUUM ANALYZE` periodically

**Check table sizes:**
```sql
SELECT 
  tablename,
  pg_size_pretty(pg_total_relation_size('public.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size('public.'||tablename) DESC;
```

## 🔄 Backup Strategy

### Automated Backups
Heroku Postgres provides automated daily backups. Verify:
1. Go to Heroku dashboard → Your app → Data → Postgres
2. Check "Backups" tab
3. Ensure backups are running

### Manual Backup
```bash
heroku pg:backups:capture --app utah-aba-finder-api
```

### Restore Backup
```bash
heroku pg:backups:restore <backup_id> --app utah-aba-finder-api
```

## 📈 Performance Optimization

### 1. Add Database Indexes
Check for missing indexes on frequently queried columns:
```ruby
# Example: Add index for provider lookups
add_index :providers, :status
add_index :providers, :category
add_index :users, :email
```

### 2. Enable Query Caching
For frequently accessed, rarely changing data:
```ruby
# Cache provider list for 5 minutes
Rails.cache.fetch("providers_list", expires_in: 5.minutes) do
  Provider.where(status: :approved).to_a
end
```

### 3. Optimize Serializers
- Only include necessary fields
- Use separate serializers for list vs detail views
- Avoid loading associations unnecessarily

## 🚦 Rate Limiting (Recommended)

Consider adding rate limiting to prevent abuse:

```ruby
# Add to Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
Rack::Attack.throttle('req/ip', limit: 100, period: 1.minute) do |req|
  req.ip
end
```

## 📝 Logging Best Practices

All errors are logged with:
- Full stack trace
- Request context (user, IP, path)
- Timestamp
- Request ID for tracking

Monitor logs:
```bash
heroku logs --tail --app utah-aba-finder-api
```

## 🔍 Regular Maintenance Tasks

### Weekly
- [ ] Check `/health/detailed` endpoint
- [ ] Review error logs
- [ ] Check database size

### Monthly
- [ ] Review slow queries
- [ ] Check for unused indexes
- [ ] Review memory usage trends
- [ ] Verify backups are working

### Quarterly
- [ ] Database optimization (VACUUM ANALYZE)
- [ ] Review and clean up old data
- [ ] Update dependencies
- [ ] Review and optimize indexes

## 🆘 Emergency Procedures

### If API is Down
1. Check Heroku status: `heroku ps --app utah-aba-finder-api`
2. Check logs: `heroku logs --tail --app utah-aba-finder-api`
3. Check health endpoint: `curl https://utah-aba-finder-api-c9d143f02ce8.herokuapp.com/health`
4. Restart dyno if needed: `heroku restart --app utah-aba-finder-api`

### If Database is Full
1. Check current size: `heroku pg:info --app utah-aba-finder-api`
2. Identify large tables via `/health/detailed`
3. Archive or delete old data
4. Consider upgrading database plan

### If Memory is High
1. Check memory usage: `heroku run rails monitoring:check_memory`
2. Review recent changes
3. Check for memory leaks in logs
4. Consider upgrading dyno size
5. Restart dyno: `heroku restart --app utah-aba-finder-api`

## 📞 Support Resources

- **Heroku Status**: https://status.heroku.com
- **Heroku Support**: Available in dashboard
- **Postgres Docs**: https://devcenter.heroku.com/articles/heroku-postgresql

## ✅ Checklist for Production Readiness

- [x] Health check endpoints configured
- [x] Error handling in place
- [x] Memory monitoring active
- [x] Database monitoring active
- [ ] External monitoring service configured (UptimeRobot/Pingdom)
- [ ] Alerts configured in Heroku
- [ ] Backup verification completed
- [ ] Rate limiting configured (optional)
- [ ] Log aggregation set up (optional)
