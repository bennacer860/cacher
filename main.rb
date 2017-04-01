require 'sinatra'

class Main < Sinatra::Base
  get '/' do
    # make call to the database
    result = number_of_users
    "Hello World! #{result[:count]}"
  end

  def number_of_users
    Cache.fetch "number_of_users" do
      FakeDatabase.connection "select count(*) from users"
    end
  end
end

class FakeDatabase
  def self.connection query
    puts "executing : #{query}"
    return {count: 33}
  end
end


