class SeedPracticeTypes < ActiveRecord::Migration[7.1]
  def up
    #reset_column_information is to get rid of possible cached data from rails. May interfere when trying to seed data right after creation of table.
    PracticeType.reset_column_information
    PracticeType.create!([
      { name: "ABA Therapy" },
      { name: "Autism Evaluation" },
      { name: "Speech Therapy" }
    ])
  end
end
