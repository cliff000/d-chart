require 'test_helper'

class MachesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get maches_index_url
    assert_response :success
  end

  test "should get form" do
    get maches_form_url
    assert_response :success
  end

  test "should get sended_form" do
    get maches_sended_form_url
    assert_response :success
  end

  test "should get me" do
    get maches_me_url
    assert_response :success
  end

  test "should get total" do
    get maches_total_url
    assert_response :success
  end

end
