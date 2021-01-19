require 'open-uri'
require 'yt/models/base'

module Yt
  module Models
    # Provides methods to interact with YouTube accounts.
    # @see https://developers.google.com/youtube/v3/guides/authentication
    class Account < Base

    ### USER INFO ###

      has_one :user_info

      # @!attribute [r] id
      #   @return [String] the (Google+) account’s ID.
      delegate :id, to: :user_info

      # @!attribute [r] email
      #   @return [String] the account’s email address.
      delegate :email, to: :user_info

      # @return [Boolean] whether the email address is verified.
      def has_verified_email?
        user_info.verified_email
      end

      # @!attribute [r] name
      #   @return [String] the account’s full name.
      delegate :name, to: :user_info

      # @!attribute [r] given_name
      #   @return [String] the user’s given (first) name.
      delegate :given_name, to: :user_info

      # @!attribute [r] family_name
      #   @return [String] the user’s family (last) name.
      delegate :family_name, to: :user_info

      # @return [String] the URL of the account’s (Google +) profile page.
      def profile_url
        user_info.link
      end

      # @return [String] the URL of the account’s (Google +) profile picture.
      def avatar_url
        user_info.picture
      end

      # @return [String] the account’s gender. Possible values include, but
      #   are not limited to, +'male'+, +'female'+, +'other'+.
      delegate :gender, to: :user_info

      # @return [String] the account’s preferred locale.
      delegate :locale, to: :user_info

      # @return [String] the hosted domain name for the user’s Google Apps
      #   account. For instance, example.com.
      delegate :hd, to: :user_info

    ### ACTIONS ###

      # Uploads a video to the account’s channel.
      # @param [String] path_or_url the video to upload. Can either be the
      #   path of a local file or the URL of a remote file.
      # @param [Hash] params the metadata to add to the uploaded video.
      # @option params [String] :title The video’s title.
      # @option params [String] :description The video’s description.
      # @option params [Array<String>] :tags The video’s tags.
      # @option params [String] :privacy_status The video’s privacy status.
      # @option params [Boolean] :self_declared_made_for_kids The video’s made for kids self-declaration.
      # @return [Yt::Models::Video] the newly uploaded video.
      def upload_video(path_or_url, params = {})
        file =
          if is_url(path_or_url)
            fetch_remote_file(path_or_url)
          else
            open path_or_url, 'rb'
          end

        session = resumable_sessions.insert file.size, upload_body(params)
        session.update(body: file) do |data|
          Yt::Video.new(
            id: data['id'],
            snippet: data['snippet'],
            status: data['status'],
            auth: self
          )
        end
      end

      def is_url(path_or_url)
        return false
        pattern = /^(https?|ftp)/i
        pattern.match(path_or_url)
      end

      # Creates a playlist in the account’s channel.
      # @return [Yt::Models::Playlist] the newly created playlist.
      # @param [Hash] params the attributes of the playlist.
      # @option params [String] :title The new playlist’s title.
      #   Cannot have more than 100 characters. Can include the characters
      #   < and >, which are replaced to ‹ › in order to be accepted by YouTube.
      # @option params [String] :description The new playlist’s description.
      #   Cannot have more than 5000 bytes. Can include the characters
      #   < and >, which are replaced to ‹ › in order to be accepted by YouTube.
      # @option params [Array<String>] :tags The new playlist’s tags.
      #   Cannot have more than 500 characters. Can include the characters
      #   < and >, which are replaced to ‹ › in order to be accepted by YouTube.
      # @option params [String] :privacy_status The new playlist’s privacy
      #   status. Must be one of: private, unscheduled, public.
      # @example Create a playlist titled "My favorites".
      #   account.create_playlist title: 'My favorites'
      def create_playlist(params = {})
        playlists.insert params
      end

      # @!method delete_playlists(attributes = {})
      #   Deletes the account’s playlists matching all the given attributes.
      #   @return [Array<Boolean>] whether each playlist matching the given
      #     attributes was deleted.
      #   @param [Hash] attributes the attributes to match the playlists by.
      #   @option attributes [<String, Regexp>] :title The playlist’s title.
      #     Pass a String for perfect match or a Regexp for advanced match.
      #   @option attributes [<String, Regexp>] :description The playlist’s
      #     description. Pass a String (perfect match) or a Regexp (advanced).
      #   @option attributes [Array<String>] :tags The playlist’s tags.
      #     All tags must match exactly.
      #   @option attributes [String] :privacy_status The playlist’s privacy
      #     status.
      delegate :delete_playlists, to: :channel

    ### CONTENT OWNERS ###

      # @!attribute [r] content_owners
      #   @return [Yt::Collections::ContentOwners] the content owners that
      #     the account can manage.
      has_many :content_owners

      # The name of the content owner managing the account.
      # @return [String] name of the CMS account, if the account is partnered.
      # @return [nil] if the account is not a partnered content owner.
      attr_reader :owner_name

    ### ASSOCIATIONS ###

      # @!attribute [r] channel
      #   @return [Yt::Models::Channel] the YouTube channel of the account.
      has_one :channel

      # @!attribute [r] playlists
      #   @return [Yt::Collections::Playlists] the playlists owned by the account.
      delegate :playlists, to: :channel

      # @!attribute [r] related_playlists
      #   @return [Yt::Collections::Playlists] the playlists associated with the
      #     account, such as the playlist of uploaded or liked videos.
      #   @see https://developers.google.com/youtube/v3/docs/channels#contentDetails.relatedPlaylists
      delegate :related_playlists, to: :channel

      # @!attribute [r] subscribed_channels
      #   @return [Yt::Collections::SubscribedChannels] the channels that the
      #     account is subscribed to.
      delegate :subscribed_channels, to: :channel

      # @!attribute [r] videos
      #   @return [Yt::Collections::Videos] the videos owned by the account.
      has_many :videos

      # @!attribute [r] subscribers
      #   @return [Yt::Collections::Subscribers] the channels subscribed to
      #     the account’s channel.
      has_many :subscribers

      # @!attribute [r] resumable_sessions
      #   @private
      #   @return [Yt::Collections::ResumableSessions] the sessions used to
      #     upload videos using the resumable upload protocol.
      has_many :resumable_sessions

      # @!attribute [r] video_groups
      #   @return [Yt::Collections::VideoGroups] the video-groups created by the
      #     account.
      has_many :video_groups

    ### PRIVATE API ###

      has_authentication

      # @private
      # Initialize user info if included in the response
      def initialize(options = {})
        super options
        if options[:user_info]
          @user_info = UserInfo.new data: options[:user_info]
        end
      end

      # @private
      # Tells `has_many :videos` that account.videos should return all the
      # videos *owned by* the account (public, private, unlisted).
      def videos_params
        {for_mine: true}
      end

      # @private
      # Tells `has_many :video_groups` that content_owner.groups should return
      # all the video-groups *owned by* the account
      def video_groups_params
        {mine: true}
      end

      def playlist_items_params
        {}
      end

      # @private
      # Tells `has_many :resumable_sessions` what path to hit to upload a file.
      def upload_path
        '/upload/youtube/v3/videos'
      end
      # @private
      # Tells `has_many :resumable_sessions` what params are set for the object
      # associated to the uploaded file.
      def upload_params
        {part: 'snippet,status'}
      end

      # @private
      # Tells `has_many :resumable_sessions` what metadata to set in the object
      # associated to the uploaded file.
      def upload_body(params = {})
        {}.tap do |body|
          snippet = params.slice :title, :description, :tags, :category_id
          snippet[:categoryId] = snippet.delete(:category_id) if snippet[:category_id]
          body[:snippet] = snippet if snippet.any?

          privacy_status = params[:privacy_status]
          self_declared_made_for_kids = params[:self_declared_made_for_kids]

          body[:status] = {}
          body[:status][:privacyStatus] = privacy_status if privacy_status
          body[:status][:selfDeclaredMadeForKids] = self_declared_made_for_kids unless self_declared_made_for_kids.nil?
        end
      end

      # @private
      # Tells `has_many :resumable_sessions` what type of file can be uploaded.
      def upload_content_type
        'video/*'
      end

      def update_video_params
        {}
      end

      def update_playlist_params
        {}
      end

      def upload_thumbnail_params
        {}
      end

      def insert_playlist_item_params
        {}
      end
    end
  end
end
