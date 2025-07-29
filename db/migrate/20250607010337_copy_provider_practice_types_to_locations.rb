class CopyProviderPracticeTypesToLocations < ActiveRecord::Migration[7.1]
  def up
    say_with_time "Copying provider practice types to locations" do
      Provider.includes(:practice_types, :locations).find_each do |provider|
        provider.practice_types.each do |practice_type|
          provider.locations.each do |location|
            LocationsPracticeType.find_or_create_by!(
              location: location,
              practice_type: practice_type
            )
          end
        end
      end
    end
  end
end
