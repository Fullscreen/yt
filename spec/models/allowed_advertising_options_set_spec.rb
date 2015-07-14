require 'spec_helper'
require 'yt/models/allowed_advertising_options_set'

describe Yt::AllowedAdvertisingOptionsSet do
  subject(:allowed_advertising_options) { Yt::AllowedAdvertisingOptionsSet.new data: data }

  describe '#ads_on_embeds' do
    let(:data) { {"adsOnEmbeds"=>true} }
    it{ expect(allowed_advertising_options.ads_on_embeds).to be(true) }
  end

  describe '#auto_generated_breaks' do
    let(:data) { {"autoGeneratedBreaks"=>true} }
    it{ expect(allowed_advertising_options.auto_generated_breaks).to be(true) }
  end

  describe '#ugc_ad_formats' do
    let(:data) { {"ugcAdFormats"=> ["long", "overlay"]} }
    it{ expect(allowed_advertising_options.ugc_ad_formats).to match_array ["long", "overlay"] }
  end

  describe '#lic_ad_formats' do
    let(:data) { {"licAdFormats"=> ["long", "trueview_instream"]} }
    it{ expect(allowed_advertising_options.lic_ad_formats).to match_array ["long", "trueview_instream"] }
  end

end
