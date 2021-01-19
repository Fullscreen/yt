require 'yt/models/resource'

module Yt
  module Models
    # Provides methods to interact with YouTube videos.
    # @see https://developers.google.com/youtube/v3/docs/videos
    class Video < Resource

    ### SNIPPET ###

      # @!attribute [r] title
      #   @return [String] the video’s title.
      delegate :title, to: :snippet

      # @!attribute [r] description
      #   @return [String] the video’s description.
      delegate :description, to: :snippet

      # @!method thumbnail_url(size = :default)
      #   Returns the URL of the video’s thumbnail.
      #   @param [Symbol, String] size The size of the video’s thumbnail.
      #   @return [String] if +size+ is +default+, the URL of a 120x90px image.
      #   @return [String] if +size+ is +medium+, the URL of a 320x180px image.
      #   @return [String] if +size+ is +high+, the URL of a 480x360px image.
      #   @return [nil] if the +size+ is not +default+, +medium+ or +high+.
      delegate :thumbnail_url, to: :snippet

      # @!attribute [r] published_at
      #   @return [Time] the date and time that the video was published.
      delegate :published_at, to: :snippet

      # @!attribute [r] channel_id
      #   @return [String] the ID of the channel that the video belongs to.
      delegate :channel_id, to: :snippet

      # @!attribute [r] channel_title
      #   @return [String] the title of the channel that the video belongs to.
      delegate :channel_title, to: :snippet

      # @return [<String>] the URL of the channel that the video belongs to.
      def channel_url
        "https://www.youtube.com/channel/#{channel_id}"
      end

      # @!attribute [r] live_broadcast_content
      #   @return [String] the type of live broadcast that the video contains.
      #     Possible values are: +'live'+, +'none'+, +'upcoming'+.
      delegate :live_broadcast_content, to: :snippet

      # @return [Array<String>] the list of tags attached to the video.
      def tags
        ensure_complete_snippet :tags
      end

      # @return [String] ID of the YouTube category associated with the video.
      def category_id
        ensure_complete_snippet :category_id
      end

    ### STATUS ###

      # @return [Boolean] whether the video was deleted by the user.
      def deleted?
        status.upload_status == 'deleted'
      end

      # @return [Boolean] whether the video failed to upload.
      def failed?
        status.upload_status == 'failed'
      end

      # @return [Boolean] whether the video has been fully processed by YouTube.
      def processed?
        status.upload_status == 'processed'
      end

      # @return [Boolean] whether the video was rejected by YouTube.
      def rejected?
        status.upload_status == 'rejected'
      end

      # @return [Boolean] whether the video is being uploaded to YouTube.
      def uploading?
        status.upload_status == 'uploaded'
      end

      # @return [Boolean] whether the video failed to upload to YouTube because
      #   of an unsupported codec.
      # @see https://support.google.com/youtube/answer/1722171
      def uses_unsupported_codec?
        status.failure_reason == 'codec'
      end

      # @return [Boolean] whether the video failed to upload to YouTube because
      #   YouTube was unable to convert the video.
      def has_failed_conversion?
        status.failure_reason == 'conversion'
      end

      # @return [Boolean] whether the video failed to upload to YouTube because
      #   the video file is empty.
      def empty?
        status.failure_reason == 'emptyFile'
      end

      # @return [Boolean] whether the video failed to upload to YouTube because
      #   the video uses an unsupported file format.
      # @see https://support.google.com/youtube/troubleshooter/2888402?hl=en
      def invalid?
        status.failure_reason == 'invalidFile'
      end

      # @return [Boolean] whether the video failed to upload to YouTube because
      #   the video file is too small for YouTube.
      def too_small?
        status.failure_reason == 'tooSmall'
      end

      # @return [Boolean] whether the video failed to upload to YouTube because
      #   the uploading process was aborted.
      def aborted?
        status.failure_reason == 'uploadAborted'
      end

      # @return [Boolean] whether the video was rejected by YouTube because
      #   the video was claimed by a different account.
      def claimed?
        status.rejection_reason == 'claim'
      end

      # @return [Boolean] whether the video was rejected by YouTube because
      #   the video commits a copyright infringement.
      def infringes_copyright?
        status.rejection_reason == 'copyright'
      end

      # @return [Boolean] whether the video was rejected by YouTube because
      #   the video is a duplicate of another video.
      def duplicate?
        status.rejection_reason == 'duplicate'
      end

      # @return [Boolean] whether the video was rejected by YouTube because
      #   the video contains inappropriate content.
      def inappropriate?
        status.rejection_reason == 'inappropriate'
      end

      # @return [Boolean] whether the video was rejected by YouTube because
      #   the video exceeds the maximum duration for YouTube.
      # @see https://support.google.com/youtube/answer/71673?hl=en
      def too_long?
        status.rejection_reason == 'length'
      end

      # @return [Boolean] whether the video was rejected by YouTube because
      #   the video violates the Terms of Use.
      def violates_terms_of_use?
        status.rejection_reason == 'termsOfUse'
      end

      # @return [Boolean] whether the video was rejected by YouTube because
      #   the video infringes a trademark.
      # @see https://support.google.com/youtube/answer/2801979?hl=en
      def infringes_trademark?
        status.rejection_reason == 'trademark'
      end

      # @return [Boolean] whether the video was rejected by YouTube because
      #   the account that uploaded the video has been closed.
      def belongs_to_closed_account?
        status.rejection_reason == 'uploaderAccountClosed'
      end

      # @return [Boolean] whether the video was rejected by YouTube because
      #   the account that uploaded the video has been suspended.
      def belongs_to_suspended_account?
        status.rejection_reason == 'uploaderAccountSuspended'
      end

      # Returns the time when a video is scheduled to be published.
      # @return [Time] if the video is scheduled to be published, the time
      #   when it will become public.
      # @return [nil] if the video is not scheduled to be published.
      def scheduled_at
        status.publish_at if scheduled?
      end

      # @return [Boolean] whether the video is scheduled to be published.
      def scheduled?
        private? && status.publish_at
      end

      # @!attribute [r] license
      #   @return [String] the video’s license. Possible values are:
      #     +'creativeCommon'+, +'youtube'+.
      delegate :license, to: :status

      # @return [Boolean] whether the video uses the Standard YouTube license.
      # @see https://www.youtube.com/static?template=terms
      def licensed_as_standard_youtube?
        license == 'youtube'
      end

      # @return [Boolean] whether the video uses a Creative Commons license.
      # @see https://support.google.com/youtube/answer/2797468?hl=en
      def licensed_as_creative_commons?
        license == 'creativeCommon'
      end

      # Returns whether the video statistics are publicly viewable.
      # @return [Boolean] if the resource is a video, whether the extended
      #   video statistics on the video’s watch page are publicly viewable.
      #   By default, those statistics are viewable, and statistics like a
      #   video’s viewcount and ratings will still be publicly visible even
      #   if this property’s value is set to false.
      def has_public_stats_viewable?
        status.public_stats_viewable
      end

      # @return [Boolean] whether the video can be embedded on other websites.
      def embeddable?
        status.embeddable
      end

      #   @return [Boolean, nil] This value indicates whether the video is
      #     designated as child-directed, and it contains the current "made for
      #     kids" status of the video.
      def made_for_kids?
        status.made_for_kids
      end

      #   @return [Boolean, nil] In a videos.insert or videos.update request,
      #     this property allows the channel owner to designate the video as
      #     being child-directed. In a videos.list request, the property value
      #     is only returned if the channel owner authorized the API request.
      def self_declared_made_for_kids?
        status.self_declared_made_for_kids
      end

    ### CONTENT DETAILS ###

      has_one :content_detail

      # @!attribute [r] duration
      #   @return [Integer] the duration of the video (in seconds).
      delegate :duration, to: :content_detail

      # @!attribute [r] duration
      #   @return [String] the length of the video as an ISO 8601 time, HH:MM:SS.
      delegate :length, to: :content_detail

      # @return [Boolean] whether the video is available in 3D.
      def stereoscopic?
        content_detail.dimension == '3d'
      end

      # @return [Boolean] whether the video is available in high definition.
      def hd?
        content_detail.definition == 'hd'
      end

      # @return [Boolean] whether captions are available for the video.
      def captioned?
        content_detail.caption == 'true'
      end

      # @return [Boolean] whether the video represents licensed content, which
      #   means that the content has been claimed by a YouTube content partner.
      def licensed?
        content_detail.licensed_content || false
      end

      # @return [Boolean] whether the video is identified by YouTube as
      #   age-restricted content.
      def age_restricted?
        content_detail.youtube_rating == 'ytAgeRestricted'
      end

    ### FILE DETAILS ###

      has_one :file_detail

      # @!attribute [r] file_name
      #   @return [String] the name of the uploaded file.
      delegate :file_name, to: :file_detail

      # @!attribute [r] file_size
      #   @return [Integer] the size of the uploaded file (in bytes).
      delegate :file_size, to: :file_detail

      # @!attribute [r] file_type
      #   @return [String] the type of file uploaded. May be one of:
      #     archive, audio, document, image, other, project, video.
      delegate :file_type, to: :file_detail

      # @!attribute [r] container
      #   @return [String] the video container of the uploaded file. (e.g. 'mov').
      delegate :container, to: :file_detail


    ### RATING ###

      has_one :rating

      # @return [Boolean] whether the authenticated account likes the video.
      # @raise [Yt::Errors::Unauthorized] if {Resource#auth auth} is not an
      #   authenticated Yt::Account.
      def liked?
        rating.rating == :like
      end

      # Likes the video on behalf of the authenticated account.
      # @return [Boolean] whether the authenticated account likes the video.
      # @raise [Yt::Errors::Unauthorized] if {Resource#auth auth} is not an
      #   authenticated Yt::Account.
      def like
        rating.set :like
        liked?
      end

      # Dislikes the video on behalf of the authenticated account.
      # @return [Boolean] whether the account does not like the video.
      # @raise [Yt::Errors::Unauthorized] if {Resource#auth auth} is not an
      #   authenticated Yt::Account.
      def dislike
        rating.set :dislike
        !liked?
      end

      # Resets the rating of the video on behalf of the authenticated account.
      # @return [Boolean] whether the account does not like the video.
      # @raise [Yt::Errors::Unauthorized] if {Resource#auth auth} is not an
      #   authenticated Yt::Account.
      def unlike
        rating.set :none
        !liked?
      end

    ### VIDEO CATEGORY ###

      has_one :video_category

      # @return [String] the video category’s title.
      def category_title
        video_category.title
      end

    ### ADVERTISING OPTIONS ###

      has_one :advertising_options_set

      # @!attribute [r] ad_formats
      #   @return [Array<String>] the list of ad formats that the video is
      #     allowed to show. Possible values are: +'long'+, +'overlay'+,
      #     +'standard_instream'+, +'third_party'+, +'trueview_inslate'+,
      #     +'trueview_instream'+.
      delegate :ad_formats, to: :advertising_options_set

    ### LIVE STREAMING DETAILS ###

      has_one :live_streaming_detail

      # @!attribute [r] actual_start_time
      #   The time when a live broadcast started.
      #   @return [Time] if the broadcast has begun, the time it actually started.
      #   @return [nil] if the broadcast has not begun or video is not live.
      delegate :actual_start_time, to: :live_streaming_detail

      # @!attribute [r] actual_end_time
      #   The time when a live broadcast ended.
      #   @return [Time] if the broadcast is over, the time it actually ended.
      #   @return [nil] if the broadcast is not over or video is not live.
      delegate :actual_end_time, to: :live_streaming_detail

      # @!attribute [r] scheduled_start_time
      #   The time when a live broadcast is scheduled to start.
      #   @return [Time] the time that the broadcast is scheduled to begin.
      #   @return [nil] if video is not live.
      delegate :scheduled_start_time, to: :live_streaming_detail

      # @!attribute [r] scheduled_end_time
      #   The time when a live broadcast is scheduled to end.
      #   @return [Time] if the broadcast is scheduled to end, the time it is
      #     scheduled to end.
      #   @return [nil] if the broadcast is scheduled to continue indefinitely
      #     or the video is not live.
      delegate :scheduled_end_time, to: :live_streaming_detail

      # @!attribute [r] concurrent_viewers
      #   The number of current viewers of a live broadcast.
      #   @return [Integer] if the broadcast has current viewers and the
      #     broadcast owner has not hidden the viewcount for the video, the
      #     number of viewers currently watching the broadcast.
      #   @return [nil] if the broadcast has ended or the broadcast owner has
      #     hidden the viewcount for the video or the video is not live.
      delegate :concurrent_viewers, to: :live_streaming_detail

    ### ASSOCIATIONS ###
      has_many :captions

      # @!attribute [r] comments
      #   @return [Yt::Collections::Comments] the video’s comments.
      has_many :comment_threads

      # @!attribute [r] annotations
      #   @return [Yt::Collections::Annotations] the video’s annotations.
      has_many :annotations

      has_many :resumable_sessions

      # @!attribute [r] claim
      #   @return [Yt::Models::Claim, nil] the first claim on the video by
      #     the content owner of the video, if eagerly loaded.
      def claim
        @claim
      end

    ### ANALYTICS ###

      # @macro reports

      # @macro report_by_video_dimensions
      has_report :views, Integer

      # @macro report_by_video_dimensions
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

      # @note This is not the total number of subscribers gained by the video’s
      #   channel, but the subscribers gained *from* the video’s page.
      # @macro report_by_day_and_country
      has_report :subscribers_gained, Integer

      # @note This is not the total number of subscribers lost by the video’s
      #   channel, but the subscribers lost *from* the video’s page.
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
      #   @return [Integer] the number of times the video has been viewed.
      delegate :view_count, to: :statistics_set

      # @!attribute [r] like_count
      #   @return [Integer] the number of users who liked the video.
      delegate :like_count, to: :statistics_set

      # @!attribute [r] dislike_count
      #   @return [Integer] the number of users who disliked the video.
      delegate :dislike_count, to: :statistics_set

      # @!attribute [r] favorite_count
      #   @return [Integer] the number of users who marked the video as favorite.
      delegate :favorite_count, to: :statistics_set

      # @!attribute [r] comment_count
      #   @return [Integer] the number of comments for the video.
      delegate :comment_count, to: :statistics_set

    ### PLAYER ###

      has_one :player

      # @!attribute [r] embed_html
      #   @return [String] the HTML code of an <iframe> tag that embeds a
      #     player that will play the video.
      delegate :embed_html, to: :player

    ### ACTIONS (UPLOAD, UPDATE, DELETE) ###

      # Uploads a thumbnail
      # @param [String] path_or_url the image to upload. Can either be the
      #   path of a local file or the URL of a remote file.
      # @return the new thumbnail resource for the given image.
      # @raise [Yt::Errors::RequestError] if path_or_url is not a valid path
      #   or URL.
      def upload_thumbnail(path_or_url)
        file = open(path_or_url, 'rb') rescue StringIO.new
        session = resumable_sessions.insert file.size

        session.update(body: file) do |data|
          snippet.instance_variable_set :@thumbnails, data['items'].first
        end
      end

      # Deletes the video on behalf of the authenticated account.
      # @return [Boolean] whether the video does not exist anymore.
      # @raise [Yt::Errors::Unauthorized] if {Resource#auth auth} is not an
      #   authenticated Yt::Account with permissions to delete the video.
      def delete(options = {})
        do_delete {@id = nil}
        !exists?
      end

      # Updates the attributes of a video.
      # @return [Boolean] whether the video was successfully updated.
      # @raise [Yt::Errors::Unauthorized] if {Resource#auth auth} is not an
      #   authenticated Yt::Account with permissions to update the video.
      # @param [Hash] attributes the attributes to update.
      # @option attributes [String] :title The new video’s title.
      #   Cannot have more than 100 characters. Can include the characters
      #   < and >, which are replaced to ‹ › in order to be accepted by YouTube.
      # @option attributes [String] :description The new video’s description.
      #   Cannot have more than 5000 bytes. Can include the characters
      #   < and >, which are replaced to ‹ › in order to be accepted by YouTube.
      # @option attributes [Array<String>] :tags The new video’s tags.
      #   Cannot have more than 500 characters. Can include the characters
      #   < and >, which are replaced to ‹ › in order to be accepted by YouTube.
      # @option attributes [String] :category_id The new video’s category ID.
      # @option attributes [String] :privacy_status The new video’s privacy
      #   status. Must be one of: private, unscheduled, public.
      # @option attributes [Boolean] :embeddable The new value to specify
      #   whether the video can be embedded on other websites.
      # @option attributes [String] :license The new video’s license. Must be
      #   one of: youtube, creativeCommon.
      # @option attributes [Boolean] :public_stats_viewable The new value to
      #   specify whether the video’s statistics are publicly viewable.
      # @option attributes :publish_at The new timestamp when the video will be
      #   made public. Must be in ISO 8601 format (YYYY-MM-DDThh:mm:ss.sZ).
      # @example Update title and description of a video.
      #   video.update title: 'New title', description: 'New description'
      # @example Update tags and category ID of a video.
      #   video.update tags: ['new', 'tags'], category_id: '22'
      # @example Update status of a video.
      #   video.update privacy_status: 'public', public_stats_viewable: true
      # @example Update visibility/license of a video.
      #   video.update embeddable: true, license: :youtube
      # @example Update the time when a private video will become public.
      #   video.update publish_at: 3.days.from_now.utc.iso8601(3)
      def update(attributes = {})
        super
      end

    ### PRIVATE API ###

      # @private
      # Override Resource's new to set statistics and content details as well
      # if the response includes them
      def initialize(options = {})
        super options
        if options[:statistics]
          @statistics_set = StatisticsSet.new data: options[:statistics]
        end
        if options[:content_details]
          @content_detail = ContentDetail.new data: options[:content_details]
        end
        if options[:file_details]
          @file_detail = FileDetail.new data: options[:file_details]
        end
        if options[:live_streaming_details]
          @live_streaming_detail = LiveStreamingDetail.new data: options[:live_streaming_details]
        end
        if options[:video_category]
          @video_category = VideoCategory.new data: options[:video_category]
        end
        if options[:player]
          @player = Player.new data: options[:player]
        end
        if options[:claim]
          @claim = options[:claim]
        end
      end

      # @private
      def exists?
        !@id.nil?
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
          else
            params[:ids] = "channel==#{channel_id}"
          end
          params[:filters] = "video==#{id}"
        end
      end

      # @private
      # Tells `has_many :resumable_sessions` what path to hit to upload a file.
      def upload_path
        '/upload/youtube/v3/thumbnails/set'
      end

      # @private
      # Tells `has_many :resumable_sessions` what params are set for the object
      # associated to the uploaded file.
      # https://developers.google.com/youtube/v3/docs/thumbnails/set
      def upload_params
        params = {video_id: id}
        params.merge! auth.upload_thumbnail_params
        params
      end

      # @private
      # Tells `has_many :resumable_sessions` what type of file can be uploaded.
      def upload_content_type
        'application/octet-stream'
      end

    private

      # TODO: instead of having Video, Playlist etc override this method,
      #       they should define *what* can be updated in their own *update*
      #       method.
      # @see https://developers.google.com/youtube/v3/docs/videos/update
      # @todo: Add recording details keys
      def update_parts
        snippet_keys = [:title, :description, :tags, :category_id]
        snippet = {keys: snippet_keys, sanitize_brackets: true}
        status_keys = [:privacy_status, :embeddable, :license,
          :public_stats_viewable, :publish_at, :self_declared_made_for_kids]
        {snippet: snippet, status: {keys: status_keys}}
      end

      # For updating video with content owner auth.
      # @see https://developers.google.com/youtube/v3/docs/videos/update
      def update_params
        params = super
        params[:params] ||= {}
        params[:params].merge! auth.update_video_params
        params
      end

      # NOTE: Another irrational behavior of YouTube API. If you are setting a
      # video to public/unlisted then you should *not* pass publishAt at any
      # cost, otherwise the API will fail (since setting publishAt means you
      # want the video to be private). Similarly, you should *not* pass any
      # past publishAt (for the same reason).
      def build_update_body_part(name, part, attributes = {})
        {}.tap do |body_part|
          part[:keys].map do |key|
            body_part[camelize key] = attributes.fetch key, public_send(name).public_send(key)
          end

          if (body_part[:publishAt] || 1.day.from_now) < Time.now || body_part[:privacyStatus].in?(['public', 'unlisted'])
            body_part.delete(:publishAt)
          end
        end
      end
    end
  end
end
