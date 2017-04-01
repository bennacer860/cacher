require 'sinatra'

class Main < Sinatra::Base
  get '/' do
    # make call to the database
    result = number_of_users
    "Hello World! #{result[:count]}"
  end

  def number_of_users
    Cache.fetch "number_of_users" do
      FakeDatabaseAdapter.connection "select count(*) from users"
    end
  end
end

class Cache
  @memory = {}
  def self.fetch key, &block
    if @memory.key?(key)
      # fetch and return result
      puts "fetch from cache"
      @memory[key]
    else
      if block_given?
        # make the DB query and create a new entry for the request result
        puts "did not find key in cache, executing block ..."
        @memory[key] = yield(block)
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


