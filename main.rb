require 'sinatra'

class Main < Sinatra::Base  
  get '/' do  
    # make call to the database
    result = FakeDatabase.connection "select count(*) from users"
    "Hello World! #{result[:count]}"
  end
end

class FakeDatabase
  def self.connection query
    puts "executing : #{query}"
    return {count: 33}
  end
end


