require 'yt/models/resource'

module Yt
  module Models
    class Caption < Resource
      delegate :video_id, to: :snippet
      delegate :last_updated, to: :snippet
      delegate :language, to: :snippet
      delegate :name, to: :snippet
      delegate :status, to: :snippet
    end
  end
end
