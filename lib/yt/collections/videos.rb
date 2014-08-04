require 'yt/collections/base'
require 'yt/models/video'

module Yt
  module Collections
    # Provides methods to interact with a collection of YouTube videos.
    #
    # Resources with videos are: {Yt::Models::Channel channels} and
    # {Yt::Models::Account accounts}.
    class Videos < Base

    private

      # @return [Yt::Models::Video] a new video initialized with one of
      #   the items returned by asking YouTube for a list of videos.
      # @see https://developers.google.com/youtube/v3/docs/videos#resource
      def new_item(data)
        Yt::Video.new id: data['id']['videoId'], snippet: data['snippet'], statistics: data['statistics'], auth: @auth
      end

      # @return [Hash] the parameters to submit to YouTube to list videos.
      # @see https://developers.google.com/youtube/v3/docs/search/list
      def list_params
        super.tap do |params|
          params[:params] = @parent.videos_params.merge videos_params
          params[:path] = videos_path
        end
      end

      def next_page
        super.tap{|items| add_offset_to(items) if @page_token.nil?}
      end

      # According to http://stackoverflow.com/a/23256768 YouTube does not
      # provide more than 500 results for any query. In order to overcome
      # that limit, the query is restarted with a publishedBefore filter in
      # case there are more videos to be listed for a channel
      def add_offset_to(items)
        if items.count == videos_params[:maxResults]
          last_published = items.last['snippet']['publishedAt']
          @page_token, @published_before = '', last_published
        end
      end

      def videos_params
        params = {type: :video, maxResults: 50, part: videos_parts, order: 'date'}
        params[:publishedBefore] = @published_before if @published_before
        params.merge @extra_params
      end

      def videos_path
        if @extra_params.empty? || @extra_params.key?(:id)
          '/youtube/v3/videos'
        else
          '/youtube/v3/search'
        end
      end

      def videos_parts
        [:snippet].concat(@extra_parts).uniq.join(',')
      end
    end
  end
end