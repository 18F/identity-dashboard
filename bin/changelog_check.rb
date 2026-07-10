#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'optparse'

CHANGELOG_REGEX =
  %r{^(?:\* )?changelog: ?(?<category>[\w -]{2,}), ?(?<subcategory>[^,]{2,}), ?(?<change>.+)$}i
CATEGORIES = [
  'User-Facing Improvements',
  'Bug Fixes',
  'Internal',
  'Upcoming Features',
].freeze
MAX_CATEGORY_DISTANCE = 3
SKIP_CHANGELOG_MESSAGE = '[skip changelog]'
DEPENDABOT_COMMIT_MESSAGE = 'Signed-off-by: dependabot[bot] <support@github.com>'
REVERT_COMMIT_MESSAGE = /This reverts commit ([a-z\d]+)./
SECURITY_CHANGELOG = {
  category: 'Internal',
  subcategory: 'Dependencies',
  change: 'Update dependencies to latest versions',
}.freeze
REVERT_CHANGELOG = {
  category: 'Bug Fixes',
  subcategory: 'Code Revert',
  change: 'Revert changes introduced in %s',
}.freeze

SquashedCommit = Struct.new(:title, :commit_messages, keyword_init: true)
ChangelogEntry = Struct.new(:category, :subcategory, :change, keyword_init: true)
CategoryDistance = Struct.new(:category, :distance)

# A valid entry has a line in a commit message in the form of:
# changelog: CATEGORY, SUBCATEGORY, CHANGE_DESCRIPTION
def build_changelog(line, find_revert: false)
  if line == DEPENDABOT_COMMIT_MESSAGE
    SECURITY_CHANGELOG
  elsif find_revert && (commit = REVERT_COMMIT_MESSAGE.match(line)&.[](1))
    REVERT_CHANGELOG.dup.merge(change: REVERT_CHANGELOG[:change] % [commit])
  else
    CHANGELOG_REGEX.match(line)
  end
end

def revert_commit?(commit)
  commit.title.start_with?('Revert ')
end

def build_changelog_from_commit(commit)
  [*commit.commit_messages, commit.title]
    .lazy
    .map { |message| build_changelog(message, find_revert: revert_commit?(commit)) }
    .find(&:itself)
end

def get_git_log(base_branch, source_branch)
  format = '--pretty=title: %s%nbody:%b%nDELIMITER'
  log, status = Open3.capture2(
    'git', 'log', format, "#{base_branch}..#{source_branch}"
  )

  raise 'git log failed' unless status.success?
  log
end

# Transforms a formatted git log into structured objects.
def build_structured_git_log(git_log)
  git_log.strip.split('DELIMITER').map do |commit|
    commit.split("\nbody:").map do |commit_message_lines|
      commit_message_lines.split(%r{[\r\n]}).filter { |line| line != '' }
    end
  end.map do |title_and_commit_messages|
    title = title_and_commit_messages.first.first.delete_prefix('title: ')
    messages = title_and_commit_messages[1]
    SquashedCommit.new(
      title: title,
      commit_messages: messages,
    )
  end
end

def commit_messages_contain_skip_changelog?(base_branch, source_branch)
  log, status = Open3.capture2(
    'git', 'log', '--pretty=\'%B\'', "#{base_branch}..#{source_branch}"
  )
  raise 'git log failed' unless status.success?

  log.include?(SKIP_CHANGELOG_MESSAGE)
end

def generate_invalid_changes(git_log)
  log = build_structured_git_log(git_log)
  log.reject do |commit|
    commit.title.include?(SKIP_CHANGELOG_MESSAGE) ||
      commit.commit_messages.any? { |message| message.include?(SKIP_CHANGELOG_MESSAGE) } ||
      build_changelog_from_commit(commit)
  end.map(&:title)
end

def closest_change_category(change)
  CATEGORIES
    .map do |category|
      CategoryDistance.new(
        category,
        DidYouMean::Levenshtein.distance(change[:category], category),
      )
    end
    .filter { |category_distance| category_distance.distance <= MAX_CATEGORY_DISTANCE }
    .max { |category_distance| category_distance.distance }
    &.category
end

# Finds valid changelog entries across all commits in the git log.
def generate_changelog(git_log)
  log = build_structured_git_log(git_log)

  changelog_entries = []
  log.each do |item|
    next if item.title.include?(SKIP_CHANGELOG_MESSAGE)
    next if item.commit_messages.any? { |message| message.include?(SKIP_CHANGELOG_MESSAGE) }
    change = build_changelog_from_commit(item)
    next unless change
    category = closest_change_category(change)
    next unless category

    changelog_entries << ChangelogEntry.new(
      category: category,
      subcategory: change[:subcategory],
      change: change[:change].sub(/./, &:upcase),
    )
  end

  changelog_entries
end

def parsed_options(args)
  options = { base_branch: 'main', source_branch: 'HEAD' }
  basename = File.basename($0)

  optparse = OptionParser.new do |opts|
    opts.banner = <<-EOM
      usage: #{basename} -s my-feature-branch [OPTIONS]

    EOM
    opts.on('-h', '--help', 'Display this message') do
      warn opts
      exit
    end

    opts.on('-b', '--base_branch BASE_BRANCH', 'Name of base branch, defaults to main') do |val|
      options[:base_branch] = val
    end

    opts.on(
      '-s',
      '--source_branch SOURCE_BRANCH',
      'Name of source branch, defaults to HEAD',
    ) do |val|
      options[:source_branch] = val
    end
  end

  optparse.parse!(args)
  options
end

def main(args)
  options = parsed_options(args)

  git_log = get_git_log(options[:base_branch], options[:source_branch])
  changelog_entries = generate_changelog(git_log)
  invalid_changelog_entries = generate_invalid_changes(git_log)

  skip_check = commit_messages_contain_skip_changelog?(
    options[:base_branch],
    options[:source_branch],
  )

  if skip_check || changelog_entries.count > 0
    if invalid_changelog_entries.count > 0
      puts "\n!!! Commits without a changelog line !!!"
      puts invalid_changelog_entries.join("\n")
    end

    exit 0
  else
    warn(
      <<~ERROR,
        A valid changelog line was not found.
        A commit message should contain a line in the form of:

        changelog: CATEGORY, SUBCATEGORY, CHANGE_DESCRIPTION

        example:
        changelog: User-Facing Improvements, Reports, Add partner report policy filter

        categories:
        #{CATEGORIES.map { |category| "- #{category}" }.join("\n")}

        Include "[skip changelog]" in a commit message to bypass this check.

        Note: the changelog message must be separated from any other commit message by a blank line.
      ERROR
    )

    exit 1
  end
end

main(ARGV) if __FILE__ == $0
