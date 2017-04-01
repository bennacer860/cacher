require 'sinatra'

class Main < Sinatra::Base
  get '/' do
    # make call to the database
    result = number_of_users
    "Hello World! #{result[:count]}"
  end

  def number_of_users
    Cache.fetch "number_of_users", 10 do
      FakeDatabaseAdapter.connection "select count(*) from users"
    end
  end
end

class Cache
  @redis = {}
  def self.fetch key, expires_in = 30, &block
    puts ""
    puts @redis
    if @redis.key?(key) && (@redis[key][:expiration_time] > Time.now.to_i)
      # fetch and return result
      puts "fetch from cache and will expire in #{@redis[key][:expiration_time] - Time.now.to_i}"
      @redis[key][:value]
    else
      if block_given?
        # make the DB query and create a new entry for the request result
        puts "did not find key in cache, executing block ..."
        @redis[key] = {value: yield(block), expiration_time: Time.now.to_i + expires_in}
        @redis[key][:value]
      else
        # no block given, do nothing
        nil
      end
    end
  end
end

class FakeDatabaseAdapter
  def self.connection query
    puts "executing : #{query}"
    return {count: 33}
  end
end


