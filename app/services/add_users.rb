class AddUsers
  attr_reader

  def initialize(team:, user_emails:)
    @team = team
    @user_emails = user_emails
  end

  def call; end
end
