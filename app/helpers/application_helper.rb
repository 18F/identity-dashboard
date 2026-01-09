module ApplicationHelper # :nodoc:
  def navigation_link_to(text, route)
    link_to text, route, class: [current_page?(route) && 'usa-current', 'usa-nav__link']
  end

  def page_heading(title)
    content_for(:title){ title }
    content_tag(:h1, title, class: 'usa-display')
  end
end
