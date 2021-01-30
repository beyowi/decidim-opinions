# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ContentRenderers
    describe OpinionRenderer do
      let!(:renderer) { Decidim::ContentRenderers::OpinionRenderer.new(content) }

      describe "on parse" do
        subject { renderer.render }

        context "when content is nil" do
          let(:content) { nil }

          it { is_expected.to eq("") }
        end

        context "when content is empty string" do
          let(:content) { "" }

          it { is_expected.to eq("") }
        end

        context "when conent has no gids" do
          let(:content) { "whatever content with @mentions and #hashes but no gids." }

          it { is_expected.to eq(content) }
        end

        context "when content has one gid" do
          let(:opinion) { create(:opinion) }
          let(:content) do
            "This content references opinion #{opinion.to_global_id}."
          end

          it { is_expected.to eq("This content references opinion #{opinion_as_html_link(opinion)}.") }
        end

        context "when content has many links" do
          let(:opinion_1) { create(:opinion) }
          let(:opinion_2) { create(:opinion) }
          let(:opinion_3) { create(:opinion) }
          let(:content) do
            gid1 = opinion_1.to_global_id
            gid2 = opinion_2.to_global_id
            gid3 = opinion_3.to_global_id
            "This content references the following opinions: #{gid1}, #{gid2} and #{gid3}. Great?I like them!"
          end

          it { is_expected.to eq("This content references the following opinions: #{opinion_as_html_link(opinion_1)}, #{opinion_as_html_link(opinion_2)} and #{opinion_as_html_link(opinion_3)}. Great?I like them!") }
        end
      end

      def opinion_url(opinion)
        Decidim::ResourceLocatorPresenter.new(opinion).path
      end

      def opinion_as_html_link(opinion)
        href = opinion_url(opinion)
        title = opinion.title
        %(<a href="#{href}">#{title}</a>)
      end
    end
  end
end
