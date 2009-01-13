require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users

  def test_user_from_fixture
    user = users(:seb)
    assert_equal 'seb', user.name
    assert_equal Digest::SHA1.hexdigest('test'), user.hashed_password
  end

  def test_password_enc
    user = User.new
    assert !user.hashed_password
    user.name = 'test'
    user.password = 'x'
    assert user.hashed_password
    assert user.hashed_password != user.password
    hash = Digest::SHA1.hexdigest('x')
    assert_equal hash, user.hashed_password
  end

  def test_authenticate
    user = User.authenticate('seb','test')
    assert_equal 'seb', user.name
    user = User.authenticate('seb', 'invalid')
    assert_nil user
    user = User.authenticate('invalid', 'invalid')
    assert_nil user
  end

  def test_validate_new_user
    user = User.new
    assert !user.valid?
    assert user.errors.invalid?(:name)
    assert_equal 2, user.errors.length
  end

  def test_validate_old_user_wo_pw
    user = users(:seb)
    assert user.valid?
  end

  def test_validate_pw_confirm
    user = users(:seb)
    user.password = 'bla'
    user.password_confirmation = 'bla'
    assert user.valid?
    user.password_confirmation = 'xxx'
    assert !user.valid?
  end

  def test_admin_wrappers
    user = users(:dilbert)
    assert !user.admin
    user.admin = true
    assert user.reload.admin
    user.admin = false
    assert !user.reload.admin
    user.admin = 1
    assert user.reload.admin
    user.admin = 0
    assert !user.reload.admin
  end

end
