# for logging redirects to external developer documentation
class RedirectController < AuthenticatedController
  def show
    @destination = params[:destination].to_s.gsub(%r{^/}, '')
    log_redirect
    redirect_to "https://developers.login.gov/#{@destination}", status: :moved_permanently,
allow_other_host: true
  end

  private

  def log_redirect
    log.redirect(
      origin_url: request.referer || '',
      destination_url: "https://developers.login.gov/#{@destination}",
    )
  end
end
