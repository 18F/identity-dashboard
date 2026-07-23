# Controller for the Release Notes page
class ReleaseNotesController < ApplicationController
  RELEASE_NOTES_FILE = Rails.root.join('config/release_notes.yml')

  def index
    @releases = YAML.load_file(RELEASE_NOTES_FILE)['releases']
    render 'release_notes/index'
  end
end
