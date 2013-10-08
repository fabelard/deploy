set  :application,            "mnesys_portail"
set  :domain,                 "pv2-01.naoned-systemes.fr"
set  :deploy_to,              "/home/inao/mnesys_portail"

set :mailgun_api_key, 'key-79c42qx4eqypyx-jjxr6s0kkwgqhe9x4' # your mailgun API key
set :mailgun_domain, 'naonedsystemes.mailgun.org' # your mailgun email domain
set :mailgun_from, 'deploymement_prod@mnesys.fr' # who the email will appear to come from
set :mailgun_recipients, [ 'tous@naoned-systemes.fr' ] # who will receive the email

set  :scm,                    :git
#set  :git_enable_submodules,  1
set  :repository,             "git@github.com:naonedsystemes/mnesys_portail.git"
set :branch, "stable"
#set  :deploy_via,             :remote_cache
set :deploy_via, :rsync_with_remote_cache

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
    [internal] Overriding original task to fit to symfony project needs
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
    Overriding original task to use symfony migrations
  DESC
  task :migrations do
    update
    #sf.migrate
  end  
  
  after "deploy:update", 'deploy:customize'
  after :deploy, 'mailgun_notify'
  
  desc <<-DESC
    Custom tasks
  DESC
  task :customize do
    ca.symlinks
    ca.cc
    ca.rights
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
    Run the "cake rights" task
  DESC
  task :rights do
    run "cd #{current_path} && chmod 775 -R *;"
    run "cd #{current_path} && chown www-data:www-data -R *;"
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
    run "ln -s /bigfs/uploads #{current_path}/app/webroot/uploads"
    
    # symlink to medias
    run "rm -rf #{current_path}/app/webroot/medias"
    run "ln -s /bigfs/medias #{current_path}/app/webroot/medias"

    # symlink to copy_instance
    run "rm -rf #{current_path}/tools/copy_instance.sh"
    run "ln -s #{shared_path}/tools/copy_instance.sh #{current_path}/tools/copy_instance.sh"
     
  end

end
