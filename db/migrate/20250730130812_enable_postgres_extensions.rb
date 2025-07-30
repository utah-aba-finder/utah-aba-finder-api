class EnablePostgresExtensions < ActiveRecord::Migration[7.1]
  def change
    enable_extension "plpgsql"
    enable_extension "pg_trgm"
  end
end
