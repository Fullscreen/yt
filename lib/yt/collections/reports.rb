require 'yt/collections/base'

module Yt
  module Collections
    # @private
    class Reports < Base
      DIMENSIONS = Hash.new({name: 'day', parse: ->(day, *values) {[Date.iso8601(day), values.last]} }).tap do |hash|
        hash[:range] = {parse: ->(*values) { [:total, values.last]} }
        hash[:traffic_source] = {name: 'insightTrafficSourceType', parse: ->(source, value) {[TRAFFIC_SOURCES.key(source), value]} }
        hash[:playback_location] = {name: 'insightPlaybackLocationType', parse: ->(location, value) {[PLAYBACK_LOCATIONS.key(location), value]} }
        hash[:embedded_player_location] = {name: 'insightPlaybackLocationDetail', parse: ->(url, value) {[url, value]} }
        hash[:related_video] = {name: 'insightTrafficSourceDetail', parse: ->(video_id, value) { [Yt::Video.new(id: video_id, auth: @auth), value] } }
        hash[:video] = {name: 'video', parse: ->(video_id, value) { [Yt::Video.new(id: video_id, auth: @auth), value] } }
        hash[:playlist] = {name: 'playlist', parse: ->(playlist_id, value) { [Yt::Playlist.new(id: playlist_id, auth: @auth), value] } }
        hash[:device_type] = {name: 'deviceType', parse: ->(type, value) { [type.downcase.to_sym, value] } }
        hash[:gender_age_group] = {name: 'gender,ageGroup', parse: ->(gender, *values) { [gender.downcase.to_sym, *values] }}
        hash[:gender] = {name: 'gender', parse: ->(gender, value) { [gender.downcase.to_sym, value] } }
        hash[:age_group] = {name: 'ageGroup', parse: ->(age_group, value) { [age_group[3..-1], value] } }
      end

      # @see https://developers.google.com/youtube/analytics/v1/dimsmets/dims#Traffic_Source_Dimensions
      # @note EXT_APP is also returned but it’s not in the documentation above!
      TRAFFIC_SOURCES = {
        advertising: 'ADVERTISING',
        annotation: 'ANNOTATION',
        external_app: 'EXT_APP',
        external_url: 'EXT_URL',
        embedded: 'NO_LINK_EMBEDDED',
        other: 'NO_LINK_OTHER',
        playlist: 'PLAYLIST',
        promoted: 'PROMOTED',
        related_video: 'RELATED_VIDEO',
        subscriber: 'SUBSCRIBER',
        channel: 'YT_CHANNEL',
        other_page: 'YT_OTHER_PAGE',
        search: 'YT_SEARCH',
      }

      # @see https://developers.google.com/youtube/analytics/v1/dimsmets/dims#Playback_Location_Dimensions
      PLAYBACK_LOCATIONS = {
        channel: 'CHANNEL',
        watch: 'WATCH',
        embedded: 'EMBEDDED',
        other: 'YT_OTHER',
        external_app: 'EXTERNAL_APP',
        mobile: 'MOBILE' # only present for data < September 10, 2013
      }

      attr_writer :metric

      def within(days_range, options = {}, try_again = true)
        dimension = options.fetch(:dimension)
        type = options.fetch(:type)

        @days_range = days_range
        @dimension = dimension
        @filters = options.fetch(:filters, {})

        if dimension == :gender_age_group # array of array
          Hash.new{|h,k| h[k] = Hash.new 0.0}.tap do |hash|
            each{|gender, age_group, value| hash[gender][age_group[3..-1]] = value}
          end
        else
          Hash[*flat_map{|value| [value.first, type_cast(value.last, type)]}]
        end
      # NOTE: Once in a while, YouTube responds with 400 Error and the message
      # "Invalid query. Query did not conform to the expectations."; in this
      # case running the same query after one second fixes the issue. This is
      # not documented by YouTube and hardly testable, but trying again the
      # same query is a workaround that works and can hardly cause any damage.
      # Similarly, once in while YouTube responds with a random 503 error.
      rescue Yt::Error => e
        try_again && rescue?(e) ? sleep(3) && within(days_range, options, false) : raise
      end

    private

      def type_cast(value, type)
        case [type]
          when [Integer] then value.to_i if value
          when [Float] then value.to_f if value
        end
      end

      def new_item(data)
        instance_exec *data, &DIMENSIONS[@dimension][:parse]
      end

      # @see https://developers.google.com/youtube/analytics/v1/content_owner_reports
      def list_params
        super.tap do |params|
          params[:path] = '/youtube/analytics/v1/reports'
          params[:params] = reports_params
          params[:camelize_params] = false
        end
      end

      def reports_params
        @parent.reports_params.tap do |params|
          params['start-date'] = @days_range.begin
          params['end-date'] = @days_range.end
          params['metrics'] = @metric.to_s.camelize(:lower)
          params['dimensions'] = DIMENSIONS[@dimension][:name] unless @dimension == :range
          params['max-results'] = 10 if @dimension == :video
          params['max-results'] = 200 if @dimension == :playlist
          params['max-results'] = 25 if @dimension == :embedded_player_location
          params['max-results'] = 25 if @dimension == :related_video
          params['sort'] = "-#{@metric.to_s.camelize(:lower)}" if @dimension.in? [:video, :playlist, :embedded_player_location, :related_video]
          params[:filters] = filter_params
        end
      end

      def filter_params
        @filters.reverse_merge({}.tap do |filters|
          f[:isCurated] == 1 if @dimension == :playlist
          f[:insightPlaybackLocationType] = 'EMBEDDED' if @dimension == :embedded_player_location
          f[:insightTrafficSourceType] = 'RELATED_VIDEO' if @dimension == :related_video
        end).map {|f, v| "#{f}==#{v}"}.join(';')
      end

      def items_key
        'rows'
      end

      def rescue?(error)
        'badRequest'.in?(error.reasons) && error.to_s =~ /did not conform/
      end
    end
  end
end
