# frozen_string_literal: true

module Decidim
  module Plans
    module SectionTypeEdit
      class FieldScopeCell < Decidim::Plans::SectionEditCell
        delegate :current_participatory_space, to: :controller

        def show
          return unless scopes_root

          render
        end

        private

        # Renders a scopes select field in a form.
        # form - FormBuilder object
        # name - attribute name
        # options - Options for the select field
        # html_options - HTML options for the select field
        #
        # Returns nothing.
        def scopes_picker_field(form, name, options: {}, html_options: {})
          options[:label] ||= translated_attribute(section.body)
          form.select(name, scopes_options(scopes_root), options, html_options)
        end

        def scopes_root
          @scopes_root ||= begin
            Decidim::Scope.find_by(id: settings["scope_parent"]) ||
              current_participatory_space.scope
          end
        end

        def scopes_options(parent, name_prefix = "")
          options = []
          scope_children(parent).each do |scope|
            options.push(["#{name_prefix}#{translated_attribute(scope.name)}", scope.id])

            sub_prefix = "#{name_prefix}#{translated_attribute(scope.name)} / "
            options.push(*scopes_options(scope, sub_prefix))
          end
          options
        end

        def scope_children(scope)
          scope.children.order("code, name->>'#{current_locale}'")
        end
      end
    end
  end
end