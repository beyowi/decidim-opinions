# frozen_string_literal: true

require "decidim/dev/test/rspec_support/capybara_data_picker"

module Capybara
  module OpinionsPicker
    include DataPicker

    RSpec::Matchers.define :have_opinions_picked do |expected|
      match do |opinions_picker|
        data_picker = opinions_picker.data_picker

        expected.each do |opinion|
          expect(data_picker).to have_selector(".picker-values div input[value='#{opinion.id}']", visible: :all)
          expect(data_picker).to have_selector(:xpath, "//div[contains(@class,'picker-values')]/div/a[text()[contains(.,\"#{opinion.title}\")]]")
        end
      end
    end

    RSpec::Matchers.define :have_opinions_not_picked do |expected|
      match do |opinions_picker|
        data_picker = opinions_picker.data_picker

        expected.each do |opinion|
          expect(data_picker).not_to have_selector(".picker-values div input[value='#{opinion.id}']", visible: :all)
          expect(data_picker).not_to have_selector(:xpath, "//div[contains(@class,'picker-values')]/div/a[text()[contains(.,\"#{opinion.title}\")]]")
        end
      end
    end

    def opinions_pick(opinions_picker, opinions)
      data_picker = opinions_picker.data_picker

      expect(data_picker).to have_selector(".picker-prompt")
      data_picker.find(".picker-prompt").click

      opinions.each do |opinion|
        data_picker_choose_value(opinion.id)
      end
      data_picker_close

      expect(opinions_picker).to have_opinions_picked(opinions)
    end
  end
end

RSpec.configure do |config|
  config.include Capybara::OpinionsPicker, type: :system
end
