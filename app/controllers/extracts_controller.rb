class ExtractsController < AuthenticatedController
  # before_action -> { authorize Extract }

  # after_action :verify_authorized
  # after_action :verify_policy_scoped

  before_action :log_request, only: %i[create]

  def index
    @extract ||= Extract.new
  end

  def create
    extracts_params.to_h => {
      ticket:,
      team_search:,
      extract_list:,
    }
    list_criteria = extract_list.split(/,\s*|\s+/) unless extract_list.strip.empty?
    file_criteria = []
    criteria = [].union list_criteria, file_criteria

    configs = team_search ?
      ServiceProvider.where(group_id: criteria) :
      ServiceProvider.where(issuer: criteria)
    
    if configs.empty?
      flash[:error] = 'No ServiceProvider rows were returned.'
    elsif configs.length != criteria.length
      flash[:notice] = "Some issuers were invalid. Please check the results."
    end
  end

  private

  def extracts_params
    params.require(:extract).permit(
      :ticket,
      :team_search,
      :criteria_file,
      :extract_list,
    )
  end

  def log_request
    log.extraction_request(action_name, extracts_params)
  end
end

class Extract
  include ActiveModel::API
  include ActiveModel::Validations

  attr_accessor :ticket, :team_search, :criteria_file, :extract_list

  # do activeRecord validation syntax stuff here
  validates :ticket, presence: true
  validates :team_search, inclusion: { in: [true, false] }
end

# class ExtractPolicy < BasePolicy
#   attr_reader :user, :record

#   PARAMS = [:ticket, :team_search, :criteria_file, :extract_list].freeze
  
#   def permitted_attributes
#     PARAMS  
#   end

#   class Scope < BasePolicy::Scope
#     def resolve
#       binding.pry
#       return scope if user_has_login_admin_role? && !IdentityConfig.store.prod_like_env
#     end
#   end
# end
