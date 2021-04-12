class UserSession
  attr_reader :user, :email

  def initialize(info)
    @email = info['email']
    @user = User.find_by(email: email) || unregistered_government_user

    puts "====="
    puts info.inspect
    puts "===="


    @user&.update!(uuid: info['uuid'])
  end

  def call
    user
  end

  private

  def unregistered_government_user
    allowed_tlds = (Figaro.env.auto_account_creation_tlds || '')&.split(',')

    return if allowed_tlds.filter do |tld|
      /(#{Regexp.escape(tld)})\Z/.match?(email)
    end.empty?

    @user = User.create(email: email)
  end
end
