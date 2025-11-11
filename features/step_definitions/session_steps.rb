Given("I am logged in") do
  @user = create(:user)
  @user.save!
  login_as @user
end

Given("I am logged in as an E2E user") do
  email = "e2euser@example.com"
  ENV["E2E_USER_EMAILS"] = email
  e2e_user = create(:user, email:)
  e2e_user.save!
  login_as e2e_user
end

Given(/^I have the "(.*?)" permission$/) do |perm|
  @user.permissions << perm
  @user.save!
end

Given("I have the PRE_RELEASE_FEATURES authorisation") do
  @user.permissions << User::Permissions::PRE_RELEASE_FEATURES_PERMISSION
  @user.save!
end

Around("@use_real_sso") do |_scenario, block|
  current_sso_env = ENV["GDS_SSO_MOCK_INVALID"]
  ENV["GDS_SSO_MOCK_INVALID"] = "1"
  block.call
  ENV["GDS_SSO_MOCK_INVALID"] = current_sso_env
end
