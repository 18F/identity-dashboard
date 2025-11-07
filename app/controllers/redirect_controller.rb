class RedirectController < AuthenticatedController
  def show
    destination = params[:destination].to_s.gsub(%r{^/}, '')
    redirect_to "https://developers.login.gov/#{destination}", status: :moved_permanently,
allow_other_host: true
  end
end
