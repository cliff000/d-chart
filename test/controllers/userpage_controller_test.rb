require 'test_helper'

class UserpageControllerTest < ActionDispatch::IntegrationTest
  test "should get login" do
    get userpage_login_url
    assert_response :success
  end

  test "should get form" do
    get userpage_form_url
    assert_response :success
  end

  test "should get myanalysis" do
    get userpage_myanalysis_url
    assert_response :success
  end

  test "should get totalanalysis" do
    get userpage_totalanalysis_url
    assert_response :success
  end

end
