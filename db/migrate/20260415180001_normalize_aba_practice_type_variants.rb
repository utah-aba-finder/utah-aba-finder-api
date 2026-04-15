class NormalizeAbaPracticeTypeVariants < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL.squish
      UPDATE practice_types
      SET name = 'ABA Therapy'
      WHERE regexp_replace(lower(trim(name)), '[^a-z]+', '', 'g') = 'abatherapy'
        AND name IS DISTINCT FROM 'ABA Therapy'
    SQL
  end

  def down
    # Irreversible: prior variant names are not stored.
  end
end
