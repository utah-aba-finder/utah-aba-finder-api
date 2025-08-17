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
        status: registration.status,
        submitted_data: registration.submitted_data,
        submitted_data_summary: format_submitted_data_summary(registration.submitted_data),
        admin_notes: registration.admin_notes,
        reviewed_at: registration.reviewed_at,
        rejection_reason: registration.rejection_reason,
        is_processed: registration.is_processed,
        created_at: registration.created_at,
        updated_at: registration.updated_at
      },
      relationships: {
        reviewed_by: registration.reviewed_by ? {
          id: registration.reviewed_by.id,
          email: registration.reviewed_by.email
        } : nil
      }
    }
  end

  private

  def self.format_submitted_data_summary(submitted_data)
    return {} unless submitted_data.is_a?(Hash)
    
    summary = {}
    submitted_data.each do |key, value|
      if value.is_a?(Array)
        summary[key] = value.join(', ')
      elsif value.is_a?(String) && value.length > 100
        summary[key] = value[0..97] + '...'
      else
        summary[key] = value
      end
    end
    summary
  end
end 