# Helper for Application views
module ApplicationHelper
  def navigation_link_to(text, route)
    link_to text, route, class: [current_page?(route) && 'usa-current', 'usa-nav__link']
  end
end
