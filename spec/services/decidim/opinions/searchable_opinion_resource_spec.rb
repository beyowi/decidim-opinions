# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe Search do
    subject { described_class.new(params) }

    include_context "when a resource is ready for global search"

    let(:current_component) { create :opinion_component, organization: organization }
    let!(:opinion) do
      create(
        :opinion,
        :draft,
        component: current_component,
        scope: scope1,
        title: Decidim::Faker.name,
        body: description_1[:ca],
        users: [author]
      )
    end

    describe "Indexing of opinions" do
      context "when implementing Searchable" do
        context "when on create" do
          context "when opinions are NOT official" do
            let(:opinion2) do
              create(:opinion, component: current_component)
            end

            it "does not index a SearchableResource after Opinion creation when it is not official" do
              searchables = SearchableResource.where(resource_type: opinion.class.name, resource_id: [opinion.id, opinion2.id])
              expect(searchables).to be_empty
            end
          end

          context "when opinions ARE official" do
            let(:author) { organization }

            before do
              opinion.update(published_at: Time.current)
            end

            it "does indexes a SearchableResource after Opinion creation when it is official" do
              organization.available_locales.each do |locale|
                searchable = SearchableResource.find_by(resource_type: opinion.class.name, resource_id: opinion.id, locale: locale)
                expect_searchable_resource_to_correspond_to_opinion(searchable, opinion, locale)
              end
            end
          end
        end

        context "when on update" do
          context "when it is NOT published" do
            it "does not index a SearchableResource when Opinion changes but is not published" do
              searchables = SearchableResource.where(resource_type: opinion.class.name, resource_id: opinion.id)
              expect(searchables).to be_empty
            end
          end

          context "when it IS published" do
            before do
              opinion.update published_at: Time.current
            end

            it "inserts a SearchableResource after Opinion is published" do
              organization.available_locales.each do |locale|
                searchable = SearchableResource.find_by(resource_type: opinion.class.name, resource_id: opinion.id, locale: locale)
                expect_searchable_resource_to_correspond_to_opinion(searchable, opinion, locale)
              end
            end

            it "updates the associated SearchableResource after published Opinion update" do
              searchable = SearchableResource.find_by(resource_type: opinion.class.name, resource_id: opinion.id)
              created_at = searchable.created_at
              updated_title = "Brand new title"
              opinion.update(title: updated_title)

              opinion.save!
              searchable.reload

              organization.available_locales.each do |locale|
                searchable = SearchableResource.find_by(resource_type: opinion.class.name, resource_id: opinion.id, locale: locale)
                expect(searchable.content_a).to eq updated_title
                expect(searchable.updated_at).to be > created_at
              end
            end

            it "removes the associated SearchableResource after unpublishing a published Opinion on update" do
              opinion.update(published_at: nil)

              searchables = SearchableResource.where(resource_type: opinion.class.name, resource_id: opinion.id)
              expect(searchables).to be_empty
            end
          end
        end

        context "when on destroy" do
          it "destroys the associated SearchableResource after Opinion destroy" do
            opinion.destroy

            searchables = SearchableResource.where(resource_type: opinion.class.name, resource_id: opinion.id)

            expect(searchables.any?).to be false
          end
        end
      end
    end

    describe "Search" do
      context "when searching by Opinion resource_type" do
        let!(:opinion2) do
          create(
            :opinion,
            component: current_component,
            scope: scope1,
            title: Decidim::Faker.name,
            body: "Chewie, I'll be waiting for your signal. Take care, you two. May the Force be with you. Ow!"
          )
        end

        before do
          opinion.update(published_at: Time.current)
          opinion2.update(published_at: Time.current)
        end

        it "returns Opinion results" do
          Decidim::Search.call("Ow", organization, resource_type: opinion.class.name) do
            on(:ok) do |results_by_type|
              results = results_by_type[opinion.class.name]
              expect(results[:count]).to eq 2
              expect(results[:results]).to match_array [opinion, opinion2]
            end
            on(:invalid) { raise("Should not happen") }
          end
        end

        it "allows searching by prefix characters" do
          Decidim::Search.call("wait", organization, resource_type: opinion.class.name) do
            on(:ok) do |results_by_type|
              results = results_by_type[opinion.class.name]
              expect(results[:count]).to eq 1
              expect(results[:results]).to eq [opinion2]
            end
            on(:invalid) { raise("Should not happen") }
          end
        end
      end
    end

    private

    def expect_searchable_resource_to_correspond_to_opinion(searchable, opinion, locale)
      attrs = searchable.attributes.clone
      attrs.delete("id")
      attrs.delete("created_at")
      attrs.delete("updated_at")
      expect(attrs.delete("datetime").to_s(:short)).to eq(opinion.published_at.to_s(:short))
      expect(attrs).to eq(expected_searchable_resource_attrs(opinion, locale))
    end

    def expected_searchable_resource_attrs(opinion, locale)
      {
        "content_a" => I18n.transliterate(opinion.title),
        "content_b" => "",
        "content_c" => "",
        "content_d" => I18n.transliterate(opinion.body),
        "locale" => locale,

        "decidim_organization_id" => opinion.component.organization.id,
        "decidim_participatory_space_id" => current_component.participatory_space_id,
        "decidim_participatory_space_type" => current_component.participatory_space_type,
        "decidim_scope_id" => opinion.decidim_scope_id,
        "resource_id" => opinion.id,
        "resource_type" => "Decidim::Opinions::Opinion"
      }
    end
  end
end
