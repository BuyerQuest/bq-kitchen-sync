require 'test_helper'
require 'kitchen/transport/rsync'

class RsyncConnectionTest < Minitest::Test
  class Logger
    attr_reader :debug_messages, :warn_messages, :info_messages
    attr_accessor :level

    def initialize
      @level = :info
      @debug_messages = []
      @warn_messages = []
      @info_messages = []
    end

    def debug(message)
      @debug_messages << message
    end

    def warn(message)
      @warn_messages << message
    end

    def info(message)
      @info_messages << message
    end

    def debug?
      level == :debug
    end
  end

  Session = Struct.new(:options, :host)

  def test_upload_falls_back_to_scp_when_rsync_fails
    connection = Kitchen::Transport::Rsync::Connection.allocate
    logger = Logger.new
    session = Session.new({ user: 'ubuntu', port: 22 }, 'example.test')

    connection.instance_variable_set(:@logger, logger)
    connection.instance_variable_set(:@options, {})
    connection.instance_variable_set(:@session, session)
    connection.instance_variable_set(:@username, 'ubuntu')
    connection.instance_variable_set(:@hostname, 'example.test')

    connection.define_singleton_method(:copy_identity) {}
    connection.define_singleton_method(:system) { |_cmd| false }

    fallback_calls = []
    ssh_connection = Kitchen::Transport::Ssh::Connection
    original_upload = ssh_connection.instance_method(:upload)
    without_redefinition_warnings do
      ssh_connection.define_method(:upload) do |locals, remote|
        fallback_calls << [locals, remote]
        :fallback_upload
      end
    end

    system('false')

    result = nil
    assert_silent_name_error do
      with_file_exist_stub(true) do
        result = connection.upload(['/tmp/local-one', '/tmp/local-two'], '/tmp/remote')
      end
    end

    assert_equal :fallback_upload, result
    assert_equal true, connection.instance_variable_get(:@rsync_failed)
    assert_equal [[['/tmp/local-one', '/tmp/local-two'], '/tmp/remote']], fallback_calls
    assert_includes logger.debug_messages, '[rsync] Using fallback to upload /tmp/local-one;/tmp/local-two'
  ensure
    without_redefinition_warnings do
      ssh_connection.define_method(:upload, original_upload) if original_upload
    end
  end

  private

  def assert_silent_name_error
    yield
  rescue NameError => e
    flunk("Expected no NameError, got #{e.class}: #{e.message}")
  end

  def with_file_exist_stub(value)
    file = File.singleton_class
    original_exist = file.instance_method(:exist?)
    without_redefinition_warnings do
      file.define_method(:exist?) { |_path| value }
    end
    yield
  ensure
    without_redefinition_warnings do
      file.define_method(:exist?, original_exist)
    end
  end

  def without_redefinition_warnings
    previous_verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = previous_verbose
  end
end
