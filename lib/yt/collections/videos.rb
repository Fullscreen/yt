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

      def attributes_for_new_item(data)
        {}.tap do |attributes|
          attributes[:id] = use_list_endpoint? ? data['id'] : data['id']['videoId']
          attributes[:snippet] = data.fetch('snippet', {}).merge includes_tags: false
          attributes[:status] = data['status']
          attributes[:content_details] = data['contentDetails']
          attributes[:statistics] = data['statistics']
          attributes[:auth] = @auth
        end
      end

      # @return [Hash] the parameters to submit to YouTube to list videos.
      # @see https://developers.google.com/youtube/v3/docs/search/list
      def list_params
        super.tap do |params|
          params[:params] = videos_params
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
        if items.count == videos_params[:max_results]
          last_published = items.last['snippet']['publishedAt']
          @page_token, @published_before = '', last_published
        end
      end

      def videos_params
        {}.tap do |params|
          params[:type] = :video
          params[:max_results] = 50
          params[:part] = videos_parts.join(',')
          params[:order] = 'date'
          params[:published_before] = @published_before if @published_before
          params.merge! @parent.videos_params if @parent
          apply_where_params! params
        end
      end

      def videos_parts
        @included_parts.push(:snippet).map do |part|
          part.to_s.camelize :lower
        end.uniq
      end

      def videos_path
        use_list_endpoint? ? '/youtube/v3/videos' : '/youtube/v3/search'
      end

      # @private
      # YouTube API provides two different endpoints to get a list of videos:
      # /videos should be used when the query specifies video IDs or a chart,
      # /search otherwise.
      # @return [Boolean] whether to use the /videos endpoint.
      # @todo: This is one of two places outside of base.rb where @where_params
      #   is accessed; it should be replaced with a filter on params instead.
      def use_list_endpoint?
        @parent.nil? && (@where_params.keys & [:id, :chart]).any?
      end
    end
  end
end