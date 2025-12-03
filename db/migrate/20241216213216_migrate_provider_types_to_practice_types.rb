class MigrateProviderTypesToPracticeTypes < ActiveRecord::Migration[7.1]
  def up
    # Use raw SQL to avoid loading Provider model which may have enums for columns that don't exist yet
    # (e.g., sponsorship_tier enum is defined in Provider model but column doesn't exist at this migration point)
    
    provider_types = {
      "aba_therapy" => "ABA Therapy",
      "autism_evaluation" => "Autism Evaluation"
    }
  
    # Preload PracticeType records using raw SQL to avoid model loading issues
    practice_type_names = provider_types.values
    practice_types_sql = "SELECT id, name FROM practice_types WHERE name IN (#{practice_type_names.map { |n| "'#{n}'" }.join(', ')})"
    practice_types_result = execute(practice_type_names.empty? ? "SELECT id, name FROM practice_types WHERE 1=0" : practice_types_sql)
    
    practice_types_map = {}
    practice_types_result.each do |row|
      practice_types_map[row['name']] = row['id'].to_i
    end
    
    # Map provider_type enum values (0 = aba_therapy, 1 = autism_evaluation based on default)
    provider_type_map = {
      0 => { key: "aba_therapy", practice_type_name: "ABA Therapy" },
      1 => { key: "autism_evaluation", practice_type_name: "Autism Evaluation" }
    }
    
    provider_type_map.each do |enum_value, mapping|
      practice_type_id = practice_types_map[mapping[:practice_type_name]]
      next unless practice_type_id
      
      # Find providers with this provider_type enum value and insert associations
      execute <<-SQL
        INSERT INTO provider_practice_types (provider_id, practice_type_id, created_at, updated_at)
        SELECT p.id, #{practice_type_id}, NOW(), NOW()
        FROM providers p
        WHERE p.provider_type = #{enum_value}
          AND NOT EXISTS (
            SELECT 1 FROM provider_practice_types ppt
            WHERE ppt.provider_id = p.id AND ppt.practice_type_id = #{practice_type_id}
          )
      SQL
    end
  end
end
