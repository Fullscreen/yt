require 'yt/collections/base'
require 'yt/models/branding_setting'

module Yt
  module Collections
    # @private
    class BrandingSettings < Base

    private

      def attributes_for_new_item(data)
        {data: data['brandingSettings']}
      end

      # @return [Hash] the parameters to submit to YouTube to get the
      #   branding setting of a channel.
      # @see https://developers.google.com/youtube/v3/docs/channels#brandingSettings
      def list_params
        super.tap do |params|
          params[:params] = branding_settings_params
          params[:path] = '/youtube/v3/channels'
        end
      end

      def branding_settings_params
        params = {max_results: 50, part: 'brandingSettings'}
        params[:id] = @parent.id if @parent
        apply_where_params! params
      end
    end
  end
end