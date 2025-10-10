class UserSession # :nodoc:
  attr_reader :user, :email

  def initialize(info)
    @email = info['email']
    @user = User.find_by(email:) || unregistered_government_user
    @user&.update!(uuid: info['uuid'])
  end

  def call
    user
  end

  private

  def unregistered_government_user
    allowed_tlds = IdentityConfig.store.auto_account_creation_tlds.split(',')

    return if allowed_tlds.none? do |tld|
      /(#{Regexp.escape(tld)})\Z/.match?(email)
    end

    return if IdentityConfig.store.prod_like_env

    @user = User.create(email:)
  end
end
