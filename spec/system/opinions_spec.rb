# frozen_string_literal: true

require "spec_helper"

describe "Opinions", type: :system do
  include ActionView::Helpers::TextHelper
  include_context "with a component"
  let(:manifest_name) { "opinions" }

  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:scope) { create :scope, organization: organization }
  let!(:user) { create :user, :confirmed, organization: organization }
  let(:scoped_participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: scope) }

  let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }

  before do
    stub_geocoding(address, [latitude, longitude])
  end

  matcher :have_author do |name|
    match { |node| node.has_selector?(".author-data", text: name) }
    match_when_negated { |node| node.has_no_selector?(".author-data", text: name) }
  end

  matcher :have_creation_date do |date|
    match { |node| node.has_selector?(".author-data__extra", text: date) }
    match_when_negated { |node| node.has_no_selector?(".author-data__extra", text: date) }
  end

  context "when viewing a single opinion" do
    let!(:component) do
      create(:opinion_component,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    let!(:opinions) { create_list(:opinion, 3, component: component) }

    it "allows viewing a single opinion" do
      opinion = opinions.first

      visit_component

      click_link opinion.title

      expect(page).to have_content(opinion.title)
      expect(page).to have_content(strip_tags(opinion.body).strip)
      expect(page).to have_author(opinion.creator_author.name)
      expect(page).to have_content(opinion.reference)
      expect(page).to have_creation_date(I18n.l(opinion.published_at, format: :decidim_short))
    end

    context "when process is not related to any scope" do
      let!(:opinion) { create(:opinion, component: component, scope: scope) }

      it "can be filtered by scope" do
        visit_component
        click_link opinion.title
        expect(page).to have_content(translated(scope.name))
      end
    end

    context "when process is related to a child scope" do
      let!(:opinion) { create(:opinion, component: component, scope: scope) }
      let(:participatory_process) { scoped_participatory_process }

      it "does not show the scope name" do
        visit_component
        click_link opinion.title
        expect(page).to have_no_content(translated(scope.name))
      end
    end

    context "when it is an official opinion" do
      let(:content) { generate_localized_title }
      let!(:official_opinion) { create(:opinion, :official, body: content, component: component) }

      before do
        visit_component
        click_link official_opinion.title
      end

      it "shows the author as official" do
        expect(page).to have_content("Official opinion")
      end

      it_behaves_like "rendering safe content", ".columns.mediumlarge-8.large-9"
    end

    context "when rich text editor is enabled for participants" do
      let!(:opinion) { create(:opinion, body: content, component: component) }

      before do
        organization.update(rich_text_editor_in_public_views: true)
        visit_component
        click_link opinion.title
      end

      it_behaves_like "rendering safe content", ".columns.mediumlarge-8.large-9"
    end

    context "when rich text editor is NOT enabled for participants" do
      let!(:opinion) { create(:opinion, body: content, component: component) }

      before do
        visit_component
        click_link opinion.title
      end

      it_behaves_like "rendering unsafe content", ".columns.mediumlarge-8.large-9"
    end

    context "when it is a opinion with card image enabled" do
      let!(:component) do
        create(:opinion_component,
               :with_card_image_allowed,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      let!(:opinion) { create(:opinion, component: component) }
      let!(:image) { create(:attachment, attached_to: opinion) }

      it "shows the card image" do
        visit_component
        within "#opinion_#{opinion.id}" do
          expect(page).to have_selector(".card__image")
        end
      end
    end

    context "when it is an official meeting opinion" do
      include_context "with rich text editor content"
      let!(:opinion) { create(:opinion, :official_meeting, body: content, component: component) }

      before do
        visit_component
        click_link opinion.title
      end

      it "shows the author as meeting" do
        expect(page).to have_content(translated(opinion.authors.first.title))
      end

      it_behaves_like "rendering safe content", ".columns.mediumlarge-8.large-9"
    end

    context "when a opinion has comments" do
      let(:opinion) { create(:opinion, component: component) }
      let(:author) { create(:user, :confirmed, organization: component.organization) }
      let!(:comments) { create_list(:comment, 3, commentable: opinion) }

      it "shows the comments" do
        visit_component
        click_link opinion.title

        comments.each do |comment|
          expect(page).to have_content(comment.body)
        end
      end
    end

    context "when a opinion has costs" do
      let!(:opinion) do
        create(
          :opinion,
          :accepted,
          :with_answer,
          component: component,
          cost: 20_000,
          cost_report: { en: "My cost report" },
          execution_period: { en: "My execution period" }
        )
      end
      let!(:author) { create(:user, :confirmed, organization: component.organization) }

      it "shows the costs" do
        component.update!(
          step_settings: {
            component.participatory_space.active_step.id => {
              answers_with_costs: true
            }
          }
        )

        visit_component
        click_link opinion.title

        expect(page).to have_content("20,000.00")
        expect(page).to have_content("MY EXECUTION PERIOD")
        expect(page).to have_content("My cost report")
      end
    end

    context "when a opinion has been linked in a meeting" do
      let(:opinion) { create(:opinion, component: component) }
      let(:meeting_component) do
        create(:component, manifest_name: :meetings, participatory_space: opinion.component.participatory_space)
      end
      let(:meeting) { create(:meeting, component: meeting_component) }

      before do
        meeting.link_resources([opinion], "opinions_from_meeting")
      end

      it "shows related meetings" do
        visit_component
        click_link opinion.title

        expect(page).to have_i18n_content(meeting.title)
      end
    end

    context "when a opinion has been linked in a result" do
      let(:opinion) { create(:opinion, component: component) }
      let(:accountability_component) do
        create(:component, manifest_name: :accountability, participatory_space: opinion.component.participatory_space)
      end
      let(:result) { create(:result, component: accountability_component) }

      before do
        result.link_resources([opinion], "included_opinions")
      end

      it "shows related resources" do
        visit_component
        click_link opinion.title

        expect(page).to have_i18n_content(result.title)
      end
    end

    context "when a opinion is in evaluation" do
      let!(:opinion) { create(:opinion, :with_answer, :evaluating, component: component) }

      it "shows a badge and an answer" do
        visit_component
        click_link opinion.title

        expect(page).to have_content("Evaluating")

        within ".callout.warning" do
          expect(page).to have_content("This opinion is being evaluated")
          expect(page).to have_i18n_content(opinion.answer)
        end
      end
    end

    context "when a opinion has been rejected" do
      let!(:opinion) { create(:opinion, :with_answer, :rejected, component: component) }

      it "shows the rejection reason" do
        visit_component
        uncheck "Accepted"
        uncheck "Evaluating"
        uncheck "Not answered"
        page.find_link(opinion.title, wait: 30)
        click_link opinion.title

        expect(page).to have_content("Rejected")

        within ".callout.alert" do
          expect(page).to have_content("This opinion has been rejected")
          expect(page).to have_i18n_content(opinion.answer)
        end
      end
    end

    context "when a opinion has been accepted" do
      let!(:opinion) { create(:opinion, :with_answer, :accepted, component: component) }

      it "shows the acceptance reason" do
        visit_component
        click_link opinion.title

        expect(page).to have_content("Accepted")

        within ".callout.success" do
          expect(page).to have_content("This opinion has been accepted")
          expect(page).to have_i18n_content(opinion.answer)
        end
      end
    end

    context "when the opinion answer has not been published" do
      let!(:opinion) { create(:opinion, :accepted_not_published, component: component) }

      it "shows the acceptance reason" do
        visit_component
        click_link opinion.title

        expect(page).not_to have_content("Accepted")
        expect(page).not_to have_content("This opinion has been accepted")
        expect(page).not_to have_i18n_content(opinion.answer)
      end
    end

    context "when the opinions'a author account has been deleted" do
      let(:opinion) { opinions.first }

      before do
        Decidim::DestroyAccount.call(opinion.creator_author, Decidim::DeleteAccountForm.from_params({}))
      end

      it "the user is displayed as a deleted user" do
        visit_component

        click_link opinion.title

        expect(page).to have_content("Participant deleted")
      end
    end
  end

  context "when a opinion has been linked in a project" do
    let(:component) do
      create(:opinion_component,
             manifest: manifest,
             participatory_space: participatory_process)
    end
    let(:opinion) { create(:opinion, component: component) }
    let(:budget_component) do
      create(:component, manifest_name: :budgets, participatory_space: opinion.component.participatory_space)
    end
    let(:project) { create(:project, component: budget_component) }

    before do
      project.link_resources([opinion], "included_opinions")
    end

    it "shows related projects" do
      visit_component
      click_link opinion.title

      expect(page).to have_i18n_content(project.title)
    end
  end

  context "when listing opinions in a participatory process" do
    shared_examples_for "a random opinion ordering" do
      let!(:lucky_opinion) { create(:opinion, component: component) }
      let!(:unlucky_opinion) { create(:opinion, component: component) }

      it "lists the opinions ordered randomly by default" do
        visit_component

        expect(page).to have_selector("a", text: "Random")
        expect(page).to have_selector(".card--opinion", count: 2)
        expect(page).to have_selector(".card--opinion", text: lucky_opinion.title)
        expect(page).to have_selector(".card--opinion", text: unlucky_opinion.title)
        expect(page).to have_author(lucky_opinion.creator_author.name)
      end
    end

    it "lists all the opinions" do
      create(:opinion_component,
             manifest: manifest,
             participatory_space: participatory_process)

      create_list(:opinion, 3, component: component)

      visit_component
      expect(page).to have_css(".card--opinion", count: 3)
    end

    describe "editable content" do
      it_behaves_like "editable content for admins" do
        let(:target_path) { main_component_path(component) }
      end
    end

    context "when comments have been moderated" do
      let(:opinion) { create(:opinion, component: component) }
      let(:author) { create(:user, :confirmed, organization: component.organization) }
      let!(:comments) { create_list(:comment, 3, commentable: opinion) }
      let!(:moderation) { create :moderation, reportable: comments.first, hidden_at: 1.day.ago }

      it "displays unhidden comments count" do
        visit_component

        within("#opinion_#{opinion.id}") do
          within(".card-data__item:last-child") do
            expect(page).to have_content(2)
          end
        end
      end
    end

    describe "default ordering" do
      it_behaves_like "a random opinion ordering"
    end

    context "when voting phase is over" do
      let!(:component) do
        create(:opinion_component,
               :with_votes_blocked,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      let!(:most_voted_opinion) do
        opinion = create(:opinion, component: component)
        create_list(:opinion_vote, 3, opinion: opinion)
        opinion
      end

      let!(:less_voted_opinion) { create(:opinion, component: component) }

      before { visit_component }

      it "lists the opinions ordered by votes by default" do
        expect(page).to have_selector("a", text: "Most supported")
        expect(page).to have_selector("#opinions .card-grid .column:first-child", text: most_voted_opinion.title)
        expect(page).to have_selector("#opinions .card-grid .column:last-child", text: less_voted_opinion.title)
      end

      it "shows a disabled vote button for each opinion, but no links to full opinions" do
        expect(page).to have_button("Supports disabled", disabled: true, count: 2)
        expect(page).to have_no_link("View opinion")
      end
    end

    context "when voting is disabled" do
      let!(:component) do
        create(:opinion_component,
               :with_votes_disabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      describe "order" do
        it_behaves_like "a random opinion ordering"
      end

      it "shows only links to full opinions" do
        create_list(:opinion, 2, component: component)

        visit_component

        expect(page).to have_no_button("Supports disabled", disabled: true)
        expect(page).to have_no_button("Vote")
        expect(page).to have_link("View opinion", count: 2)
      end
    end

    context "when there are a lot of opinions" do
      before do
        create_list(:opinion, Decidim::Paginable::OPTIONS.first + 5, component: component)
      end

      it "paginates them" do
        visit_component

        expect(page).to have_css(".card--opinion", count: Decidim::Paginable::OPTIONS.first)

        click_link "Next"

        expect(page).to have_selector(".pagination .current", text: "2")

        expect(page).to have_css(".card--opinion", count: 5)
      end
    end

    shared_examples "ordering opinions by selected option" do |selected_option|
      before do
        visit_component
        within ".order-by" do
          expect(page).to have_selector("ul[data-dropdown-menu$=dropdown-menu]", text: "Random")
          page.find("a", text: "Random").click
          click_link(selected_option)
        end
      end

      it "lists the opinions ordered by selected option" do
        expect(page).to have_selector("#opinions .card-grid .column:first-child", text: first_opinion.title)
        expect(page).to have_selector("#opinions .card-grid .column:last-child", text: last_opinion.title)
      end
    end

    context "when ordering by 'most_voted'" do
      let!(:component) do
        create(:opinion_component,
               :with_votes_enabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end
      let!(:most_voted_opinion) { create(:opinion, component: component) }
      let!(:votes) { create_list(:opinion_vote, 3, opinion: most_voted_opinion) }
      let!(:less_voted_opinion) { create(:opinion, component: component) }

      it_behaves_like "ordering opinions by selected option", "Most supported" do
        let(:first_opinion) { most_voted_opinion }
        let(:last_opinion) { less_voted_opinion }
      end
    end

    context "when ordering by 'recent'" do
      let!(:older_opinion) { create(:opinion, component: component, created_at: 1.month.ago) }
      let!(:recent_opinion) { create(:opinion, component: component) }

      it_behaves_like "ordering opinions by selected option", "Recent" do
        let(:first_opinion) { recent_opinion }
        let(:last_opinion) { older_opinion }
      end
    end

    context "when ordering by 'most_followed'" do
      let!(:most_followed_opinion) { create(:opinion, component: component) }
      let!(:follows) { create_list(:follow, 3, followable: most_followed_opinion) }
      let!(:less_followed_opinion) { create(:opinion, component: component) }

      it_behaves_like "ordering opinions by selected option", "Most followed" do
        let(:first_opinion) { most_followed_opinion }
        let(:last_opinion) { less_followed_opinion }
      end
    end

    context "when ordering by 'most_commented'" do
      let!(:most_commented_opinion) { create(:opinion, component: component, created_at: 1.month.ago) }
      let!(:comments) { create_list(:comment, 3, commentable: most_commented_opinion) }
      let!(:less_commented_opinion) { create(:opinion, component: component) }

      it_behaves_like "ordering opinions by selected option", "Most commented" do
        let(:first_opinion) { most_commented_opinion }
        let(:last_opinion) { less_commented_opinion }
      end
    end

    context "when ordering by 'most_endorsed'" do
      let!(:most_endorsed_opinion) { create(:opinion, component: component, created_at: 1.month.ago) }
      let!(:endorsements) do
        3.times.collect do
          create(:endorsement, resource: most_endorsed_opinion, author: build(:user, organization: organization))
        end
      end
      let!(:less_endorsed_opinion) { create(:opinion, component: component) }

      it_behaves_like "ordering opinions by selected option", "Most endorsed" do
        let(:first_opinion) { most_endorsed_opinion }
        let(:last_opinion) { less_endorsed_opinion }
      end
    end

    context "when ordering by 'with_more_authors'" do
      let!(:most_authored_opinion) { create(:opinion, component: component, created_at: 1.month.ago) }
      let!(:coauthorships) { create_list(:coauthorship, 3, coauthorable: most_authored_opinion) }
      let!(:less_authored_opinion) { create(:opinion, component: component) }

      it_behaves_like "ordering opinions by selected option", "With more authors" do
        let(:first_opinion) { most_authored_opinion }
        let(:last_opinion) { less_authored_opinion }
      end
    end

    context "when paginating" do
      let!(:collection) { create_list :opinion, collection_size, component: component }
      let!(:resource_selector) { ".card--opinion" }

      it_behaves_like "a paginated resource"
    end

    context "when component is not commentable" do
      let!(:ressources) { create_list(:opinion, 3, component: component) }

      it_behaves_like "an uncommentable component"
    end
  end
end
