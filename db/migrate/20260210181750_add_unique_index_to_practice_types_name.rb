class AddUniqueIndexToPracticeTypesName < ActiveRecord::Migration[7.1]
  def up
    consolidate_duplicate_practice_types!

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

  private

  def consolidate_duplicate_practice_types!
    PracticeType.reset_column_information

    PracticeType.all.group_by { |pt| pt.name.downcase }.each do |_lowercase_name, practice_types|
      next if practice_types.length == 1

      keep = practice_types.max_by do |pt|
        [
          pt.name == "ABA Therapy" ? 1 : 0,
          pt.providers.count,
          -pt.id
        ]
      end

      practice_types.reject { |pt| pt.id == keep.id }.each do |duplicate|
        duplicate.providers.find_each do |provider|
          provider.practice_types << keep unless provider.practice_types.include?(keep)
          provider.practice_types.delete(duplicate)
        end

        duplicate.locations.find_each do |location|
          location.practice_types << keep unless location.practice_types.include?(keep)
          location.practice_types.delete(duplicate)
        end

        duplicate.destroy!
      end

      keep.update!(name: PracticeType.canonical_display_name(keep.name))
    end
  end
end
