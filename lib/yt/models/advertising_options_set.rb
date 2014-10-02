require 'yt/models/base'

module Yt
  module Models
    # Encapsulates advertising options of a video, such as the types of ads
    # that can run during the video as well as the times when ads are allowed
    # to run during the video.
    # @see https://developers.google.com/youtube/partner/docs/v1/videoAdvertisingOptions#resource
    class AdvertisingOptionsSet < Base
      def initialize(options = {})
        @auth = options[:auth]
        @video_id = options[:video_id]
        @data = options[:data]
      end

      def update(attributes = {})
        underscore_keys! attributes
        do_patch body: attributes
        true
      end

      # Valid values for this property are: long, overlay, standard_instream,
      # third_party, trueview_inslate, or trueview_instream.
      # @return [Array<String>] the list of ad formats that the video is allowed to show.
      def ad_formats
        @ad_formats ||= @data['adFormats']
      end

      # Valid values for this property are: midroll, postroll, and preroll.
      # @return [Array<String>] the point at which the break occurs during the video playback.
      def break_positions
        @braek_positions ||= @data['breakPosition']
      end

      # @return [Array<Hash>] The time of the ad break specified as the number of seconds after
      #   the start of the video when the break occurs.
      def ad_breaks
        @ad_breaks ||= @data.fetch('adBreaks', []).map do |ad_break|
          {
            position: ad_break['position'],
            midroll_seconds: ad_break['midrollSeconds'],
            slots: ad_break.fetch('slot', []).map { |ad_slot| {id: ad_slot['id'], type: ad_slot['type']} }
          }
        end
      end

      # @return [String] A value that uniquely identifies the video to the
      #   third-party ad server.
      def tp_ad_server_video_id
        @data['tpAdServerVideoId']
      end

      # @return [String] The base URL for a third-party ad server from which
      #   YouTube can retrieve in-stream ads for the video.
      def tp_targeting_url
        @data['tpTargetingUrl']
      end

      # @return [String] A parameter string to append to the end of the request 
      #   to the third-party ad server.
      def tp_url_parameters
        @data['tpUrlParameters']
      end

      # @return [Boolean] true if the video automatically generates midroll breaks.
      def auto_generated_breaks
        @data['autoGeneratedBreaks']
      end

    private

      # @see https://developers.google.com/youtube/partner/docs/v1/videoAdvertisingOptions/patch
      def patch_params
        super.tap do |params|
          params[:expected_response] = Net::HTTPOK
          params[:path] = "/youtube/partner/v1/videoAdvertisingOptions/#{@video_id}"
          params[:params] = {on_behalf_of_content_owner: @auth.owner_name}
        end
      end
    end
  end
end