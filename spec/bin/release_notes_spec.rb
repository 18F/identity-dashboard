# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
load File.expand_path('../../bin/release-notes', __dir__)

RSpec.describe 'bin/release-notes' do
  around do |example|
    original_stdout = $stdout
    $stdout = StringIO.new
    example.run
    $stdout = original_stdout
  end

  def commit(sha: 'abc12345', title: 'A commit', commit_messages: [])
    Commit.new(sha: sha, title: title, commit_messages: commit_messages)
  end

  def git_log_chunk(sha:, title:, body: [])
    ["sha:#{sha}", "title:#{title}", "body:#{body.join("\n")}", 'DELIMITER'].join("\n")
  end

  describe '#run_git' do
    it 'returns the command output on success' do
      allow(Open3).to receive(:capture2).with('git', 'status').and_return(
        ['clean', instance_double(Process::Status, success?: true)],
      )

      expect(run_git('status')).to eq 'clean'
    end

    it 'raises when the git command fails' do
      allow(Open3).to receive(:capture2).with('git', 'status').and_return(
        ['', instance_double(Process::Status, success?: false)],
      )

      expect { run_git('status') }.to raise_error(/git status failed/)
    end
  end

  describe '#recent_tags' do
    it 'returns up to the three most recent tags, newest first' do
      allow(Open3).to receive(:capture2).with('git', 'tag', '--sort=-creatordate').and_return(
        ["v4\nv3\nv2\nv1\n", instance_double(Process::Status, success?: true)],
      )

      expect(recent_tags).to eq %w[v4 v3 v2]
    end
  end

  describe '#commit_range' do
    let(:tags) { %w[v3 v2 v1] }

    it 'ranges from the tag to main when one tag is selected' do
      expect(commit_range(['v2'], tags)).to eq 'v2..main'
    end

    it 'ranges inclusively between two tags, regardless of selection order' do
      expect(commit_range(%w[v1 v3], tags)).to eq 'v1^..v3'
      expect(commit_range(%w[v3 v1], tags)).to eq 'v1^..v3'
    end
  end

  describe '#commits_since' do
    it 'parses commits out of the git log output' do
      git_log = [
        git_log_chunk(sha: 'aaa111', title: 'Fix bug',
                      body: ['changelog: Bug Fixes, Reports, Fix it']),
        git_log_chunk(sha: 'bbb222', title: 'Add feature'),
      ].join("\n")
      allow(Open3).to receive(:capture2).with('git', 'log', anything, 'v1..main').and_return(
        [git_log, instance_double(Process::Status, success?: true)],
      )

      commits = commits_since('v1..main')

      expect(commits.length).to eq 2
      expect(commits.first).to have_attributes(
        sha: 'aaa111',
        title: 'Fix bug',
        commit_messages: ['changelog: Bug Fixes, Reports, Fix it'],
      )
      expect(commits.last).to have_attributes(sha: 'bbb222', title: 'Add feature',
                                              commit_messages: [])
    end
  end

  describe '#build_entries' do
    it 'builds a changelog entry from a commit with a valid changelog line' do
      commits = [
        commit(title: 'Add thing',
               commit_messages: ['changelog: bug fixes, reports, fix the thing']),
        commit(title: 'No changelog line'),
      ]

      entries = build_entries(commits)

      expect(entries.length).to eq 1
      expect(entries.first).to have_attributes(
        category: 'Bug Fixes',
        subcategory: 'Reports',
        change: 'Fix the thing',
      )
    end
  end

  describe '#print_release_notes' do
    it 'prints a message when there are no entries' do
      print_release_notes([])

      expect($stdout.string).to include('No changelog entries found in the selected commits.')
    end

    it 'prints entries grouped by category, in CATEGORIES order, then by subcategory' do
      entries = [
        ChangelogEntry.new(category: 'Bug Fixes', subcategory: 'Reports', change: 'Fix one'),
        ChangelogEntry.new(category: 'User-Facing Improvements', subcategory: 'Sign In',
                           change: 'New thing'),
        ChangelogEntry.new(category: 'Bug Fixes', subcategory: 'Reports', change: 'Fix two'),
      ]

      print_release_notes(entries)

      output = $stdout.string
      expect(output.index('User-Facing Improvements')).to be < output.index('Bug Fixes')
      expect(output).to include("  Sign In:\n    - New thing")
      expect(output).to include("  Reports:\n    - Fix one\n    - Fix two")
    end

    it 'omits categories with no entries' do
      entries = [ChangelogEntry.new(category: 'Bug Fixes', subcategory: 'Reports',
                                    change: 'Fix one')]

      print_release_notes(entries)

      expect($stdout.string).to_not include('User-Facing Improvements')
    end
  end

  describe '#prompt_tag_selection' do
    it 'returns the single selected tag' do
      allow($stdin).to receive(:getch).and_return(' ', "\r")

      expect(prompt_tag_selection(%w[v3 v2 v1])).to eq ['v3']
    end

    it 'caps selection at two tags, ignoring further toggles' do
      allow($stdin).to receive(:getch).and_return(
        ' ', +"\e", '[', 'B', ' ', +"\e", '[', 'B', ' ', "\r"
      )

      expect(prompt_tag_selection(%w[v3 v2 v1])).to eq %w[v3 v2]
    end
  end

  describe '#prompt_selection' do
    let(:commits) { [commit(sha: 'aaa', title: 'First'), commit(sha: 'bbb', title: 'Second')] }

    it 'returns only the checked commits' do
      allow($stdin).to receive(:getch).and_return(' ', "\r")

      expect(prompt_selection(commits, 'v1..main')).to eq [commits.first]
    end

    it "toggles every commit with 'a'" do
      allow($stdin).to receive(:getch).and_return('a', "\r")

      expect(prompt_selection(commits, 'v1..main')).to eq commits
    end
  end

  describe '#run_release_notes' do
    let(:status) { instance_double(Process::Status, success?: true) }

    it 'aborts when no tags are found' do
      allow(Open3).to receive(:capture2).with('git', 'tag', '--sort=-creatordate')
        .and_return(['', status])

      expect { run_release_notes }.to raise_error(SystemExit)
    end

    it 'prints a message and returns early when no commits are found for the selected range' do
      allow(Open3).to receive(:capture2).with('git', 'tag', '--sort=-creatordate')
        .and_return(["v2\nv1\n", status])
      allow(Open3).to receive(:capture2).with('git', 'log', anything, 'v1..main')
        .and_return(['', status])
      allow($stdin).to receive(:getch).and_return(+"\e", '[', 'B', ' ', "\r")

      run_release_notes

      expect($stdout.string).to include('No commits found for v1..main.')
    end

    it 'walks tag selection through to publishing when commits are found' do
      git_log = git_log_chunk(
        sha: 'aaa123', title: 'First', body: ['changelog: Bug Fixes, X, Fix one'],
      )
      allow(Open3).to receive(:capture2).and_return(['', status])
      allow(Open3).to receive(:capture2).with('git', 'tag', '--sort=-creatordate')
        .and_return(["v2\nv1\n", status])
      allow(Open3).to receive(:capture2).with('git', 'log', anything, 'v1..main')
        .and_return([git_log, status])
      allow(Open3).to receive(:capture2).with('whoami').and_return(["iamme\n", status])
      allow($stdin).to receive(:getch).and_return(
        +"\e", '[', 'B', ' ', "\r", # select the v1 tag
        ' ', "\r" # select the one commit found
      )
      allow($stdin).to receive(:gets).and_return("y\n")

      Tempfile.create(['release-notes', '.md']) do |file|
        file.write(<<~MD)
          <dl class="usa-accordion usa-accordion--bordered">

          </dl>
        MD
        file.flush
        stub_const('DevDocs::RELEASE_NOTES_FILE', file.path)

        run_release_notes

        output = $stdout.string
        expect(output).to include('Bug Fixes')
        expect(output).to include('    - Fix one')
        expect(File.read(file.path)).to include('* Fix one')
      end
    end
  end

  describe DevDocs do
    describe '.accordion_content' do
      it 'groups entries by category, in CATEGORIES order' do
        entries = [
          ChangelogEntry.new(category: 'Bug Fixes', subcategory: 'X', change: 'Fix one'),
          ChangelogEntry.new(category: 'User-Facing Improvements', subcategory: 'Y',
                             change: 'New thing'),
        ]

        expect(DevDocs.accordion_content(entries)).to eq(
          "### User-Facing Improvements\n* New thing\n\n### Bug Fixes\n* Fix one",
        )
      end
    end

    describe '.uncommitted_changes?' do
      it 'returns true when git status reports changes' do
        allow(DevDocs).to receive(:git).with('status', '--porcelain').and_return(" M file.md\n")

        expect(DevDocs.uncommitted_changes?).to eq true
      end

      it 'returns false when git status is clean' do
        allow(DevDocs).to receive(:git).with('status', '--porcelain').and_return('')

        expect(DevDocs.uncommitted_changes?).to eq false
      end
    end

    describe '.sync_main' do
      it 'aborts when there are uncommitted changes' do
        allow(DevDocs).to receive(:uncommitted_changes?).and_return(true)

        expect { DevDocs.sync_main }.to raise_error(SystemExit)
      end

      it 'checks out and pulls main when there are no uncommitted changes' do
        allow(DevDocs).to receive(:uncommitted_changes?).and_return(false)
        allow(DevDocs).to receive(:git)

        DevDocs.sync_main

        expect(DevDocs).to have_received(:git).with('checkout', 'main').ordered
        expect(DevDocs).to have_received(:git).with('pull').ordered
      end
    end

    describe '.commit_release_notes' do
      it 'checks out a branch named for the user and date, then commits the release notes file' do
        allow(Open3).to receive(:capture2).with('whoami').and_return(["iamme\n", nil])
        allow(DevDocs).to receive(:git)

        branch = DevDocs.commit_release_notes('2026-07-24')

        expect(branch).to eq 'iamme/release-notes/rc-2026-07-24'
        expect(DevDocs).to have_received(:git).with('checkout', '-b', branch).ordered
        expect(DevDocs).to have_received(:git).with('add', '_pages/release-notes.md').ordered
        expect(DevDocs).to have_received(:git)
          .with('commit', '-m', 'Release Notes for RC 2026-07-24').ordered
      end
    end

    describe '.push_branch' do
      it 'pushes the branch when the user confirms' do
        allow(DevDocs).to receive(:git).with('show', '--color=always', 'HEAD').and_return('diff')
        allow(DevDocs).to receive(:git).with('push', '-u', 'origin',
'my-branch').and_return('pushed')
        allow($stdin).to receive(:gets).and_return("y\n")

        DevDocs.push_branch('my-branch')

        expect(DevDocs).to have_received(:git).with('push', '-u', 'origin', 'my-branch')
      end

      it 'does not push when the user declines' do
        allow(DevDocs).to receive(:git).with('show', '--color=always', 'HEAD').and_return('diff')
        allow($stdin).to receive(:gets).and_return("n\n")

        DevDocs.push_branch('my-branch')

        expect(DevDocs).to_not have_received(:git).with('push', anything, anything, anything)
      end
    end

    describe '.accordion_block' do
      it 'builds a jekyll accordion include for the given date and entries' do
        entries = [ChangelogEntry.new(category: 'Bug Fixes', subcategory: 'X', change: 'Fix one')]

        block = DevDocs.accordion_block('2026-07-24', entries)

        expect(block).to include('id="track-2026-07-24"')
        expect(block).to include('title="2026-07-24"')
        expect(block).to include('* Fix one')
      end
    end

    describe '.write_release_notes' do
      it 'inserts a new accordion block at the top of the accordion list' do
        Tempfile.create(['release-notes', '.md']) do |file|
          file.write(<<~MD)
            <dl class="usa-accordion usa-accordion--bordered">

            </dl>
          MD
          file.flush
          stub_const('DevDocs::RELEASE_NOTES_FILE', file.path)
          entries = [ChangelogEntry.new(category: 'Bug Fixes', subcategory: 'X', change: 'Fix one')]

          DevDocs.write_release_notes('2026-07-24', entries)

          updated = File.read(file.path)
          expect(updated).to include('id="track-2026-07-24"')
          expect(updated.index('track-2026-07-24')).to be < updated.index('</dl>')
        end
      end
    end
  end

  describe '#publish_release_notes' do
    let(:entries) do
      [
        ChangelogEntry.new(category: 'Bug Fixes', subcategory: 'X', change: 'Fix one'),
        ChangelogEntry.new(category: 'Internal', subcategory: 'Y', change: 'Internal only'),
        ChangelogEntry.new(category: 'Upcoming Features', subcategory: 'Z', change: 'Coming soon'),
      ]
    end

    context 'when the user confirms the update' do
      it 'syncs main, publishes only the public-facing entries, then commits and pushes' do
        allow($stdin).to receive(:gets).and_return("y\n")
        allow(DevDocs).to receive(:sync_main)
        allow(DevDocs).to receive(:write_release_notes)
        allow(DevDocs).to receive(:commit_release_notes).and_return('branch-name')
        allow(DevDocs).to receive(:push_branch)

        publish_release_notes(entries)

        expect(DevDocs).to have_received(:sync_main).ordered
        expect(DevDocs).to have_received(:write_release_notes).ordered do |_today, public_entries|
          expect(public_entries.map(&:change)).to eq ['Fix one']
        end
        expect(DevDocs).to have_received(:push_branch).with('branch-name')
      end
    end

    context 'when the user declines the update' do
      it 'does not touch the dev docs repo' do
        allow($stdin).to receive(:gets).and_return("n\n")
        allow(DevDocs).to receive(:write_release_notes)

        publish_release_notes(entries)

        expect(DevDocs).to_not have_received(:write_release_notes)
      end
    end

    context 'when there are no public-facing entries' do
      it 'returns without prompting' do
        allow($stdin).to receive(:gets)
        internal_only = [ChangelogEntry.new(category: 'Internal', subcategory: 'Y',
                                            change: 'Internal only')]

        publish_release_notes(internal_only)

        expect($stdin).to_not have_received(:gets)
      end
    end
  end
end
