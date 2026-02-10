class AddUniqueIndexToPracticeTypesName < ActiveRecord::Migration[7.1]
  def up
    # Add a unique index on LOWER(name) to prevent case-insensitive duplicates
    # This ensures we can't have both "ABA Therapy" and "Aba Therapy"
    execute <<-SQL
      CREATE UNIQUE INDEX index_practice_types_on_lower_name 
      ON practice_types (LOWER(name));
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX IF EXISTS index_practice_types_on_lower_name;
    SQL
  end
end
