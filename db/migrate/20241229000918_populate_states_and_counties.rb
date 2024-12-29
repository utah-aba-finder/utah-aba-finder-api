class PopulateStatesAndCounties < ActiveRecord::Migration[7.1]
  require 'csv'

  def up
    file_path = Rails.root.join('db', 'data', 'states_and_counties.csv')
    return unless File.exist?(file_path)

    CSV.foreach(file_path, headers: true) do |row|
      state = State.find_or_create_by!(name: row["Official Name State"], abbreviation: row["State Abbreviation"])

      if row["Type"] != "county"
        County.find_or_create_by!(name: row['Name with legal/statistical area description'], state_id: state.id)
      else
        County.find_or_create_by!(name: row['Official Name County'], state_id: state.id)
      end

      County.find_or_create_by!(name: "Contact Us", state_id: state.id)
    end
  end

  def down
    County.delete_all
    State.delete_all
  end
end
