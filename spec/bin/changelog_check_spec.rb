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
        commit_log(title: 'Add partner report policy filter (#123)',
                   body: ['changelog: Bug Fixes, Reports, Fix filter']),
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

  describe '#main' do
    def run_main(args = [])
      main(args)
    rescue SystemExit => err
      err.status
    end

    context 'when a commit has a valid changelog line' do
      before do
        allow(self).to receive(:get_git_log).and_return(
          commit_log(title: 'Add partner report policy filter (#123)',
                     body: ['changelog: Bug Fixes, Reports, Fix filter']),
        )
        allow(self).to receive(:commit_messages_contain_skip_changelog?).and_return(false)
      end

      it 'exits successfully' do
        expect(run_main).to eq 0
      end
    end

    context 'when some commits are missing a changelog line' do
      before do
        allow(self).to receive(:get_git_log).and_return(
          [
            commit_log(title: 'Add partner report policy filter (#123)',
                       body: ['changelog: Bug Fixes, Reports, Fix filter']),
            commit_log(title: 'Fix typo'),
          ].join("\n"),
        )
        allow(self).to receive(:commit_messages_contain_skip_changelog?).and_return(false)
      end

      it 'exits successfully but warns about the commits missing a changelog line' do
        status = nil

        expect { status = run_main }.to output(/Fix typo/).to_stdout

        expect(status).to eq 0
      end
    end

    context 'when no commits have a changelog line and none are skipped' do
      before do
        allow(self).to receive(:get_git_log).and_return(commit_log(title: 'Fix typo'))
        allow(self).to receive(:commit_messages_contain_skip_changelog?).and_return(false)
      end

      it 'exits with an error explaining the requirement' do
        status = nil

        expect { status = run_main }.to output(/A valid changelog line was not found/).to_stderr

        expect(status).to eq 1
      end
    end

    context 'when a commit contains [skip changelog]' do
      before do
        allow(self).to receive(:get_git_log).and_return(commit_log(title: 'Fix typo'))
        allow(self).to receive(:commit_messages_contain_skip_changelog?).and_return(true)
      end

      it 'exits successfully' do
        status = nil

        expect { status = run_main }.to output.to_stdout

        expect(status).to eq 0
      end
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
