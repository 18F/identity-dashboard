module ToolHelper
  def can_view_request_details?(sp)
    tool_policy(sp).can_view_request_details?
  end

  private

  def tool_policy(sp)
    ToolPolicy.new(current_user, sp)
  end
end
