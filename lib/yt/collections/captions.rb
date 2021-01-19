require 'yt/collections/base'

module Yt
  module Collections
    # @private
    class Captions < Base

    private

      def attributes_for_new_item(data)
        {}.tap do |attributes|
          attributes[:id] = data['id']
          attributes[:snippet] = data['snippet']
          attributes[:auth] = @auth
        end
      end

      def list_params
        super.tap do |params|
          params[:path] = "/youtube/v3/captions"
          params[:params] = captions_params
        end
      end

      def captions_params
        apply_where_params!({part: 'snippet'}).tap do |params|
          params[:videoId] = @parent.id
        end
      end
    end
  end
end
