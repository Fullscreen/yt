# encoding: UTF-8

require 'spec_helper'
require 'yt/models/video'

describe Yt::Video, :device_app do
  subject(:video) { Yt::Video.new id: id, auth: $account }

  context 'given someone else’s video' do
    let(:id) { 'MESycYJytkU' }

    it { expect(video.content_detail).to be_a Yt::ContentDetail }

    it 'returns valid metadata' do
      expect(video.title).to be_a String
      expect(video.description).to be_a String
      expect(video.thumbnail_url).to be_a String
      expect(video.published_at).to be_a Time
      expect(video.privacy_status).to be_in Yt::Status::PRIVACY_STATUSES
      expect(video.tags).to be_an Array
      expect(video.channel_id).to be_a String
      expect(video.channel_title).to be_a String
      expect(video.category_id).to be_a String
      expect(video.live_broadcast_content).to be_in Yt::Snippet::BROADCAST_TYPES
      expect(video.view_count).to be_an Integer
      expect(video.like_count).to be_an Integer
      expect(video.dislike_count).to be_an Integer
      expect(video.favorite_count).to be_an Integer
      expect(video.comment_count).to be_an Integer
      expect(video.duration).to be_an Integer
      expect(video.hd?).to be_in [true, false]
      expect(video.stereoscopic?).to be_in [true, false]
      expect(video.captioned?).to be_in [true, false]
      expect(video.licensed?).to be_in [true, false]
      expect(video.deleted?).to be_in [true, false]
      expect(video.failed?).to be_in [true, false]
      expect(video.processed?).to be_in [true, false]
      expect(video.rejected?).to be_in [true, false]
      expect(video.uploaded?).to be_in [true, false]
      expect(video.uses_unsupported_codec?).to be_in [true, false]
      expect(video.has_failed_conversion?).to be_in [true, false]
      expect(video.empty?).to be_in [true, false]
      expect(video.invalid?).to be_in [true, false]
      expect(video.too_small?).to be_in [true, false]
      expect(video.aborted?).to be_in [true, false]
      expect(video.claimed?).to be_in [true, false]
      expect(video.infringes_copyright?).to be_in [true, false]
      expect(video.duplicate?).to be_in [true, false]
      expect(video.scheduled_at.class).to be_in [NilClass, Time]
      expect(video.scheduled?).to be_in [true, false]
      expect(video.too_long?).to be_in [true, false]
      expect(video.violates_terms_of_use?).to be_in [true, false]
      expect(video.inappropriate?).to be_in [true, false]
      expect(video.infringes_trademark?).to be_in [true, false]
      expect(video.belongs_to_closed_account?).to be_in [true, false]
      expect(video.belongs_to_suspended_account?).to be_in [true, false]
      expect(video.licensed_as_creative_commons?).to be_in [true, false]
      expect(video.licensed_as_standard_youtube?).to be_in [true, false]
      expect(video.has_public_stats_viewable?).to be_in [true, false]
      expect(video.embeddable?).to be_in [true, false]
    end

    it { expect{video.update}.to fail }
    it { expect{video.delete}.to fail.with 'forbidden' }

    context 'that I like' do
      before { video.like }
      it { expect(video).to be_liked }
      it { expect(video.dislike).to be true }
    end

    context 'that I dislike' do
      before { video.dislike }
      it { expect(video).not_to be_liked }
      it { expect(video.like).to be true }
    end

    context 'that I am indifferent to' do
      before { video.unlike }
      it { expect(video).not_to be_liked }
      it { expect(video.like).to be true }
    end
  end

  context 'given an unknown video' do
    let(:id) { 'not-a-video-id' }

    it { expect{video.content_detail}.to raise_error Yt::Errors::NoItems }
    it { expect{video.snippet}.to raise_error Yt::Errors::NoItems }
    it { expect{video.rating}.to raise_error Yt::Errors::NoItems }
    it { expect{video.status}.to raise_error Yt::Errors::NoItems }
    it { expect{video.statistics_set}.to raise_error Yt::Errors::NoItems }
  end

  context 'given one of my own videos that I want to delete' do
    before(:all) { @tmp_video = $account.upload_video 'https://bit.ly/yt_test', title: "Yt Test Delete Video #{rand}" }
    let(:id) { @tmp_video.id }

    it { expect(video.delete).to be true }
  end

  context 'given one of my own videos that I want to update' do
    let(:id) { $account.videos.first.id }
    let!(:old_title) { video.title }
    let!(:old_privacy_status) { video.privacy_status }
    let(:update) { video.update attrs }

    context 'given I update the title' do
      # NOTE: The use of UTF-8 characters is to test that we can pass up to
      # 50 characters, independently of their representation
      let(:attrs) { {title: "Yt Example Update Video #{rand} - ®•♡❥❦❧☙"} }

      specify 'only updates the title' do
        expect(update).to be true
        expect(video.title).not_to eq old_title
        expect(video.privacy_status).to eq old_privacy_status
      end
    end

    context 'given I update the description' do
      let!(:old_description) { video.description }
      let(:attrs) { {description: "Yt Example Description  #{rand} - ®•♡❥❦❧☙"} }

      specify 'only updates the description' do
        expect(update).to be true
        expect(video.description).not_to eq old_description
        expect(video.title).to eq old_title
        expect(video.privacy_status).to eq old_privacy_status
      end
    end

    context 'given I update the tags' do
      let!(:old_tags) { video.tags }
      let(:attrs) { {tags: ["Yt Test Tag #{rand}"]} }

      specify 'only updates the tag' do
        expect(update).to be true
        expect(video.tags).not_to eq old_tags
        expect(video.title).to eq old_title
        expect(video.privacy_status).to eq old_privacy_status
      end
    end

    context 'given I update the category ID' do
      let!(:old_category_id) { video.category_id }
      let!(:new_category_id) { old_category_id == '22' ? '21' : '22' }

      context 'passing the parameter in underscore syntax' do
        let(:attrs) { {category_id: new_category_id} }

        specify 'only updates the category ID' do
          expect(update).to be true
          expect(video.category_id).not_to eq old_category_id
          expect(video.title).to eq old_title
          expect(video.privacy_status).to eq old_privacy_status
        end
      end

      context 'passing the parameter in camel-case syntax' do
        let(:attrs) { {categoryId: new_category_id} }

        specify 'only updates the category ID' do
          expect(update).to be true
          expect(video.category_id).not_to eq old_category_id
        end
      end
    end

    # note: 'scheduled' videos cannot be set to 'unlisted'
    context 'given I update the privacy status' do
      before { video.update publish_at: nil if video.scheduled? }
      let!(:new_privacy_status) { old_privacy_status == 'private' ? 'unlisted' : 'private' }

      context 'passing the parameter in underscore syntax' do
        let(:attrs) { {privacy_status: new_privacy_status} }

        specify 'only updates the privacy status' do
          expect(update).to be true
          expect(video.privacy_status).not_to eq old_privacy_status
          expect(video.title).to eq old_title
        end
      end

      context 'passing the parameter in camel-case syntax' do
        let(:attrs) { {privacyStatus: new_privacy_status} }

        specify 'only updates the privacy status' do
          expect(update).to be true
          expect(video.privacy_status).not_to eq old_privacy_status
          expect(video.title).to eq old_title
        end
      end
    end

    context 'given I update the embeddable status' do
      let!(:old_embeddable) { video.embeddable? }
      let!(:new_embeddable) { !old_embeddable }

      let(:attrs) { {embeddable: new_embeddable} }

      # @note: This test is a reflection of another irrational behavior of
      #   YouTube API. Although 'embeddable' can be passed as an 'update'
      #   attribute according to the documentation, it simply does not work.
      #   The day YouTube fixes it, then this test will finally fail and will
      #   be removed, documenting how to update 'embeddable' too.
      # @see https://developers.google.com/youtube/v3/docs/videos/update
      # @see https://code.google.com/p/gdata-issues/issues/detail?id=4861
      specify 'does not update the embeddable status' do
        expect(update).to be true
        expect(video.embeddable?).to eq old_embeddable
      end
    end

    context 'given I update the license' do
      let!(:old_license) { video.license }
      let!(:new_license) { old_license == 'youtube' ? 'creativeCommon' : 'youtube' }
      let(:attrs) { {license: new_license} }

      # @note: This test is a reflection of another irrational behavior of
      #   YouTube API. Although 'license' can be passed as an 'update'
      #   attribute according to the documentation, it simply does not work.
      #   The day YouTube fixes it, then this test will finally fail and will
      #   be removed, documenting how to update 'embeddable' too.
      # @see https://developers.google.com/youtube/v3/docs/videos/update
      # @see https://code.google.com/p/gdata-issues/issues/detail?id=4861
      specify 'does not update the embeddable status' do
        expect(update).to be true
        expect(video.license).to eq old_license
      end
    end

    context 'given I update the public stats viewable setting' do
      let!(:old_public_stats_viewable) { video.has_public_stats_viewable? }
      let!(:new_public_stats_viewable) { !old_public_stats_viewable }

      context 'passing the parameter in underscore syntax' do
        let(:attrs) { {public_stats_viewable: new_public_stats_viewable} }

        specify 'only updates the public stats viewable setting' do
          expect(update).to be true
          expect(video.has_public_stats_viewable?).to eq new_public_stats_viewable
          expect(video.privacy_status).to eq old_privacy_status
          expect(video.title).to eq old_title
        end
      end

      context 'passing the parameter in camel-case syntax' do
        let(:attrs) { {publicStatsViewable: new_public_stats_viewable} }

        specify 'only updates the public stats viewable setting' do
          expect(update).to be true
          expect(video.has_public_stats_viewable?).to eq new_public_stats_viewable
          expect(video.privacy_status).to eq old_privacy_status
          expect(video.title).to eq old_title
        end
      end
    end

    # note: only 'private' video can be scheduled
    context 'given I update the timestamp to publish the video' do
      before { video.update privacy_status: 'private' unless video.private? }
      let!(:old_scheduled_at) { video.scheduled_at }
      let!(:new_scheduled_at) { (5.years.from_now.change(usec: 0).change(min: rand(60))).utc }
      context 'passing the parameter in underscore syntax' do
        let(:attrs) { {publish_at: new_scheduled_at.iso8601(3)} }

        specify 'only updates the timestamp to publish the video' do
          expect(update).to be true
          expect(video.scheduled_at).to eq new_scheduled_at
          expect(video.privacy_status).to eq old_privacy_status
          expect(video.title).to eq old_title
        end
      end

      context 'passing the parameter in camel-case syntax' do
        let(:attrs) { {publishAt: new_scheduled_at} }

        specify 'only updates the timestamp to publish the video' do
          expect(update).to be true
          expect(video.scheduled_at).to eq new_scheduled_at
          expect(video.privacy_status).to eq old_privacy_status
          expect(video.title).to eq old_title
        end
      end
    end

    it 'returns valid reports for video-related metrics' do
      # Some reports are only available to Content Owners.
      # See content ownere test for more details about what the methods return.
      expect{video.views}.not_to raise_error
      expect{video.comments}.not_to raise_error
      expect{video.likes}.not_to raise_error
      expect{video.dislikes}.not_to raise_error
      expect{video.shares}.not_to raise_error
      expect{video.earnings}.to raise_error Yt::Errors::Unauthorized
      expect{video.impressions}.to raise_error Yt::Errors::Unauthorized

      expect{video.views_on 3.days.ago}.not_to raise_error
      expect{video.comments_on 3.days.ago}.not_to raise_error
      expect{video.likes_on 3.days.ago}.not_to raise_error
      expect{video.dislikes_on 3.days.ago}.not_to raise_error
      expect{video.shares_on 3.days.ago}.not_to raise_error
      expect{video.earnings_on 3.days.ago}.to raise_error Yt::Errors::Unauthorized
      expect{video.impressions_on 3.days.ago}.to raise_error Yt::Errors::Unauthorized
    end

    it 'returns valid reports for video-related demographics' do
      expect{video.viewer_percentages}.not_to raise_error
      expect{video.viewer_percentage}.not_to raise_error
    end
  end
end