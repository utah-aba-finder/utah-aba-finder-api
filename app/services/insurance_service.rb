class InsuranceService
  def self.process_insurance_names(insurance_names)
    return [] if insurance_names.blank?
    
    # Convert to array if it's a string
    names = insurance_names.is_a?(Array) ? insurance_names : [insurance_names]
    
    # Process each insurance name
    processed_insurances = names.map do |name|
      process_single_insurance(name.strip)
    end.compact
    
    processed_insurances
  end
  
  def self.process_single_insurance(name)
    return nil if name.blank?
    
    # Try to find existing insurance (case-insensitive)
    existing_insurance = Insurance.where('LOWER(name) = ?', name.downcase).first
    
    if existing_insurance
      # Return existing insurance
      existing_insurance
    else
      # Create new insurance
      new_insurance = Insurance.create!(name: name)
      Rails.logger.info "🆕 Created new insurance: #{name}"
      new_insurance
    end
  rescue => e
    Rails.logger.error "❌ Failed to process insurance '#{name}': #{e.message}"
    nil
  end
  
  def self.link_insurances_to_provider(provider, insurance_names)
    return unless insurance_names.present?
    
    # Process insurance names and get insurance records
    insurances = process_insurance_names(insurance_names)
    
    # Link each insurance to the provider
    insurances.each do |insurance|
      ProviderInsurance.find_or_create_by!(
        provider: provider,
        insurance: insurance,
        accepted: true
      )
    end
    
    Rails.logger.info "🔗 Linked #{insurances.count} insurances to provider #{provider.name}"
  end
  
  def self.get_insurance_names_for_provider(provider)
    provider.insurances.pluck(:name).sort
  end
  
  def self.search_insurances(query)
    return Insurance.none if query.blank?
    
    Insurance.where('name ILIKE ?', "%#{query}%")
  end
  
  def self.get_popular_insurances(limit = 10)
    Insurance.joins(:provider_insurances)
             .group('insurances.id')
             .order('COUNT(provider_insurances.id) DESC')
             .limit(limit)
  end
end
