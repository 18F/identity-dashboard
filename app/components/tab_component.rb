# A tab component to allow view switching
#
# @example render a basic 3-tab component. Only final render should use <%=.
# <% tab_component = TabComponent.new(
#              opts: { class_name: 'test-me' }
#            ).add_tab(title: 'Tab One', id: 'tab1') do %>
#      <% render('components/feature_card', {
#           icon: 'accessible_forward',
#           title: 'footer.performance',
#           body: 'forms.confirm_service_provider'}) %>
# <% end %>
# <% tab_component.add_tab(title: 'Tab Two', id: 'tab2') do %>
#     <% render('components/feature_card', {
#           icon: 'assessment',
#           title: 'footer.no_fear_act',
#           body: 'team_memberships.rbac_description'}) %>
# <% end %>
# <% tab_component.add_tab(title: 'Tab Three', id: 'tab', focusable: true) do %>
#     <% render('components/feature_card', {
#           icon: 'electrical_services',
#           title: 'footer.status',
#           body: 'footer.disclaimer_html'}) %>
# <% end %>
# <%= render tab_component %>
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
  # @yield [block] Tab panel contents (optional)
  def add_tab(**tab_options)
    tab_options[:content] = yield if block_given?
    tab_data.push(tab_options)

    self
  end
end
