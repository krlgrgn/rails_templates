# Create RVM files
run "echo #{@app_name} > .ruby-gemset"
run "echo `rvm current` > .ruby-version"
run "rvm gemset create #{@app_name}"
run "rvm gemset use #{@app_name}"

# Application Setup
# ==================================
# Application generators configuration
inject_into_file "config/application.rb", :before => "  end" do <<-'RUBY'
    # Generator configuration
    config.generators do |g|
      g.test_framework :rspec,
        fixture: false,
        view_specs: false,
        helper_specs: false,
        routing_specs: false,
        controller_specs: true,
        request_specs: false
      g.fixture_replacement :factory_girl, dir: "spec/factories"
    end
RUBY
end


#
# gitignore
# ===================================
run "cat << EOF >> .gitignore
/.bundle
/db/*.sqlite3
/db/*.sqlite3-journal
/log/*.log
/tmp
database.yml
doc/
*.swp
*.swo
*~
.project
.idea
.secret
.DS_Store
EOF"

git :init


#
# Gems
# ===================================
# Authentication
gem 'devise'

# Authorization
gem 'declarative_authorization'

gem_group :development, :test do
  gem 'rspec-rails' # Testing framework for rails.
  gem 'factory_girl_rails' # Replaces fixtures for feeding test data via factories.
end

gem_group :test do
  gem 'faker' # Generates fake test data.
  gem 'capybara'
end

# Use unicorn as the app server
gem 'unicorn'

# Postgres
#gem 'pg'

# Styling
gem 'foundation-rails'

# Install the gems
run 'bundle install'

#
# Rspec Setup
# ===================================
generate "rspec:install"

run "echo \"--format documentation\" >> .rspec"

#
# Foundation Setup
# ===================================
remove_file 'app/views/layouts/application.html.erb'
generate "foundation:install"

#
# Base User Setup
# ===================================
generate "scaffold User email:string first_name:string last_name:string password_digest:string session_token:string"

inject_into_file "app/models/user.rb", :before => "end" do <<-'RUBY'
  EMAIL_REGEXP = /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/


  # Validations
  validates :email,      presence: true, uniqueness: true,
                         format: {
                            with: EMAIL_REGEXP,
                            message: "Invalid email address."
                         }
  validates :first_name,            presence: true
  validates :last_name,             presence: true
  validates :password,              presence: true,  length: { minimum: 6 }
  validates :password_confirmation, presence: true

  # Filters
  before_save { |user| user.email = email.downcase }

  # Relations
  has_many :user_roles
  has_many :roles, :through => :user_roles

  # Methods
  has_secure_password

  def role_symbols
    self.roles.map do |role|
      role.name.underscore.to_sym
    end
  end
RUBY
end

#
# Authentication Setup
# ===================================


#
# Authorization Setup
# ===================================
create_file "config/authoriazation_rules.rb" do
  "#
# Here we define the roles that each user could have.
# A user could have many roles, and each role could have many users.
# We have a many to many relationship between users and roles.
#
authorization do
  #role :guest do
  #end
  #role :admin do
  #  has_permission_on [:adventures], :to => [:index, :show, :new, :create, :edit, :update, :destroy]
  #end
  #role :adventurer do
  #  has_permission_on [:adventures], :to => [:index, :show, :new, :create]
  #  has_permission_on [:adventures], :to => [:edit, :update, :destroy] do
  #    if_attribute :user => is { user }
  #  end
  #end
end"
end

create_file "app/models/user_role_maps.rb" do <<-'RUBY'
class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
end
RUBY
end

create_file "app/models/role.rb" do <<-'RUBY'
class Role < ActiveRecord::Base
end
RUBY
end

generate "migration CreateRoles name:string"
generate "migration CreateJoinTableUserRole user role"

inject_into_file "app/controllers/application_controller.rb", :before => "end" do <<-'RUBY'

  #
  # Letting declarative authorization know who the current user is.
  #
  before_filter { |c| Authorization.current_user = c.current_user }


  def permission_denied
    redirect_to root_url
  end
RUBY
end

run "rake db:create"
run "rake db:migrate"
run "rake db:test:prepare"

say <<-eos
============================================================================
Your new Rails application is ready to go.
Don't forget to scroll up for important messages from installed generators.

No model spec has been written for the User model.
eos
