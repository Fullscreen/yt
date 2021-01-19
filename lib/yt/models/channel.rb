require 'yt/models/resource'

module Yt
  module Models
    # Provides methods to interact with YouTube channels.
    # @see https://developers.google.com/youtube/v3/docs/channels
    class Channel < Resource

    ### SNIPPET ###

      # @!attribute [r] title
      #   @return [String] the channel’s title.
      delegate :title, to: :snippet

      # @!attribute [r] description
      #   @return [String] the channel’s description.
      delegate :description, to: :snippet

      # @!method thumbnail_url(size = :default)
      #   Returns the URL of the channel’s thumbnail.
      #   @param [Symbol, String] size The size of the channel’s thumbnail.
      #   @return [String] if +size+ is +default+, the URL of a 88x88px image.
      #   @return [String] if +size+ is +medium+, the URL of a 240x240px image.
      #   @return [String] if +size+ is +high+, the URL of a 800x800px image.
      #   @return [nil] if the +size+ is not +default+, +medium+ or +high+.
      delegate :thumbnail_url, to: :snippet

      # @!attribute [r] published_at
      #   @return [Time] the date and time that the channel was created.
      delegate :published_at, to: :snippet

    ### STATUS ###

      # @!attribute [r] made_for_kids?
      #   @return [Boolean, nil] This value indicates whether the channel is
      #     designated as child-directed, and it contains the current "made for
      #     kids" status of the channel.
      def made_for_kids?
        status.made_for_kids
      end

      # @!attribute [r] self_declared_made_for_kids?
      #   @return [Boolean, nil] In a channels.update request, this property
      #     allows the channel owner to designate the channel as
      #     child-directed. The property value is only returned if the channel
      #     owner authorized the API request.
      def self_declared_made_for_kids?
        status.self_declared_made_for_kids
      end

    ### SUBSCRIPTION ###

      has_one :subscription

      # @return [Boolean] whether the account is subscribed to the channel.
      # @raise [Yt::Errors::Unauthorized] if {Resource#auth auth} is not an
      #   authenticated Yt::Account.
      def subscribed?
        sleep [(@subscriptions_updated_at || Time.now) - Time.now, 0].max
        subscription.exists?
      rescue Errors::NoItems
        false
      end

      # Subscribes the authenticated account to the channel.
      # Unlike {#subscribe!}, does not raise an error if already subscribed.
      # @raise [Yt::Errors::Unauthorized] if {Resource#auth auth} is not an
      #   authenticated Yt::Account.
      def subscribe
        subscriptions.insert(ignore_errors: true).tap do |subscription|
          throttle_subscriptions
          @subscription = subscription
        end
      end

      # Subscribes the authenticated account to the channel.
      # Unlike {#subscribe}, raises an error if already subscribed.
      # @raise [Yt::Errors::RequestError] if already subscribed.
      # @raise [Yt::Errors::Unauthorized] if {Resource#auth auth} is not an
      #   authenticated Yt::Account.
      def subscribe!
        subscriptions.insert.tap do |subscription|
          throttle_subscriptions
          @subscription = subscription
        end
      end

      # Unsubscribes the authenticated account from the channel.
      # Unlike {#unsubscribe!}, does not raise an error if already unsubscribed.
      # @raise [Yt::Errors::Unauthorized] if {Resource#auth auth} is not an
      #   authenticated Yt::Account.
      def unsubscribe
        unsubscribe! if subscribed?
      end

      # Unsubscribes the authenticated account from the channel.
      # Unlike {#unsubscribe}, raises an error if already unsubscribed.
      #
      # @raise [Yt::Errors::RequestError] if already unsubscribed.
      # @raise [Yt::Errors::Unauthorized] if {Resource#auth auth} is not an
      #   authenticated Yt::Account.
      def unsubscribe!
        subscription.delete.tap{ throttle_subscriptions }
      end

    ### ASSOCIATIONS ###

      # @!attribute [r] videos
      #   @return [Yt::Collections::Videos] the channel’s videos.
      has_many :videos

      # @!attribute [r] playlists
      #   @return [Yt::Collections::Playlists] the channel’s playlists.
      has_many :playlists

      # @!attribute [r] related_playlists
      #   @return [Yt::Collections::Playlists] the playlists associated with the
      #     channel, such as the playlist of uploaded or liked videos.
      #   @see https://developers.google.com/youtube/v3/docs/channels#contentDetails.relatedPlaylists
      has_many :related_playlists

      # @!attribute [r] subscribed_channels
      #   @return [Yt::Collections::SubscribedChannels] the channels that this
      #     channel is subscribed to.
      #   @raise [Yt::Errors::Forbidden] if the owner of the channel has
      #     explicitly select the option to keep all subscriptions private.
      has_many :subscribed_channels

    ### ANALYTICS ###

      # @macro reports

      # @macro report_by_channel_dimensions
      has_report :views, Integer

      # @macro report_by_channel_dimensions
      has_report :estimated_minutes_watched, Integer

      # @macro report_by_gender_and_age_group
      has_report :viewer_percentage, Float

      # @macro report_by_day_and_country
      has_report :comments, Integer

      # @macro report_by_day_and_country
      has_report :likes, Integer

      # @macro report_by_day_and_country
      has_report :dislikes, Integer

      # @macro report_by_day_and_country
      has_report :shares, Integer

      # @macro report_by_day_and_country
      has_report :subscribers_gained, Integer

      # @macro report_by_day_and_country
      has_report :subscribers_lost, Integer

      # @macro report_by_day_and_country
      has_report :videos_added_to_playlists, Integer

      # @macro report_by_day_and_country
      has_report :videos_removed_from_playlists, Integer

      # @macro report_by_day_and_state
      has_report :average_view_duration, Integer

      # @macro report_by_day_and_state
      has_report :average_view_percentage, Float

      # @macro report_by_day_and_state
      has_report :annotation_clicks, Integer

      # @macro report_by_day_and_state
      has_report :annotation_click_through_rate, Float

      # @macro report_by_day_and_state
      has_report :annotation_close_rate, Float

      # @macro report_by_day_and_state
      has_report :card_impressions, Integer

      # @macro report_by_day_and_state
      has_report :card_clicks, Integer

      # @macro report_by_day_and_state
      has_report :card_click_rate, Float

      # @macro report_by_day_and_state
      has_report :card_teaser_impressions, Integer

      # @macro report_by_day_and_state
      has_report :card_teaser_clicks, Integer

      # @macro report_by_day_and_state
      has_report :card_teaser_click_rate, Float

      # @macro report_by_day_and_country
      has_report :estimated_revenue, Float

      # @macro report_by_day_and_country
      has_report :ad_impressions, Integer

      # @macro report_by_day_and_country
      has_report :monetized_playbacks, Integer

      # @macro report_by_day_and_country
      has_report :playback_based_cpm, Float

    ### STATISTICS ###

      has_one :statistics_set

      # @!attribute [r] view_count
      #   @return [Integer] the number of times the channel has been viewed.
      delegate :view_count, to: :statistics_set

      # @!attribute [r] video_count
      #   @return [Integer] the number of videos uploaded to the channel.
      delegate :video_count, to: :statistics_set

      # @!attribute [r] subscriber_count
      #   @return [Integer] the number of subscriber the channel has.
      delegate :subscriber_count, to: :statistics_set

      # @return [Boolean] whether the number of subscribers is publicly visible.
      def subscriber_count_visible?
        statistics_set.hidden_subscriber_count == false
      end

    ### CONTENT OWNER DETAILS ###

      has_one :content_owner_detail

      # @!attribute [r] content_owner
      #   The name of the content owner linked to the channel.
      #   @return [String] if the channel is partnered, its content owner’s name.
      #   @return [nil] if the channel is not partnered or if {Resource#auth auth}
      #     is a content owner without permissions to administer the channel.
      #   @raise [Yt::Errors::Forbidden] if {Resource#auth auth} does not
      #     return an authenticated content owner.
      delegate :content_owner, to: :content_owner_detail

      # Returns the time the channel was partnered to a content owner.
      # @return [Time] if the channel is partnered, the time when it was linked
      #   to its content owner.
      # @return [nil] if the channel is not partnered or if {Resource#auth auth}
      #   is a content owner without permissions to administer the channel.
      # @raise [Yt::Errors::Forbidden] if {Resource#auth auth} does not
      #   return an authenticated content owner.
      def linked_at
        content_owner_detail.time_linked
      end

    ### BRANDING SETTINGS ###

      has_one :branding_setting

    ### ACTIONS (UPLOAD, UPDATE, DELETE) ###

      # Deletes the channel’s playlists matching all the given attributes.
      # @return [Array<Boolean>] whether each playlist matching the given
      #   attributes was deleted.
      # @raise [Yt::Errors::RequestError] if {Resource#auth auth} is not an
      #   authenticated Yt::Account with permissions to update the channel.
      # @param [Hash] attributes the attributes to match the playlists by.
      # @option attributes [<String, Regexp>] :title The playlist’s title.
      #   Pass a String for perfect match or a Regexp for advanced match.
      # @option attributes [<String, Regexp>] :description The playlist’s
      #   description. Pass a String (perfect match) or a Regexp (advanced).
      # @option attributes [Array<String>] :tags The playlist’s tags.
      #   All tags must match exactly.
      # @option attributes [String] :privacy_status The playlist’s privacy
      #   status.
      def delete_playlists(attributes = {})
        playlists.delete_all attributes
      end

    ### PRIVATE API ###

      # @private
      # Override Resource's new to set statistics as well
      # if the response includes them
      def initialize(options = {})
        super options
        if options[:statistics]
          @statistics_set = StatisticsSet.new data: options[:statistics]
        end
        if options[:content_owner_details]
          @content_owner_detail = ContentOwnerDetail.new data: options[:content_owner_details]
        end
        if options[:branding_settings]
          @branding_setting = BrandingSetting.new data: options[:branding_settings]
        end
      end

      # @private
      # Tells `has_many :videos` that channel.videos should return all the
      # videos publicly available on the channel.
      def videos_params
        {channel_id: id}
      end

      # @private
      # Tells `has_reports` to retrieve the reports from YouTube Analytics API
      # either as a Channel or as a Content Owner.
      # @see https://developers.google.com/youtube/analytics/channel_reports
      # @see https://developers.google.com/youtube/analytics/content_owner_reports
      def reports_params
        {}.tap do |params|
          if auth.owner_name
            params[:ids] = "contentOwner==#{auth.owner_name}"
            params[:filters] = "channel==#{id}"
          else
            params[:ids] = "channel==#{id}"
          end
        end
      end

      # @private
      # Tells `has_one :content_owner_detail` to retrieve the content owner
      # detail as the Content Owner, it the channel was authorized with one.
      # If it was not, the call will fail, since YouTube only allows content
      # owners to check who is the content owner of a channel.
      def content_owner_details_params
        {on_behalf_of_content_owner: auth.owner_name || auth.id}
      end

      # @private
      # @note Google API must have some caching layer by which if we try to
      # delete a subscription that we just created, we encounter an error.
      # To overcome this, if we have just updated the subscription, we must
      # wait some time before requesting it again.
      def throttle_subscriptions(seconds = 10)
        @subscriptions_updated_at = Time.now + seconds
      end
    end
  end
end
