# for logging redirects to external developer documentation
class DocsRedirectController < AuthenticatedController
  def show
    @destination = params[:destination] || ''
    unless @destination.blank?
      # allow alphanumeric, forward slash, hash, underscore, and hyphen
      @destination = @destination.tr('^A-Za-z0-9/#_-', '')
    end
    destination_url = "https://developers.login.gov#{@destination}"
    log_redirect(destination_url)
    redirect_to destination_url,
                status: :moved_permanently,
                allow_other_host: true
  end

  private

  def log_redirect(url)
    log.redirect(
      origin_url: request.referer || '',
      destination_url: url,
    )
  end
end
