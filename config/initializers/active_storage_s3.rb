# Configure Active Storage S3 service to not use ACLs
Rails.application.config.after_initialize do
  if Rails.application.config.active_storage.service == :amazon
    # Monkey patch the S3 service to not use ACLs
    ActiveSupport.on_load(:active_storage_s3_service) do
      class ActiveStorage::Service::S3Service < ActiveStorage::Service
        private
        
        def upload_options
          # Remove ACL-related options
          super.except(:acl, :grant_read, :grant_read_acp, :grant_write_acp, :grant_full_control)
        end
      end
    end
  end
end
