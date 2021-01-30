# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/participatory_processes/test/factories"
require "decidim/meetings/test/factories"

FactoryBot.define do
  factory :opinion_component, parent: :component do
    name { Decidim::Components::Namer.new(participatory_space.organization.available_locales, :opinions).i18n_name }
    manifest_name { :opinions }
    participatory_space { create(:participatory_process, :with_steps, organization: organization) }

    trait :with_endorsements_enabled do
      step_settings do
        {
          participatory_space.active_step.id => { endorsements_enabled: true }
        }
      end
    end

    trait :with_endorsements_disabled do
      step_settings do
        {
          participatory_space.active_step.id => { endorsements_enabled: false }
        }
      end
    end

    trait :with_votes_enabled do
      step_settings do
        {
          participatory_space.active_step.id => { votes_enabled: true }
        }
      end
    end

    trait :with_votes_disabled do
      step_settings do
        {
          participatory_space.active_step.id => { votes_enabled: false }
        }
      end
    end

    trait :with_votes_hidden do
      step_settings do
        {
          participatory_space.active_step.id => { votes_hidden: true }
        }
      end
    end

    trait :with_vote_limit do
      transient do
        vote_limit { 10 }
      end

      settings do
        {
          vote_limit: vote_limit
        }
      end
    end

    trait :with_opinion_limit do
      transient do
        opinion_limit { 1 }
      end

      settings do
        {
          opinion_limit: opinion_limit
        }
      end
    end

    trait :with_opinion_length do
      transient do
        opinion_length { 500 }
      end

      settings do
        {
          opinion_length: opinion_length
        }
      end
    end

    trait :with_endorsements_blocked do
      step_settings do
        {
          participatory_space.active_step.id => {
            endorsements_enabled: true,
            endorsements_blocked: true
          }
        }
      end
    end

    trait :with_votes_blocked do
      step_settings do
        {
          participatory_space.active_step.id => {
            votes_enabled: true,
            votes_blocked: true
          }
        }
      end
    end

    trait :with_creation_enabled do
      step_settings do
        {
          participatory_space.active_step.id => { creation_enabled: true }
        }
      end
    end

    trait :with_geocoding_enabled do
      settings do
        {
          geocoding_enabled: true
        }
      end
    end

    trait :with_attachments_allowed do
      settings do
        {
          attachments_allowed: true
        }
      end
    end

    trait :with_threshold_per_opinion do
      transient do
        threshold_per_opinion { 1 }
      end

      settings do
        {
          threshold_per_opinion: threshold_per_opinion
        }
      end
    end

    trait :with_can_accumulate_supports_beyond_threshold do
      settings do
        {
          can_accumulate_supports_beyond_threshold: true
        }
      end
    end

    trait :with_collaborative_drafts_enabled do
      settings do
        {
          collaborative_drafts_enabled: true
        }
      end
    end

    trait :with_geocoding_and_collaborative_drafts_enabled do
      settings do
        {
          geocoding_enabled: true,
          collaborative_drafts_enabled: true
        }
      end
    end

    trait :with_attachments_allowed_and_collaborative_drafts_enabled do
      settings do
        {
          attachments_allowed: true,
          collaborative_drafts_enabled: true
        }
      end
    end

    trait :with_minimum_votes_per_user do
      transient do
        minimum_votes_per_user { 3 }
      end

      settings do
        {
          minimum_votes_per_user: minimum_votes_per_user
        }
      end
    end

    trait :with_participatory_texts_enabled do
      settings do
        {
          participatory_texts_enabled: true
        }
      end
    end

    trait :with_amendments_enabled do
      settings do
        {
          amendments_enabled: true
        }
      end
    end

    trait :with_amendments_and_participatory_texts_enabled do
      settings do
        {
          participatory_texts_enabled: true,
          amendments_enabled: true
        }
      end
    end

    trait :with_comments_disabled do
      settings do
        {
          comments_enabled: false
        }
      end
    end

    trait :with_card_image_allowed do
      settings do
        {
          allow_card_image: true
        }
      end
    end

    trait :with_extra_hashtags do
      transient do
        automatic_hashtags { "AutoHashtag AnotherAutoHashtag" }
        suggested_hashtags { "SuggestedHashtag AnotherSuggestedHashtag" }
      end

      step_settings do
        {
          participatory_space.active_step.id => {
            automatic_hashtags: automatic_hashtags,
            suggested_hashtags: suggested_hashtags,
            creation_enabled: true
          }
        }
      end
    end

    trait :without_publish_answers_immediately do
      step_settings do
        {
          participatory_space.active_step.id => {
            publish_answers_immediately: false
          }
        }
      end
    end
  end

  factory :opinion, class: "Decidim::Opinions::Opinion" do
    transient do
      users { nil }
      # user_groups correspondence to users is by sorting order
      user_groups { [] }
      skip_injection { false }
    end

    title do
      content = generate(:title).dup
      content.prepend("<script>alert('TITLE');</script> ") unless skip_injection
      content
    end
    body do
      content = Faker::Lorem.sentences(3).join("\n")
      content.prepend("<script>alert('BODY');</script> ") unless skip_injection
      content
    end
    component { create(:opinion_component) }
    published_at { Time.current }
    address { "#{Faker::Address.street_name}, #{Faker::Address.city}" }

    after(:build) do |opinion, evaluator|
      if opinion.component
        users = evaluator.users || [create(:user, organization: opinion.component.participatory_space.organization)]
        users.each_with_index do |user, idx|
          user_group = evaluator.user_groups[idx]
          opinion.coauthorships.build(author: user, user_group: user_group)
        end
      end
    end

    trait :published do
      published_at { Time.current }
    end

    trait :unpublished do
      published_at { nil }
    end

    trait :official do
      after :build do |opinion|
        opinion.coauthorships.clear
        opinion.coauthorships.build(author: opinion.organization)
      end
    end

    trait :official_meeting do
      after :build do |opinion|
        opinion.coauthorships.clear
        component = create(:meeting_component, participatory_space: opinion.component.participatory_space)
        opinion.coauthorships.build(author: build(:meeting, component: component))
      end
    end

    trait :evaluating do
      state { "evaluating" }
      answered_at { Time.current }
      state_published_at { Time.current }
    end

    trait :accepted do
      state { "accepted" }
      answered_at { Time.current }
      state_published_at { Time.current }
    end

    trait :rejected do
      state { "rejected" }
      answered_at { Time.current }
      state_published_at { Time.current }
    end

    trait :withdrawn do
      state { "withdrawn" }
    end

    trait :accepted_not_published do
      state { "accepted" }
      answered_at { Time.current }
      state_published_at { nil }
      answer { generate_localized_title }
    end

    trait :with_answer do
      state { "accepted" }
      answer { generate_localized_title }
      answered_at { Time.current }
      state_published_at { Time.current }
    end

    trait :not_answered do
      state { nil }
    end

    trait :draft do
      published_at { nil }
    end

    trait :hidden do
      after :create do |opinion|
        create(:moderation, hidden_at: Time.current, reportable: opinion)
      end
    end

    trait :with_votes do
      after :create do |opinion|
        create_list(:opinion_vote, 5, opinion: opinion)
      end
    end

    trait :with_endorsements do
      after :create do |opinion|
        5.times.collect do
          create(:endorsement, resource: opinion, author: build(:user, organization: opinion.participatory_space.organization))
        end
      end
    end

    trait :with_amendments do
      after :create do |opinion|
        create_list(:opinion_amendment, 5, amendable: opinion)
      end
    end
  end

  factory :opinion_vote, class: "Decidim::Opinions::OpinionVote" do
    opinion { build(:opinion) }
    author { build(:user, organization: opinion.organization) }
  end

  factory :opinion_amendment, class: "Decidim::Amendment" do
    amendable { build(:opinion) }
    emendation { build(:opinion, component: amendable.component) }
    amender { build(:user, organization: amendable.component.participatory_space.organization) }
    state { Decidim::Amendment::STATES.sample }
  end

  factory :opinion_note, class: "Decidim::Opinions::OpinionNote" do
    body { Faker::Lorem.sentences(3).join("\n") }
    opinion { build(:opinion) }
    author { build(:user, organization: opinion.organization) }
  end

  factory :collaborative_draft, class: "Decidim::Opinions::CollaborativeDraft" do
    transient do
      users { nil }
      # user_groups correspondence to users is by sorting order
      user_groups { [] }
    end

    title { "<script>alert(\"TITLE\");</script> " + generate(:title) }
    body { "<script>alert(\"BODY\");</script>\n" + Faker::Lorem.sentences(3).join("\n") }
    component { create(:opinion_component) }
    address { "#{Faker::Address.street_name}, #{Faker::Address.city}" }
    state { "open" }

    after(:build) do |collaborative_draft, evaluator|
      if collaborative_draft.component
        users = evaluator.users || [create(:user, organization: collaborative_draft.component.participatory_space.organization)]
        users.each_with_index do |user, idx|
          user_group = evaluator.user_groups[idx]
          collaborative_draft.coauthorships.build(author: user, user_group: user_group)
        end
      end
    end

    trait :published do
      state { "published" }
      published_at { Time.current }
    end

    trait :open do
      state { "open" }
    end

    trait :withdrawn do
      state { "withdrawn" }
    end
  end

  factory :participatory_text, class: "Decidim::Opinions::ParticipatoryText" do
    title { "<script>alert(\"TITLE\");</script> " + generate(:title) }
    description { "<script>alert(\"DESCRIPTION\");</script>\n" + Faker::Lorem.sentences(3).join("\n") }
    component { create(:opinion_component) }
  end

  factory :valuation_assignment, class: "Decidim::Opinions::ValuationAssignment" do
    opinion
    valuator_role do
      space = opinion.component.participatory_space
      organization = space.organization
      build :participatory_process_user_role, role: :valuator, user: build(:user, organization: organization)
    end
  end
end
