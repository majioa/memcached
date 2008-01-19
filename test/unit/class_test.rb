
require "#{File.dirname(__FILE__)}/../test_helper"

require 'ruby-debug' if ENV['DEBUG']

class GenericClass
end

class ClassTest < Test::Unit::TestCase

  def setup
    @cache = Memcached.new(
      ['127.0.0.1:43042', '127.0.0.1:43043'], 
      :namespace => 'test'
    )
    @value = OpenStruct.new(:a => 1, :b => 2, :c => GenericClass)
    @raw_value = Marshal.dump(@value)
  end

  def test_initialize
    cache = Memcached.new ['127.0.0.1:43042', '127.0.0.1:43043'], :namespace => 'test'
    assert_equal 'test', cache.namespace
    assert_equal 2, cache.servers.size
    assert_equal '127.0.0.1', cache.servers.first.hostname
    assert_equal '127.0.0.1', cache.servers.last.hostname
    assert_equal 43043, cache.servers.last.port
  end
  
  def test_invalid_server_strings
    assert_raise(ArgumentError) { Memcached.new "localhost:43042" }
    assert_raise(ArgumentError) { Memcached.new "127.0.0.1:memcached" }
    assert_raise(ArgumentError) { Memcached.new "127.0.0.1:43043:1" }
  end

  def test_initialize_without_hash
    cache = Memcached.new ['127.0.0.1:43042', '127.0.0.1:43043']
    assert_equal nil, cache.namespace
    assert_equal 2, cache.servers.size
  end

  def test_initialize_single_server
    cache = Memcached.new '127.0.0.1:43042'
    assert_equal nil, cache.namespace
    assert_equal 1, cache.servers.size
  end

  def test_initialize_bad_argument
    assert_raise(ArgumentError) { Memcached.new 1 }
  end

  def test_get_missing
    assert_raise(Memcached::Notfound) do
      result = @cache.get 'test_get_missing'
    end
  end

  def test_get
    @cache.set 'test_get', @value, 0
    result = @cache.get 'test_get'
    assert_equal @value, result
  end
  
  def test_truncation_issue_is_covered
    value = OpenStruct.new(:a => 1, :b => 2, :c => Object.new) # Marshals with a null \000
    @cache.set 'test_get', value, 0
    result = @cache.get 'test_get', true
    non_wrapped_result = Libmemcached.memcached_get(
      @cache.instance_variable_get("@struct"), 
      'test_get'
    ).first
    assert result.size > non_wrapped_result.size      
  end  

  def test_get_invalid_key
    assert_raise(Memcached::ClientError) { @cache.get('key' * 100) }
    assert_raise(Memcached::ClientError) { @cache.get "I'm so bad" }
  end
#
#  def test_get_no_connection
#    @cache.servers = 'localhost:1'
#    assert_raise Memcached::Error do
#      @cache.get 'key'
#    end
#  end
#
#  def test_get_multi
#    values = @cache.get_multi 'get-one', 'get-two'
#  end
#
#  def test_get_raw
#    value = @cache.get 'key', true
#    assert_equal '0123456789', value
#  end
#
#  def test_incr
#    value = @cache.incr 'incr'
#    assert_equal 5, value
#  end
#
#  def test_incr_not_found
#  end
#
#  def test_decr
#    value = @cache.decr 'decr'
#  end
#
#  def test_decr_not_found
#  end
#
  def test_set
    assert_equal true, @cache.set('test_set', @value)
  end
  
  def test_set_invalid_key
    assert_raise(Memcached::ClientError) do
      @cache.set "I'm so bad", @value
    end
  end
  
#
#  def test_set_expiry
#  end
#
#  def test_set_raw
#  end
#
#  def test_set_object_too_large
#  end
#
#  def test_add
#    @cache.add 'definitely-not-there-key', @value
#  end
#
#  def test_add_exists
#    @cache.add 'already-there-key', @value
#  end
#
#  def test_add_expiry
#    @cache.add 'key', @value, 5
#  end
#
#  def test_add_raw
#    @cache.add 'key', @value, 0, true
#  end
#
#  def test_delete
#    @cache.delete 'key'
#  end
#
#  def test_delete_with_expiry
#    @cache.delete 'key', 300
#  end
#
#  def test_stats
#  end
#
#  def test_thread_contention
#  end

end
