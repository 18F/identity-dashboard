class ExtractsController < AuthenticatedController
  def index
    @extract ||= Extract.new
  end

  def create
    # populate extract method with params
  end
end

class Extract
  include ActiveModel::API

  attr_accessor :ticket, :team_search, :criteria_file, :extract_list

  # do activeRecord validation syntax stuff here
end
