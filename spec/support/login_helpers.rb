module LoginHelpers
  include Warden::Test::Helpers

  def login_as(user)
    GDS::SSO.test_user = user
    Current.user = user
    super(user) # warden
  end

  def login_as_admin
    login_as(create(:user, name: "admin-name", email: "admin@example.com"))
  end
end

RSpec.configure do |config|
  config.include LoginHelpers, type: :request
  config.include LoginHelpers, type: :feature
  config.before(:each, type: :controller) do
    request.env["warden"] = double(authenticate!: false, authenticated?: false, user: nil)
  end
end
