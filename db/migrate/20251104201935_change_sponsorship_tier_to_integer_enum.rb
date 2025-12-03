class ChangeSponsorshipTierToIntegerEnum < ActiveRecord::Migration[7.1]
  def up
    # Remove old index
    remove_index :providers, :sponsorship_tier if index_exists?(:providers, :sponsorship_tier)
    
    # Convert string values to integer enum values
    # free: 0, featured: 1, sponsor: 2, partner: 3
    # Map old string values to new integer values:
    # 'featured' -> 1 (featured)
    # 'premium' -> 2 (sponsor)
    # 'basic' -> 1 (featured, as entry level)
    # nil/blank -> 0 (free)
    
    execute <<-SQL
      ALTER TABLE providers 
      ALTER COLUMN sponsorship_tier TYPE integer 
      USING CASE 
        WHEN sponsorship_tier = 'featured' THEN 1
        WHEN sponsorship_tier = 'premium' THEN 2
        WHEN sponsorship_tier = 'basic' THEN 1
        ELSE 0
      END
    SQL
    
    # Add default value
    change_column_default :providers, :sponsorship_tier, 0
    change_column_null :providers, :sponsorship_tier, false
    
    # Re-add index
    add_index :providers, :sponsorship_tier
  end
  
  def down
    # Remove index
    remove_index :providers, :sponsorship_tier if index_exists?(:providers, :sponsorship_tier)
    
    # Convert integer enum back to string
    execute <<-SQL
      ALTER TABLE providers 
      ALTER COLUMN sponsorship_tier TYPE varchar 
      USING CASE 
        WHEN sponsorship_tier = 1 THEN 'featured'
        WHEN sponsorship_tier = 2 THEN 'sponsor'
        WHEN sponsorship_tier = 3 THEN 'partner'
        ELSE NULL
      END
    SQL
    
    change_column_null :providers, :sponsorship_tier, true
    
    # Re-add index
    add_index :providers, :sponsorship_tier
  end
end
