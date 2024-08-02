module ApplicationHelper
  def navigation_link_to(text, route)
    link_to text, route, class: [current_page?(route) && 'usa-current', 'usa-nav__link']
  end

  def ga4_tag
    return '' unless IdentityConfig.store.google_analytics_state
    <<~EOF.html_safe
    <script async
      type="text/javascript"
      agency="GSA"
      id="_fed_an_ua_tag"
      src="https://dap.digitalgov.gov/Universal-Federated-Analytics-Min.js?agency=GSA&dapdev=true"></script>
    EOF
  end
end
