# A tab component to allow view switching
#
# @example render a basic 3-tab component
# <%= render(TabComponent.new(tab_data: [
#     { title: 'Tab One',
#       id: 'tab1',
#       content: render('components/feature_card', {
#         icon: 'accessible_forward',
#         title: 'footer.performance',
#         body: 'forms.confirm_service_provider'}),
#       focusable: false,
#     },
#     { title: 'Tab Two',
#       id: 'tab2',
#       content: render('components/feature_card', {
#         icon: 'assessment',
#         title: 'footer.no_fear_act',
#         body: 'team_memberships.rbac_description'}),
#       focusable: false,
#     },
#     { title: 'Tab Three',
#       id: 'tab3',
#       content: render('components/feature_card', {
#         icon: 'electrical_services',
#         title: 'footer.status',
#         body: 'footer.disclaimer_html'}),
#       focusable: true
#     },
#   ], opts: { class_name: 'test-me' })) %>
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
  def initialize(tab_data:, opts: {})
    @tab_data, @opts = tab_data, opts
  end
end
