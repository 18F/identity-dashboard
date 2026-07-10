require 'spec_helper'
load File.expand_path('../../bin/changelog_check.rb', __dir__)

RSpec.describe 'bin/changelog_check.rb' do
  def commit_log(title:, body: [])
    ["title: #{title}", "body:#{body.join("\n")}", 'DELIMITER'].join("\n")
  end

  describe '#generate_changelog' do
    it 'finds a valid changelog line in a commit body' do
      git_log = commit_log(
        title: 'Add partner report policy filter (#123)',
        body: ['changelog: User-Facing Improvements, Reports, Add partner report policy filter'],
      )

      changelog = generate_changelog(git_log)

      expect(changelog.length).to eq 1
      expect(changelog.first.category).to eq 'User-Facing Improvements'
      expect(changelog.first.subcategory).to eq 'Reports'
      expect(changelog.first.change).to eq 'Add partner report policy filter'
    end

    it 'snaps a slightly misspelled category to the closest match' do
      git_log = commit_log(
        title: 'Fix bug (#124)',
        body: ['changelog: Bug Fix, Reports, Fix broken filter'],
      )

      changelog = generate_changelog(git_log)

      expect(changelog.first.category).to eq 'Bug Fixes'
    end

    it 'auto-tags dependabot commits' do
      git_log = commit_log(
        title: 'Bump rails from 7.0.0 to 7.0.1',
        body: ['Signed-off-by: dependabot[bot] <support@github.com>'],
      )

      changelog = generate_changelog(git_log)

      expect(changelog.first.category).to eq 'Internal'
      expect(changelog.first.subcategory).to eq 'Dependencies'
    end

    it 'skips commits containing [skip changelog]' do
      git_log = commit_log(title: 'Tweak README [skip changelog]')

      expect(generate_changelog(git_log)).to be_empty
    end
  end

  describe '#generate_invalid_changes' do
    it 'returns titles of commits missing a valid changelog line' do
      git_log = [
        commit_log(title: 'Add partner report policy filter (#123)', body: ['changelog: Bug Fixes, Reports, Fix filter']),
        commit_log(title: 'Fix typo'),
      ].join("\n")

      invalid = generate_invalid_changes(git_log)

      expect(invalid).to eq ['Fix typo']
    end

    it 'does not flag commits containing [skip changelog]' do
      git_log = commit_log(title: 'Tweak README [skip changelog]')

      expect(generate_invalid_changes(git_log)).to be_empty
    end
  end

  describe '#parsed_options' do
    it 'populates default values' do
      expect(parsed_options([])).to eq({ base_branch: 'main', source_branch: 'HEAD' })
    end

    it 'assigns base_branch and source_branch from arguments' do
      options = parsed_options(['-b', 'origin/main', '-s', 'origin/feature'])

      expect(options).to eq({ base_branch: 'origin/main', source_branch: 'origin/feature' })
    end
  end
end
