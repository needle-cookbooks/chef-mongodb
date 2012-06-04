include_recipe 'python'
include_recipe 'runit'

%w{ simplejson hmac hashlib pymongo }.each do |egg|
  python_pip egg
end

directory node[:mongodb][:agent_install_path] do
  recursive true
end

bash "extract mms-agent" do
  code <<-EOH
  EOH
  action :nothing
end

remote_file "/tmp/10gen-mms-agent.tar.gz" do
  source "https://mms.10gen.com/settings/10gen-mms-agent.tar.gz"
  not_if { ::File.exists?(::File.join(node[:mongodb][:agent_install_path],'agent.py')) }
  notifies :run, "bash[extract mms-agent]", :immediately
end

template ::File.join(node[:mongodb][:agent_install_path],'settings.py') do
  source 'mms-agent-settings.py.erb'
  variables( :api_key => node[:mongodb][:agent_api_key],
             :secret_key => node[:mongodb][:agent_secret_key] )
end

runit_service "mms-agent"
