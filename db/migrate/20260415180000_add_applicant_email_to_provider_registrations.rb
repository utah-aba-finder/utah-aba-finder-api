class AddApplicantEmailToProviderRegistrations < ActiveRecord::Migration[7.1]
  def change
    add_column :provider_registrations, :applicant_email, :string
  end
end
