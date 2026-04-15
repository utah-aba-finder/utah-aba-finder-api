class NormalizeAbaTherapyPracticeTypeName < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL.squish
      UPDATE practice_types
      SET name = 'ABA Therapy'
      WHERE LOWER(TRIM(name)) = 'aba therapy'
        AND name IS DISTINCT FROM 'ABA Therapy'
    SQL
  end

  def down
    # Non-reversible: we do not know prior casing variants.
  end
end
