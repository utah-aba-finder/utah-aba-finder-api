class ProviderRegistrationSerializer
  def self.format_registrations(registrations)
    {
      data: registrations.map do |registration|
        format_registration(registration)
      end
    }
  end

  def self.format_registration(registration)
    {
      id: registration.id,
      type: "provider_registration",
      attributes: {
        email: registration.email,
        provider_name: registration.provider_name,
        category: registration.category,
        category_display_name: registration.category_display_name,
        status: registration.status,
        submitted_data: registration.submitted_data,
        submitted_data_summary: registration.submitted_data_summary,
        admin_notes: registration.admin_notes,
        rejection_reason: registration.rejection_reason,
        is_processed: registration.is_processed,
        created_at: registration.created_at,
        updated_at: registration.updated_at,
        reviewed_at: registration.reviewed_at
      },
      relationships: {
        reviewed_by: registration.reviewed_by ? {
          data: {
            id: registration.reviewed_by.id,
            type: "user",
            attributes: {
              email: registration.reviewed_by.email,
              role: registration.reviewed_by.role
            }
          }
        } : nil
      }
    }
  end
end 