# frozen_string_literal: true

Decidim::CellsHelper.module_eval do

  def opinions_controller?
    context[:controller].class.to_s == "Decidim::Opinions::OpinionsController"
  end

  def withdrawable?
    return unless from_context
    return unless proposals_controller? || opinions_controller?
    return if index_action?
    from_context.withdrawable_by?(current_user)
  end

  def flagable?
    return unless from_context
    return unless proposals_controller? || collaborative_drafts_controller? || opinions_controller?
    return if index_action?
    return if from_context.try(:official?)
    true
  end
end