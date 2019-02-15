# frozen_string_literal: true

module Decidim
  module Plans
    # A Helper to find and render the author of a version.
    module TraceabilityHelper
      include Decidim::TraceabilityHelper

      # Caches a DiffRenderer instance for the `current_version`.
      def item_diff_renderers
        @item_diff_renderers ||= item_versions.map do |version|
          renderer_for(version)
        end.compact
      end

      def associated_diff_renderers
        @associated_diff_renderers ||= associated_versions.map do |version|
          renderer_for(version)
        end.compact
      end

      def content_diff_renderers
        @content_diff_renderers ||= content_versions.map do |version|
          renderer_for(version)
        end.compact
      end

      def diff_renderers
        item_diff_renderers + associated_diff_renderers + content_diff_renderers
      end

      private

      def renderer_for(version)
        return nil if version.item.nil?

        locale = current_locale unless component_settings.multilingual_answers?

        item_klass = version.item.class.name
        lastpart = item_klass.split("::").last
        renderer_klass = "Decidim::Plans::DiffRenderer::#{lastpart}"

        return nil unless defined?(renderer_klass)

        renderer_klass.constantize.new(version, locale)
      end

      # Renders the given value in a user-friendly way based on the value class.
      #
      # value - an object to be rendered
      #
      # Returns an HTML-ready String.
      def render_diff_value(value, type, action, options = {})
        return "".html_safe if value.blank?

        value_to_render = case type
                          when :date
                            l value, format: :long
                          when :percentage
                            number_to_percentage value, precision: 2
                          when :translatable
                            value.to_s
                          else
                            value
                          end

        content_tag(:div, class: "card--list__item #{action}") do
          content_tag(:div, class: "card--list__text") do
            content_tag(:div, { class: "diff__value" }.merge(options)) do
              value_to_render
            end
          end
        end
      end
    end
  end
end
