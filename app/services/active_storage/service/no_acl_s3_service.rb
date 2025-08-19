# app/services/active_storage/service/no_acl_s3_service.rb
# Ensures no ACL/Grant options are ever sent to S3, and the service is private.
module ActiveStorage
  module Service
    class NoAclS3Service < S3Service
      STRIPPED_KEYS = [:acl, :grant_read, :grant_read_acp, :grant_write_acp, :grant_full_control].freeze

      def initialize(bucket:, upload: {}, public: false, **options)
        safe_upload = (upload || {}).except(*STRIPPED_KEYS)
        # Force private, regardless of supplied config
        super(bucket: bucket, upload: safe_upload, public: false, **options)
      end

      private

      # Strip any stray ACL/Grant keys that might sneak in via call-sites
      def upload(key, io, checksum: nil, **options)
        options = options.except(*STRIPPED_KEYS)
        super
      end

      # For PUT-style direct uploads, Rails signs headers. Ensure no x-amz-acl header is included.
      def headers_for_direct_upload(key, checksum:, **options)
        headers = super
        headers.delete("x-amz-acl")
        headers
      end
    end
  end
end
