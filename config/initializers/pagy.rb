# Pagy initializer
require 'pagy/extras/metadata'
require 'pagy/extras/overflow'

# Default configuration
Pagy::DEFAULT[:items] = 20        # items per page
Pagy::DEFAULT[:size]  = [1,4,4,1] # nav bar links
Pagy::DEFAULT[:overflow] = :empty  # handle overflow with empty results 