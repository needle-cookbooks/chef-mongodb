include_recipe 'python'
include_recipe 'runit'

data_bag_key = Chef::EncryptedDataBagItem.load_secret(node['data_bag_key'])
secrets = Chef::EncryptedDataBagItem.load("secrets", node.chef_environment, data_bag_key)

%w{ hmac simplejson hashlib pymongo }.each do |egg|
  python_pip egg
end

mms_dir = ::File.join(node[:mongodb][:agent_prefix],'mms-agent') 

directory mms_dir do
  recursive true
end

bash "extract mms-agent" do
  code <<-EOH
    cd #{node[:mongodb][:agent_prefix]}
    tar -zxvf /tmp/10gen-mms-agent.tar.gz
  EOH
  action :nothing
end

remote_file "/tmp/10gen-mms-agent.tar.gz" do
  source "https://mms.10gen.com/settings/10gen-mms-agent.tar.gz"
  not_if { ::File.exists?(::File.join(mms_dir,'agent.py')) }
  notifies :run, "bash[extract mms-agent]", :immediately
end

template ::File.join(mms_dir,'settings.py') do
  source 'mms-agent-settings.py.erb'
  variables( :api_key => secrets['mongodb']['agent_api_key'],
             :secret_key => secrets['mongodb']['agent_api_secret'] )
end

runit_service "mms-agent"
