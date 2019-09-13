# Help Text model
class HelpText < ApplicationRecord
  include ActionView::Helpers

  belongs_to :service_provider

  validates :service_provider_id, uniqueness: true, presence: true

  before_commit :sanitize_help_text_content

  private

  def sanitize_help_text_content
    sections = [sign_in, sign_up, forgot_password]
    sections.each { |section| sanitize_section(section) }
  end

  def sanitize_section(section)
    section.each do |_language, translation|
      translation.replace sanitize translation, tags: %w[a b br p], attributes: %w[href]
    end
  end
end
