bq-kitchen-sync
============

This is a fork of the original Kitchen Sync gem, upgraded for Ruby 3.2+

Does transferring files in test-kitchen take too long?
```
       Transferring files to <chef18-ubuntu>
```

Do I ever have the gem for you!

bq-kitchen-sync implements alternate `rsync` and `sftp` transports for test-kitchen, speeding up file transfers significantly. Wait seconds, not minutes.

Quick Start
-----------

Run this to add the gem to your chef's ruby:

```shell
chef gem install bq-kitchen-sync --source "https://github.com/BuyerQuest/kitchen-sync.git"
```

If you're using test-kitchen through bundler instead, add this to your Gemfile:
```
gem 'bq-kitchen-sync', github: 'BuyerQuest/bq-kitchen-sync'
```

and then set the transport to `rsync` in your kitchen.yml file.


Available Transfer Methods
--------------------------

### `rsync`

```
transport:
  name: rsync
```

This is the fastest mode.

* You must be using `ssh-agent` with an identity loaded.
* `rsync` must be available on the remote side.
* * Use a test-kitchen [lifecycle hook](https://kitchen.ci/docs/reference/lifecycle-hooks/) to install it.

### `sftp`

```
transport:
  name: sftp
```

The default mode uses SFTP for file transfers, as well as a helper script to
avoid recopying files that are already present on the test host. If SFTP is
disabled, this will automatically fall back to the SCP mode.

By default this will use the Chef omnibus Ruby, you can customize the path to
Ruby via `ruby_path`:

```
transport:
  name: sftp
  ruby_path: /usr/bin/ruby
```

License
-------

Copyright 2014-2016, Noah Kantrowitz
Copyright 2025, Andrew Bobulsky

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
