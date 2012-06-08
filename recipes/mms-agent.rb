include_recipe 'python'
include_recipe 'runit'

data_bag_key = Chef::EncryptedDataBagItem.load_secret(node['data_bag_key'])
secrets = Chef::EncryptedDataBagItem.load("secrets", node.chef_environment, data_bag_key)

%w{ simplejson hmac hashlib pymongo }.each do |egg|
  python_pip egg
end

directory node[:mongodb][:agent_prefix] do
  recursive true
end

bash "extract mms-agent" do
  code <<-EOH
  cwd '/opt'
    tar -zxvf /tmp/10gen-mms-agent.tar.gz
  EOH
  action :nothing
end

remote_file "/tmp/10gen-mms-agent.tar.gz" do
  source "https://mms.10gen.com/settings/10gen-mms-agent.tar.gz"
  not_if { ::File.exists?(::File.join(node[:mongodb][:agent_prefix],'mms-agent','agent.py')) }
  notifies :run, "bash[extract mms-agent]", :immediately
end

template ::File.join(node[:mongodb][:agent_prefix],'mms-agent','settings.py') do
  source 'mms-agent-settings.py.erb'
  variables( :api_key => secrets['mongodb']['agent_api_key'],
             :secret_key => secrets['mongodb']['agent_secret_key'] )
end

runit_service "mms-agent"
