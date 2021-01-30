# frozen_string_literal: true

module Decidim
  module Opinions
    # Exposes the opinion resource so users can view and create them.
    class OpinionsController < Decidim::Opinions::ApplicationController
      helper Decidim::WidgetUrlsHelper
      helper OpinionWizardHelper
      helper ParticipatoryTextsHelper
      include Decidim::ApplicationHelper
      include FormFactory
      include FilterResource
      include Decidim::Opinions::Orderable
      include Paginable

      helper_method :opinion_presenter, :form_presenter

      before_action :authenticate_user!, only: [:new, :create, :complete]
      before_action :ensure_is_draft, only: [:compare, :complete, :preview, :publish, :edit_draft, :update_draft, :destroy_draft]
      before_action :set_opinion, only: [:show, :edit, :update, :withdraw]
      before_action :edit_form, only: [:edit_draft, :edit]

      before_action :set_participatory_text

      def index
        if component_settings.participatory_texts_enabled?
          @opinions = Decidim::Opinions::Opinion
                       .where(component: current_component)
                       .published
                       .not_hidden
                       .only_amendables
                       .includes(:category, :scope)
                       .order(position: :asc)
          render "decidim/opinions/opinions/participatory_texts/participatory_text"
        else
          @opinions = search
                       .results
                       .published
                       .not_hidden
                       .includes(:amendable, :category, :component, :resource_permission, :scope)

          @voted_opinions = if current_user
                               OpinionVote.where(
                                 author: current_user,
                                 opinion: @opinions.pluck(:id)
                               ).pluck(:decidim_opinion_id)
                             else
                               []
                             end
          @opinions = paginate(@opinions)
          @opinions = reorder(@opinions)
        end
      end

      def show
        raise ActionController::RoutingError, "Not Found" if @opinion.blank? || !can_show_opinion?

        @report_form = form(Decidim::ReportForm).from_params(reason: "spam")
      end

      def new
        enforce_permission_to :create, :opinion
        @step = :step_1
        if opinion_draft.present?
          redirect_to edit_draft_opinion_path(opinion_draft, component_id: opinion_draft.component.id, question_slug: opinion_draft.component.participatory_space.slug)
        else
          @form = form(OpinionWizardCreateStepForm).from_params(body: translated_opinion_body_template)
        end
      end

      def create
        enforce_permission_to :create, :opinion
        @step = :step_1
        @form = form(OpinionWizardCreateStepForm).from_params(opinion_creation_params)

        CreateOpinion.call(@form, current_user) do
          on(:ok) do |opinion|
            flash[:notice] = I18n.t("opinions.create.success", scope: "decidim")

            redirect_to Decidim::ResourceLocatorPresenter.new(opinion).path + "/compare"
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("opinions.create.error", scope: "decidim")
            render :new
          end
        end
      end

      def compare
        @step = :step_2
        @similar_opinions ||= Decidim::Opinions::SimilarOpinions
                               .for(current_component, @opinion)
                               .all

        if @similar_opinions.blank?
          flash[:notice] = I18n.t("opinions.opinions.compare.no_similars_found", scope: "decidim")
          redirect_to Decidim::ResourceLocatorPresenter.new(@opinion).path + "/complete"
        end
      end

      def complete
        enforce_permission_to :create, :opinion
        @step = :step_3

        @form = form_opinion_model

        @form.attachment = form_attachment_new
      end

      def preview
        @step = :step_4
      end

      def publish
        @step = :step_4
        PublishOpinion.call(@opinion, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("opinions.publish.success", scope: "decidim")
            redirect_to opinion_path(@opinion)
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("opinions.publish.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def edit_draft
        @step = :step_3
        enforce_permission_to :edit, :opinion, opinion: @opinion
      end

      def update_draft
        @step = :step_1
        enforce_permission_to :edit, :opinion, opinion: @opinion

        @form = form_opinion_params
        UpdateOpinion.call(@form, current_user, @opinion) do
          on(:ok) do |opinion|
            flash[:notice] = I18n.t("opinions.update_draft.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(opinion).path + "/preview"
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("opinions.update_draft.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def destroy_draft
        enforce_permission_to :edit, :opinion, opinion: @opinion

        DestroyOpinion.call(@opinion, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("opinions.destroy_draft.success", scope: "decidim")
            redirect_to new_opinion_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("opinions.destroy_draft.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def edit
        enforce_permission_to :edit, :opinion, opinion: @opinion
      end

      def update
        enforce_permission_to :edit, :opinion, opinion: @opinion

        @form = form_opinion_params
        UpdateOpinion.call(@form, current_user, @opinion) do
          on(:ok) do |opinion|
            flash[:notice] = I18n.t("opinions.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(opinion).path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("opinions.update.error", scope: "decidim")
            render :edit
          end
        end
      end

      def withdraw
        enforce_permission_to :withdraw, :opinion, opinion: @opinion

        WithdrawOpinion.call(@opinion, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("opinions.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(@opinion).path
          end
          on(:has_supports) do
            flash[:alert] = I18n.t("opinions.withdraw.errors.has_supports", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(@opinion).path
          end
        end
      end

      private

      def search_klass
        OpinionSearch
      end

      def default_filter_params
        {
          search_text: "",
          origin: default_filter_origin_params,
          activity: "all",
          category_id: default_filter_category_params,
          state: %w(accepted evaluating not_answered),
          scope_id: default_filter_scope_params,
          related_to: "",
          type: "all"
        }
      end

      def default_filter_origin_params
        filter_origin_params = %w(citizens meeting)
        filter_origin_params << "official" if component_settings.official_opinions_enabled
        filter_origin_params << "user_group" if current_organization.user_groups_enabled?
        filter_origin_params
      end

      def default_filter_category_params
        return "all" unless current_component.participatory_space.categories.any?

        ["all"] + current_component.participatory_space.categories.pluck(:id).map(&:to_s)
      end

      def default_filter_scope_params
        return "all" unless current_component.participatory_space.scopes.any?

        if current_component.participatory_space.scope
          ["all", current_component.participatory_space.scope.id] + current_component.participatory_space.scope.children.map { |scope| scope.id.to_s }
        else
          %w(all global) + current_component.participatory_space.scopes.pluck(:id).map(&:to_s)
        end
      end

      def opinion_draft
        Opinion.from_all_author_identities(current_user).not_hidden.only_amendables
                .where(component: current_component).find_by(published_at: nil)
      end

      def ensure_is_draft
        @opinion = Opinion.not_hidden.where(component: current_component).find(params[:id])
        redirect_to Decidim::ResourceLocatorPresenter.new(@opinion).path unless @opinion.draft?
      end

      def set_opinion
        @opinion = Opinion.published.not_hidden.where(component: current_component).find_by(id: params[:id])
      end

      # Returns true if the opinion is NOT an emendation or the user IS an admin.
      # Returns false if the opinion is not found or the opinion IS an emendation
      # and is NOT visible to the user based on the component's amendments settings.
      def can_show_opinion?
        return true if @opinion&.amendable? || current_user&.admin?

        Opinion.only_visible_emendations_for(current_user, current_component).published.include?(@opinion)
      end

      def opinion_presenter
        @opinion_presenter ||= present(@opinion)
      end

      def form_opinion_params
        form(OpinionForm).from_params(params)
      end

      def form_opinion_model
        form(OpinionForm).from_model(@opinion)
      end

      def form_presenter
        @form_presenter ||= present(@form, presenter_class: Decidim::Opinions::OpinionPresenter)
      end

      def form_attachment_new
        form(AttachmentForm).from_model(Attachment.new)
      end

      def edit_form
        form_attachment_model = form(AttachmentForm).from_model(@opinion.attachments.first)
        @form = form_opinion_model
        @form.attachment = form_attachment_model
        @form
      end

      def set_participatory_text
        @participatory_text = Decidim::Opinions::ParticipatoryText.find_by(component: current_component)
      end

      def translated_opinion_body_template
        translated_attribute component_settings.new_opinion_body_template
      end

      def opinion_creation_params
        params[:opinion].merge(body_template: translated_opinion_body_template)
      end
    end
  end
end
