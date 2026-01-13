#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yard'
require 'optparse'
require 'stringio'
require 'active_support/core_ext/object/blank'
require_relative 'identity_config'

# Parses YARD output for AnalyticsEvents methods
class EventsDocumenter
  DEFAULT_DATABASE_PATH = '.yardoc'

  DOCUMENTATION_OPTIONAL_PARAMS = %w[
    pii_like_keypaths
    active_profile_idv_level
    pending_profile_idv_level
    proofing_components
    profile_history
  ].freeze

  attr_reader :database_path, :class_name

  # @return [(String, Integer)] returns a tuple of (output, exit_status)
  def self.run(argv)
    exit_status = 0
    output = StringIO.new
    check = false
    help = false
    require_extra_params = true
    class_name = 'AnalyticsEvents'

    parser = OptionParser.new do |opts|
      opts.on('--check', 'Checks that all params are documented, will exit 1 if missing') do
        check = true
      end

      opts.on('--skip-extra-params') do
        require_extra_params = false
      end

      opts.on('--class-name=CLASS_NAME') do |c|
        class_name = c
      end

      opts.on('--help', 'print this help message') do
        help = true
      end
    end

    parser.parse!(argv)

    documenter = new(
      database_path: argv.first,
      class_name: class_name,
      require_extra_params: require_extra_params,
    )

    if help || !check
      output.puts parser
    elsif check
      missing_documentation = documenter.missing_documentation
      if missing_documentation.present?
        output.puts missing_documentation
        exit_status = 1
      else
        output.puts "All #{class_name} methods are documented! 🚀"
      end
    end

    [output.string.presence, exit_status]
  end

  def initialize(database_path:, class_name:, require_extra_params:)
    @database_path = database_path || DEFAULT_DATABASE_PATH
    @class_name = class_name
    @require_extra_params = require_extra_params
  end

  def require_extra_params?
    !!@require_extra_params
  end

  # rubocop:disable Metrics/BlockLength
  # Checks for params that are missing documentation, and returns a list of
  # @return [Array<String>]
  def missing_documentation
    analytics_methods.flat_map do |method_object|
      error_prefix = "#{method_object.file}:#{method_object.line} #{method_object.name}"
      errors = []

      param_names = param_names_for(method_object)
      trailing_param = method_object.parameters.last&.first
      documented_params = method_object.tags('param').map(&:name)
      missing_attributes = param_names - documented_params - DOCUMENTATION_OPTIONAL_PARAMS
      unless extract_event_name(method_object) || method_object.visibility.to_s == 'private'
        errors << "#{error_prefix} event name not detected in track_event"
      end

      missing_attributes.each do |attribute|
        errors << "#{error_prefix} #{attribute} (undocumented)"
      end

      if require_extra_params? && param_names.size > 0 && trailing_param != '**extra'
        errors << "#{error_prefix} missing **extra"
      end

      if method_object.signature.end_with?('*)')
        errors << "#{error_prefix} don't use * as an argument, remove all args or name args"
      end

      method_object.tags('param').each do |tag|
        errors << "#{error_prefix} #{tag.name} missing types" unless tag.types
      end

      description = method_description(method_object)
      if description.present? && !method_object.docstring.match?(/\A[A-Z]/)
        indented_description = description.lines.map { |line| "  #{line.chomp}" }.join("\n")

        errors << <<~MSG
          #{error_prefix} method description starts with lowercase, check indentation:
          #{indented_description}
        MSG
      end

      errors
    end
  end
  # rubocop:enable Metrics/BlockLength

  # Strips Rubocop directives from description text
  # @return [String, nil]
  def method_description(method_object)
    method_object.docstring.to_s.gsub(/^rubocop.+$/, '').presence&.chomp
  end

  private

  def param_names_for(method_object)
    param_names = method_object.parameters.map { |p| p.first }
    _splat_params, param_names = param_names.partition { |p| p.start_with?('**') }

    param_names.map { |p| p.chomp(':') }
  end

  # Naive attempt to pull tracked event string or symbol from source code
  def extract_event_name(method_object)
    # track_event("some event name")
    m = /track_event\(\s*["'](?<event_name>[^"']+)["',)]/.match(method_object.source)
    # track_event(:some_event_name)
    m ||= /track_event\(\s*:(?<event_name>[\w_]+)[,)]/.match(method_object.source)
    m && m[:event_name]
  end

  def database
    @database ||= YARD::Serializers::YardocSerializer.new(database_path).deserialize('root')
  end

  # @return [Array<YARD::CodeObjects::MethodObject>]
  def analytics_methods
    class_name_parts = class_name.split('::').map(&:to_sym)

    database.select do |_k, object|
      # this check will fail if the namespace is nested more than once
      method_object_name_parts = [object.namespace&.parent&.name, object.namespace&.name]
        .select { |part| part.present? && part != :root }

      object.type == :method && method_object_name_parts == class_name_parts
    end.values
  end
end

# rubocop:disable Rails/Output
# rubocop:disable Rails/Exit
if $PROGRAM_NAME == __FILE__
  output, status = EventsDocumenter.run(ARGV)
  puts output
  exit status
end
# rubocop:enable Rails/Exit
# rubocop:enable Rails/Output
