# for logging redirects to external developer documentation
class DocsRedirectController < AuthenticatedController
  def show
    @destination = params[:destination] || ''
    unless @destination.blank?
      # remove leading slash + allow alphanumeric, forward slash, hash, underscore, and hyphen
      @destination = @destination.sub(%r{^/}, '').tr('^A-Za-z0-9/#_-', '')
    end
    log_redirect
    redirect_to "https://developers.login.gov/#{@destination}",
                status: :moved_permanently,
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
