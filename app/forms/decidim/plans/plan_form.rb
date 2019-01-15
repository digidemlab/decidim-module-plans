# frozen_string_literal: true

module Decidim
  module Plans
    # A form object to be used when public users want to create a Plan.
    class PlanForm < Decidim::Form
      include TranslatableAttributes
      mimic :plan

      alias component current_component

      translatable_attribute :title, String

      attribute :user_group_id, Integer
      attribute :category_id, Integer
      attribute :scope_id, Integer
      attribute :attachment, AttachmentForm
      attribute :contents, Array[ContentForm]

      validates :category, presence: true, if: ->(form) { form.category_id.present? }
      validates :scope, presence: true, if: ->(form) { form.scope_id.present? }
      validates :title, translatable_presence: true

      validate :scope_belongs_to_participatory_space_scope

      validate :notify_missing_attachment_if_errored

      delegate :categories, to: :current_component

      # Finds the Category from the category_id.
      #
      # Returns a Decidim::Category
      def category
        @category ||= categories.find_by(id: category_id)
      end

      # Finds the Scope from the given decidim_scope_id, uses participatory space scope if missing.
      #
      # Returns a Decidim::Scope
      def scope
        @scope ||= @scope_id ? current_participatory_space.scopes.find_by(id: @scope_id) : current_participatory_space.scope
      end

      # Scope identifier
      #
      # Returns the scope identifier related to the plan
      def scope_id
        @scope_id || scope&.id
      end

      def map_model(model)
        self.contents = model.sections.map do |section|
          ContentForm.from_model(
            Content
              .where(plan: model, section: section)
              .first_or_initialize(plan: model, section: section)
          )
        end

        self.user_group_id = model.user_groups.first&.id
        return unless model.categorization

        self.category_id = model.categorization.decidim_category_id
      end

      def user_group
        @user_group ||= Decidim::UserGroup.find user_group_id if user_group_id.present?
      end

      private

      def scope_belongs_to_participatory_space_scope
        errors.add(:scope_id, :invalid) if current_participatory_space.out_of_scope?(scope)
      end

      # This method will add an error to the `attachment` field only if there's
      # any error in any other field. This is needed because when the form has
      # an error, the attachment is lost, so we need a way to inform the user of
      # this problem.
      def notify_missing_attachment_if_errored
        errors.add(:attachment, :needs_to_be_reattached) if errors.any? && attachment.present?
      end
    end
  end
end