#
# Copyright 2014-2016, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'base64'
require 'benchmark'
require 'shellwords'

require 'kitchen/transport/ssh'
require 'net/ssh'

require 'kitchen-sync/core_ext'

module Kitchen
  module Transport
    class Rsync < Ssh
      def finalize_config!(instance)
        super.tap do
          if defined?(Kitchen::Verifier::Inspec) && instance.verifier.is_a?(Kitchen::Verifier::Inspec)
            instance.verifier.send(:define_singleton_method, :runner_options_for_rsync) do |config_data|
              runner_options_for_ssh(config_data)
            end
          end
        end
      end

      # Copy-pasta from Ssh#create_new_connection because I need the Rsync
      # connection class.
      # Tracked in https://github.com/test-kitchen/test-kitchen/pull/726
      def create_new_connection(options, &block)
        if @connection
          logger.debug("[SSH] shutting previous connection #{@connection}")
          @connection.close
        end

        @connection_options = options
        @connection = self.class::Connection.new(options, &block)
      end

      class Connection < Ssh::Connection
        def upload(locals, remote)
          if @rsync_failed || !File.exist?('/usr/bin/rsync')
            logger.debug('[rsync] Rsync already failed or not installed, not trying it')
            return super
          end

          locals = Array(locals)
          ssh_command = rsync_ssh_command
          copy_identity
          rsync_cmd = [
            '/usr/bin/rsync',
            '-e',
            ssh_command,
            "-rltz#{logger.level == :debug ? 'vv' : ''}",
            *locals,
            "#{username}@#{hostname}:#{remote}",
          ]
          logger.debug("[rsync] Running rsync command: #{Shellwords.join(rsync_cmd)}")
          ret = []
          time = Benchmark.realtime do
            ret << system(*rsync_cmd)
          end
          logger.info("[rsync] Time taken to upload #{locals.join(';')} to #{self}:#{remote}: %.2f sec" % time)
          unless ret.first
            logger.warn("[rsync] rsync exited with status #{$?.exitstatus}, using SCP instead")
            @rsync_failed = true
          end

          # Fall back to SCP
          if @rsync_failed
            logger.debug("[rsync] Using fallback to upload #{locals.join(';')}")
            super(locals, remote)
          end
        end

        # Copy your SSH identity, creating a new one if needed
        def copy_identity
          return if @copied_identity
          identities = Net::SSH::Authentication::Agent.connect.identities
          raise 'No SSH identities found. Please run ssh-add.' if identities.empty?
          key = identities.first
          enc_key = Base64.encode64(key.to_blob).gsub("\n", '')
          identitiy = "ssh-rsa #{enc_key} #{key.comment}"
          @session.exec! <<-EOT
            test -e ~/.ssh || mkdir ~/.ssh
            test -e ~/.ssh/authorized_keys || touch ~/.ssh/authorized_keys
            if ! grep -q "#{identitiy}" ~/.ssh/authorized_keys ; then
              chmod go-w ~ ~/.ssh ~/.ssh/authorized_keys ; \
              echo "#{identitiy}" >> ~/.ssh/authorized_keys
            fi
          EOT
          @copied_identity = true
        end

        def rsync_ssh_command
          command = login_command
          args = command.arguments.dup
          args.pop

          [command.command, *args].map { |arg| shell_escape_ssh_arg(arg) }.join(' ')
        end

        def shell_escape_ssh_arg(arg)
          if arg.start_with?('ProxyCommand=')
            "ProxyCommand=#{shell_single_quote(arg.delete_prefix('ProxyCommand='))}"
          else
            Shellwords.escape(arg).gsub('\=', '=')
          end
        end

        def shell_single_quote(value)
          "'#{value.gsub("'", "'\"'\"'")}'"
        end
      end

    end
  end
end
