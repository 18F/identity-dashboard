# A tab component to allow view switching
#
# @example render a basic 3-tab component. Only final render should use <%=.
# <% tab_component = TabComponent.new(
#        opts: { class_name: 'test-me' }
#      ).add_tab(title: 'Tab One', id: 'tab1') do %>
#        <% render('components/step_progress', {
#         steps: ['all', 'edit', 'index', 'main'],
#         current_step_index: 3,
#         localization_base: 'headings.service_providers'}) %>
#   <% end %>
#   <% tab_component.add_tab(title: 'Tab Two', id: 'tab2', focusable: true) do %>
#     <% capture do %>
#       <p class="usa-prose">This is the…</p>
#       <p class="usa-prose">second tab panel!</p>
#       <a class="usa-link" href="#tab3">Go to tab 3</a>
#     <% end %>
#   <% end %>
#   <% tab_component.add_tab(title: 'Tab Three', id: 'tab3', focusable: true) do %>
#     <% render('components/step_progress', {
#       steps: ['en', 'es', 'fr', 'zh'],
#       current_step_index: 0,
#       localization_base: 'locale_map'}) %>
#   <% end %>
#   <%= render tab_component %>
class TabComponent < ViewComponent::Base
  attr_reader :tab_data, :opts

  # @param [Array] tab_data objects containing tab and panel info
  #  [{
  #    title: String tab title,
  #    id: String panel element ID,
  #    content: HTML/Partial,
  #    focusable: Boolean panel contains focusable elements,
  #  }],
  # @param [Object] opts options to be passed into HTML
  #  { class_name: String class name }
  def initialize(tab_data: [], opts: {})
    @tab_data, @opts = tab_data, opts
  end

  # @param [Object] tab_options any of tab_data options (see above)
  def add_tab(**tab_options)
    tab_options[:content] = yield if block_given?
    tab_data.push(tab_options)

    self
  end
end
