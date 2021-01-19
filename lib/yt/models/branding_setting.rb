require 'yt/models/base'

module Yt
  module Models
    # @private
    # Encapsulates channel branding data that contains channel banner(cover) image
    # with the channel info.
    # @see https://developers.google.com/youtube/v3/docs/channels#brandingSettings
    class BrandingSetting < Base

      def initialize(options = {})
        @data = options[:data] || {}
      end

      def image_url(size = 'bannerImageUrl')
        image.fetch(size.to_s)
      end

      has_attribute :image
      has_attribute :channel
    end
  end
end