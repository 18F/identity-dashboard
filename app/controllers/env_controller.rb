# Controller for the "environments status" page
class EnvController < ApplicationController
  def index
    if IdentityConfig.store.prod_like_env
      render file: 'public/404.html', status: :not_found, layout: false
    else
      @deploy_statuses = deploy_status_checker.check!
    end
  end

  protected

  def deploy_status_checker
    @deploy_status_checker ||= DeployStatusChecker.new
  end
end
