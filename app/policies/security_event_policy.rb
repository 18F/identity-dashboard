class SecurityEventPolicy < BasePolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @model = model
  end

  def index?
    current_user.present?
  end

  def all?
    current_user&.admin?
  end

  def show?
    current_user.present? && (current_user.admin? || model.user == current_user)
  end
end
