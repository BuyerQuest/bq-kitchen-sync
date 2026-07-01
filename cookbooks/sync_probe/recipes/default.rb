cookbook_file '/tmp/bq-kitchen-sync-payload.txt' do
  source 'payload.txt'
  owner 'root'
  group 'root'
  mode '0644'
end

file '/tmp/bq-kitchen-sync-marker.txt' do
  content "bq-kitchen-sync converged via #{node['platform']} #{node['platform_version']}\n"
  owner 'root'
  group 'root'
  mode '0644'
end
