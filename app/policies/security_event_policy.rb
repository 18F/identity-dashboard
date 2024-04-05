class SecurityEventPolicy < BasePolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @model = model
  end

  def index?
    current_user&.login_engineer?
  end

  def all?
    current_user&.login_engineer?
  end

  alias_method :search?, :all?

  def show?
    current_user&.login_engineer?
  end
end
