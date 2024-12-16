class MigrateProviderTypesToPracticeTypes < ActiveRecord::Migration[7.1]
  def up
    provider_types = {
      "aba_therapy" => "ABA Therapy",
      "autism_evaluation" => "Autism Evaluation"
    }
  
    # Preload PracticeType records into a hash for easy lookup
    practice_types = PracticeType.where(name: provider_types.values).index_by(&:name)
  
    Provider.find_each do |provider|
      practice_type_name = provider_types[provider.provider_type]
  
      if practice_type_name && practice_types[practice_type_name]
        practice_type = practice_types[practice_type_name]
        
        unless provider.practice_types.include?(practice_type)
          provider.practice_types << practice_type
        end
      end
    end
  end
end
