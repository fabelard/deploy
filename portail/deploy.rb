set  :application,            "mnesys_portail"
set  :domain,                 "localhost"
set  :deploy_to,              "/home/www/inao/mnesys_portail"

set  :scm,                    :git
set  :repository,             "git@github.com:naonedsystemes/mnesys_portail.git"
set  :branch, "stable"
#set  :deploy_via,             :remote_cache
set :deploy_via, 			        :rsync_with_remote_cache

role :web,                    domain
role :app,                    domain
role :db,                     domain, :primary => true

set  :user,                   "root"
set  :use_sudo,               false
set  :keep_releases,          3
ssh_options[:forward_agent] = true

set :php, "/usr/bin/php"
set :cake_app, "app"

namespace (:deploy) do

  desc <<-DESC
    [internal] Overriding original task to fit to cakephp project needs
  DESC
  task :finalize_update, :except => { :no_release => true } do
    # Fix permissions
    run "cd #{latest_release} && chmod 775 -R *;"
    run "cd #{latest_release} && chown www-data:www-data -R *;"
  end

  desc <<-DESC
    Overriding original task to exclude restart
  DESC
  task :default do
    update
  end

  desc <<-DESC
    Overriding original task to use cakephp migrations
  DESC
  task :migrations do
    update
    #ca.migrate
  end
  
  after "deploy:update", "deploy:customize", "deploy:cleanup"
  
  desc <<-DESC
    Custom tasks
  DESC
  task :customize do
    ca.symlinks
    ca.cc
    ca.rights
    ca.migrations
    ca.acl
    system 'cap apache:reload'
  end
 
end

namespace :apache do
  [:stop, :start, :restart, :reload].each do |action|
    desc "#{action.to_s.capitalize} Apache"
    task action, :roles => :web do
    	invoke_command "/etc/init.d/apache2 #{action.to_s}", :via => run_method
    end
  end
end

namespace (:ca) do

  desc <<-DESC
    Run the "cake cc" task
  DESC
  task :cc do
    run "cd #{current_path} && rm -rf app/tmp/cache/models/*"
    run "cd #{current_path} && rm -rf app/tmp/cache/persistent/*"
  end

 desc <<-DESC
    Run the "cake ACL" task
  DESC
  task :acl do
    run "cd #{current_path}/#{cake_app} && ./Console/cake AclExtras.AclExtras aco_sync;"
  end

 desc <<-DESC
    Run the "cake rights" task
  DESC
  task :rights do
    run "cd #{current_path} && chmod 775 -R *;"
    run "cd #{current_path} && chown www-data:www-data -R *;"
  end

 desc <<-DESC
    Run the "cake Migrations" task
  DESC
  task :migrations do
    run "cd #{current_path}/#{cake_app} && ./Console/cake Migrations.migration run all;"
  end

  desc <<-DESC
    Create symlink to cakephp specific targets
  DESC
  task :symlinks do
    # symlink to database.php
    run "rm -rf #{current_path}/app/Config/database.php"
    run "ln -s #{shared_path}/database.php #{current_path}/app/Config/database.php"
   
    # symlink to core.php
    run "rm -rf #{current_path}/app/Config/core.php"
    run "ln -s #{shared_path}/core.php #{current_path}/app/Config/core.php"

    # symlink to uploads
    run "rm -rf #{current_path}/app/webroot/uploads"
    run "ln -s /home/www/inao/uploads #{current_path}/app/webroot/uploads"
    #run "ln -s {inao_datas_mnesys_portail}/uploads #{current_path}/app/webroot/uploads"
    
    # symlink to medias
    run "rm -rf #{current_path}/app/webroot/medias"
    run "ln -s /home/www/inao/medias #{current_path}/app/webroot/medias"
    #run "ln -s {inao_datas_mnesys_portail}/medias #{current_path}/app/webroot/medias"
    
    ## symlink to node server
    #run "rm -f /home/www/inao/server/server.js"
    #run "ln -s #{current_path}/tools/script_server/server.js /home/www/inao/server/server.js"

    # symlink to copy_instance
    #run "rm -rf #{current_path}/tools/copy_instance.sh"
    #run "ln -s #{shared_path}/tools/copy_instance.sh #{current_path}/tools/copy_instance.sh"
     
  end

end
