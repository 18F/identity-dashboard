module ApplicationHelper
  def navigation_link_to(text, route)
    link_to text, route, class: [current_page?(route) && 'usa-current', 'usa-nav__link']
  end

  def ga4_tag
    return '' unless IdentityConfig.store&.google_analytics_enabled
    <<~EOF.html_safe
      <!-- We participate in the US government's analytics program. See the data at analytics.usa.gov. -->
      <script async
        type="text/javascript"
        src="https://dap.digitalgov.gov/Universal-Federated-Analytics-Min.js?agency=GSA&subagency=TTS"
        id="_fed_an_ua_tag">
      </script>
    EOF
  end
end
