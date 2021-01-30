# frozen_string_literal: true

require "spec_helper"

describe Decidim::Opinions::Admin::Permissions do
  subject { described_class.new(user, permission_action, context).permissions.allowed? }

  let(:user) { build :user, :admin }
  let(:current_component) { create(:opinion_component) }
  let(:opinion) { nil }
  let(:extra_context) { {} }
  let(:context) do
    {
      opinion: opinion,
      current_component: current_component,
      current_settings: current_settings,
      component_settings: component_settings
    }.merge(extra_context)
  end
  let(:component_settings) do
    double(
      official_opinions_enabled: official_opinions_enabled?,
      opinion_answering_enabled: component_settings_opinion_answering_enabled?,
      participatory_texts_enabled?: component_settings_participatory_texts_enabled?
    )
  end
  let(:current_settings) do
    double(
      creation_enabled?: creation_enabled?,
      opinion_answering_enabled: current_settings_opinion_answering_enabled?,
      publish_answers_immediately: current_settings_publish_answers_immediately?
    )
  end
  let(:creation_enabled?) { true }
  let(:official_opinions_enabled?) { true }
  let(:component_settings_opinion_answering_enabled?) { true }
  let(:component_settings_participatory_texts_enabled?) { true }
  let(:current_settings_opinion_answering_enabled?) { true }
  let(:current_settings_publish_answers_immediately?) { true }
  let(:permission_action) { Decidim::PermissionAction.new(action) }

  shared_examples "can create opinion notes" do
    describe "opinion note creation" do
      let(:action) do
        { scope: :admin, action: :create, subject: :opinion_note }
      end

      context "when the space allows it" do
        it { is_expected.to eq true }
      end
    end
  end

  shared_examples "can answer opinions" do
    describe "opinion answering" do
      let(:action) do
        { scope: :admin, action: :create, subject: :opinion_answer }
      end

      context "when everything is OK" do
        it { is_expected.to eq true }
      end

      context "when answering is disabled in the step level" do
        let(:current_settings_opinion_answering_enabled?) { false }

        it { is_expected.to eq false }
      end

      context "when answering is disabled in the component level" do
        let(:component_settings_opinion_answering_enabled?) { false }

        it { is_expected.to eq false }
      end
    end
  end

  shared_examples "can export opinions" do
    describe "export opinions" do
      let(:action) do
        { scope: :admin, action: :export, subject: :opinions }
      end

      context "when everything is OK" do
        it { is_expected.to eq true }
      end
    end
  end

  context "when user is a valuator" do
    let(:organization) { space.organization }
    let(:space) { current_component.participatory_space }
    let!(:valuator_role) { create :participatory_process_user_role, user: user, role: :valuator, participatory_process: space }
    let!(:user) { create :user, organization: organization }

    context "and can valuate the current opinion" do
      let(:opinion) { create :opinion, component: current_component }
      let!(:assignment) { create :valuation_assignment, opinion: opinion, valuator_role: valuator_role }

      it_behaves_like "can create opinion notes"
      it_behaves_like "can answer opinions"
      it_behaves_like "can export opinions"
    end

    context "when current user is the valuator" do
      describe "unassign opinions from themselves" do
        let(:action) do
          { scope: :admin, action: :unassign_from_valuator, subject: :opinions }
        end
        let(:extra_context) { { valuator: user } }

        it { is_expected.to eq true }
      end
    end
  end

  it_behaves_like "can create opinion notes"
  it_behaves_like "can answer opinions"
  it_behaves_like "can export opinions"

  describe "opinion creation" do
    let(:action) do
      { scope: :admin, action: :create, subject: :opinion }
    end

    context "when everything is OK" do
      it { is_expected.to eq true }
    end

    context "when creation is disabled" do
      let(:creation_enabled?) { false }

      it { is_expected.to eq false }
    end

    context "when official opinions are disabled" do
      let(:official_opinions_enabled?) { false }

      it { is_expected.to eq false }
    end
  end

  describe "opinion edition" do
    let(:action) do
      { scope: :admin, action: :edit, subject: :opinion }
    end

    context "when the opinion is not official" do
      let(:opinion) { create :opinion, component: current_component }

      it_behaves_like "permission is not set"
    end

    context "when the opinion is official" do
      let(:opinion) { create :opinion, :official, component: current_component }

      context "when everything is OK" do
        it { is_expected.to eq true }
      end

      context "when it has some votes" do
        before do
          create :opinion_vote, opinion: opinion
        end

        it_behaves_like "permission is not set"
      end
    end
  end

  describe "update opinion category" do
    let(:action) do
      { scope: :admin, action: :update, subject: :opinion_category }
    end

    it { is_expected.to eq true }
  end

  describe "import opinions from another component" do
    let(:action) do
      { scope: :admin, action: :import, subject: :opinions }
    end

    it { is_expected.to eq true }
  end

  describe "split opinions" do
    let(:action) do
      { scope: :admin, action: :split, subject: :opinions }
    end

    it { is_expected.to eq true }
  end

  describe "merge opinions" do
    let(:action) do
      { scope: :admin, action: :merge, subject: :opinions }
    end

    it { is_expected.to eq true }
  end

  describe "opinion answers publishing" do
    let(:user) { create(:user) }
    let(:action) do
      { scope: :admin, action: :publish_answers, subject: :opinions }
    end

    it { is_expected.to eq false }

    context "when user is an admin" do
      let(:user) { create(:user, :admin) }

      it { is_expected.to eq true }
    end
  end

  describe "assign opinions to a valuator" do
    let(:action) do
      { scope: :admin, action: :assign_to_valuator, subject: :opinions }
    end

    it { is_expected.to eq true }
  end

  describe "unassign opinions from a valuator" do
    let(:action) do
      { scope: :admin, action: :unassign_from_valuator, subject: :opinions }
    end

    it { is_expected.to eq true }
  end

  describe "manage participatory texts" do
    let(:action) do
      { scope: :admin, action: :manage, subject: :participatory_texts }
    end

    it { is_expected.to eq true }
  end
end
