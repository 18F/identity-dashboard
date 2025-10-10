module ToolHelper # :nodoc:
  def can_view_request_details?(sp)
    tool_policy(sp).can_view_request_details?
  end

  def syntax_highlight(xml)
    formatter = Rouge::Formatters::HTML.new(css_class: 'highlight')
    lexer = Rouge::Lexers::XML.new
    formatter.format(lexer.lex(xml)).html_safe
  end

  private

  def tool_policy(sp)
    ToolPolicy.new(current_user, sp)
  end
end
