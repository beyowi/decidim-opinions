# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ContentParsers
    describe OpinionParser do
      let(:organization) { create(:organization) }
      let(:component) { create(:opinion_component, organization: organization) }
      let(:context) { { current_organization: organization } }
      let!(:parser) { Decidim::ContentParsers::OpinionParser.new(content, context) }

      describe "ContentParser#parse is invoked" do
        let(:content) { "" }

        it "must call OpinionParser.parse" do
          expect(described_class).to receive(:new).with(content, context).and_return(parser)

          result = Decidim::ContentProcessor.parse(content, context)

          expect(result.rewrite).to eq ""
          expect(result.metadata[:opinion].class).to eq Decidim::ContentParsers::OpinionParser::Metadata
        end
      end

      describe "on parse" do
        subject { parser.rewrite }

        context "when content is nil" do
          let(:content) { nil }

          it { is_expected.to eq("") }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::OpinionParser::Metadata)
            expect(parser.metadata.linked_opinions).to eq([])
          end
        end

        context "when content is empty string" do
          let(:content) { "" }

          it { is_expected.to eq("") }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::OpinionParser::Metadata)
            expect(parser.metadata.linked_opinions).to eq([])
          end
        end

        context "when conent has no links" do
          let(:content) { "whatever content with @mentions and #hashes but no links." }

          it { is_expected.to eq(content) }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::OpinionParser::Metadata)
            expect(parser.metadata.linked_opinions).to eq([])
          end
        end

        context "when content links to an organization different from current" do
          let(:opinion) { create(:opinion, component: component) }
          let(:external_opinion) { create(:opinion, component: create(:opinion_component, organization: create(:organization))) }
          let(:content) do
            url = opinion_url(external_opinion)
            "This content references opinion #{url}."
          end

          it "does not recognize the opinion" do
            subject
            expect(parser.metadata.linked_opinions).to eq([])
          end
        end

        context "when content has one link" do
          let(:opinion) { create(:opinion, component: component) }
          let(:content) do
            url = opinion_url(opinion)
            "This content references opinion #{url}."
          end

          it { is_expected.to eq("This content references opinion #{opinion.to_global_id}.") }

          it "has metadata with the opinion" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::OpinionParser::Metadata)
            expect(parser.metadata.linked_opinions).to eq([opinion.id])
          end
        end

        context "when content has one link that is a simple domain" do
          let(:link) { "aaa:bbb" }
          let(:content) do
            "This content contains #{link} which is not a URI."
          end

          it { is_expected.to eq(content) }

          it "has metadata with the opinion" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::OpinionParser::Metadata)
            expect(parser.metadata.linked_opinions).to be_empty
          end
        end

        context "when content has many links" do
          let(:opinion1) { create(:opinion, component: component) }
          let(:opinion2) { create(:opinion, component: component) }
          let(:opinion3) { create(:opinion, component: component) }
          let(:content) do
            url1 = opinion_url(opinion1)
            url2 = opinion_url(opinion2)
            url3 = opinion_url(opinion3)
            "This content references the following opinions: #{url1}, #{url2} and #{url3}. Great?I like them!"
          end

          it { is_expected.to eq("This content references the following opinions: #{opinion1.to_global_id}, #{opinion2.to_global_id} and #{opinion3.to_global_id}. Great?I like them!") }

          it "has metadata with all linked opinions" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::OpinionParser::Metadata)
            expect(parser.metadata.linked_opinions).to eq([opinion1.id, opinion2.id, opinion3.id])
          end
        end

        context "when content has a link that is not in a opinions component" do
          let(:opinion) { create(:opinion, component: component) }
          let(:content) do
            url = opinion_url(opinion).sub(%r{/opinions/}, "/something-else/")
            "This content references a non-opinion with same ID as a opinion #{url}."
          end

          it { is_expected.to eq(content) }

          it "has metadata with no reference to the opinion" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::OpinionParser::Metadata)
            expect(parser.metadata.linked_opinions).to be_empty
          end
        end

        context "when content has words similar to links but not links" do
          let(:similars) do
            %w(AA:aaa AA:sss aa:aaa aa:sss aaa:sss aaaa:sss aa:ssss aaa:ssss)
          end
          let(:content) do
            "This content has similars to links: #{similars.join}. Great! Now are not treated as links"
          end

          it { is_expected.to eq(content) }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::OpinionParser::Metadata)
            expect(parser.metadata.linked_opinions).to be_empty
          end
        end

        context "when opinion in content does not exist" do
          let(:opinion) { create(:opinion, component: component) }
          let(:url) { opinion_url(opinion) }
          let(:content) do
            opinion.destroy
            "This content references opinion #{url}."
          end

          it { is_expected.to eq("This content references opinion #{url}.") }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::OpinionParser::Metadata)
            expect(parser.metadata.linked_opinions).to eq([])
          end
        end

        context "when opinion is linked via ID" do
          let(:opinion) { create(:opinion, component: component) }
          let(:content) { "This content references opinion ~#{opinion.id}." }

          it { is_expected.to eq("This content references opinion #{opinion.to_global_id}.") }

          it "has metadata with the opinion" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::OpinionParser::Metadata)
            expect(parser.metadata.linked_opinions).to eq([opinion.id])
          end
        end
      end

      def opinion_url(opinion)
        Decidim::ResourceLocatorPresenter.new(opinion).url
      end
    end
  end
end
