class RedirectController < AuthenticatedController

  def show
    redirect_to 'https://developers.login.gov/', status: :moved_permanently, allow_other_host: true
  end

end