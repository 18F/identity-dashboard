module ApplicationHelper # :nodoc:
  include Chartkick::Helper

  def navigation_link_to(text, route)
    link_to text, route, class: [current_page?(route) && 'usa-current', 'usa-nav__link']
  end

  def page_heading(title)
    content_for(:title) { title }
    content_tag(:h1, title, class: 'usa-display')
  end

  # TODO: This should be removed in favor of having an error component for flash messages.
  # Don't use this.
  def wrap_in_p_tag(text, css_class: nil)
    content_tag(:p, text, class: css_class).html_safe # rubocop:disable Rails/OutputSafety
  end
end
