# Build Caching form scratch with Ruby

According to a lot of developer, Caching is one of the hardest topic in web developement. The main reason is invalidating cache and always keep the data you serve fresh. You can imagine how difficult it can be in a distributed architecture. We are not going to cover the complexicity of distributed caching but rather a centrenlized caching in memory. We could use some in-memory data structure store, but for the sake of this exercice we will build every component ourself and make it as simple as possible.

### Without Cache

Let's build a light weight web application using Sinatra. We are starting with an app without Cache to point out the performance gain when making calls to the Database. Let's assume that our Database lives in a far away server and the query we are executing on it are time and CPU expensive.

A fake database adapter would look like this:
```ruby
class FakeDatabase
  def self.connection query
    puts "executing : #{query}"
    return {count: 33}
  end
end
```

Obviously it is not doing any query execution. Worse, it is always returning 33. Notice that I am printing out what query is executed to see it in the logs.
let's build the Sinatra app that would use this Database Adapter to execute a VERY expensive query.

```ruby
require 'sinatra'

class Main < Sinatra::Base  
  get '/' do  
    # make call to the database
    result = FakeDatabase.connection "select count(*) from users"
    "Hello World! #{result[:count]}"
  end
end
```

### Let's add some Cache

As we can see in the previous code snipet, the VERY expensive query is what should be cached and executed as seldom as possible. The code would look like this:

```ruby
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
```

The logic of the Cache is pretty straight forward and would be like the following, if the passed block has never been executed, execute it, store it as a key/value with the passed key and return the result. Otherwise, fetch the result using the passed key.  
We will use a Hash to mimic a Key/Value database, we can even mimic the name :).

```ruby
class Cache
  @redis = {}
  def self.fetch key, &block
    if @redis.key?(key)
      # fetch and return result
      puts "fetch from cache"
      @redis[key]
    else
      if block_given?
        # make the DB query and create a new entry for the request result
        puts "did not find key in cache, executing block ..."
        @redis[key] = yield(block)
      else
        # no block given, do nothing
        nil
      end
    end
  end
end
```
let see what happen when we load the homepage in the browser a couple of times

```
$ rackup
[2017-03-31 23:24:49] INFO  WEBrick 1.3.1
[2017-03-31 23:24:49] INFO  ruby 2.3.0 (2015-12-25) [x86_64-darwin15]
[2017-03-31 23:24:49] INFO  WEBrick::HTTPServer#start: pid=51672 port=9292
did not find key in cache, executing block ...
executing : select count(*) from users
::1 - - [31/Mar/2017:23:25:01 -0400] "GET / HTTP/1.1" 200 15 0.0385
fetch from cache
::1 - - [31/Mar/2017:23:25:04 -0400] "GET / HTTP/1.1" 200 15 0.0012
fetch from cache
::1 - - [31/Mar/2017:23:25:17 -0400] "GET / HTTP/1.1" 200 15 0.0009
```

Perfect, We can notice that the first GET request is making a Database call and all the follwing call are fetching that result from the cache.

###Cache With an expiration date
You might foresee the issue with our current implementation. If we get more users, the results will still be the same since it is feched from the cache. We need to find a way to invalidate the cache in order to refresh the query's result. We can do that by adding an expiration date to our key/value (In our case if we assume that we are not dealing with realtime requirements and it is fine if the user is not getting the updated data by the minute). So, the strategy here is to invalidate the cache if the current time is greater than the expiration date and replace the key/value by executing the block of code again.

```ruby
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
```

let's see what the logs say:

```
{}
did not find key in cache, executing block ...
executing : select count(*) from users
::1 - - [31/Mar/2017:23:34:34 -0400] "GET / HTTP/1.1" 200 15 0.0102

{"number_of_users"=>{:value=>{:count=>33}, :expiration_time=>1491017684}}
fetch from cache and will expire in 8
::1 - - [31/Mar/2017:23:34:36 -0400] "GET / HTTP/1.1" 200 15 0.0008

{"number_of_users"=>{:value=>{:count=>33}, :expiration_time=>1491017684}}
fetch from cache and will expire in 6
::1 - - [31/Mar/2017:23:34:38 -0400] "GET / HTTP/1.1" 200 15 0.0007

{"number_of_users"=>{:value=>{:count=>33}, :expiration_time=>1491017684}}
fetch from cache and will expire in 5
::1 - - [31/Mar/2017:23:34:39 -0400] "GET / HTTP/1.1" 200 15 0.0008

{"number_of_users"=>{:value=>{:count=>33}, :expiration_time=>1491017684}}
did not find key in cache, executing block ...
executing : select count(*) from users
::1 - - [31/Mar/2017:23:34:48 -0400] "GET / HTTP/1.1" 200 15 0.0008
```

The first request is a miss. the follwing requests are a hit but with an expiration time this time. After 10 seconds, it is a miss again and the Cache is refreshed.


##Conclusion
...
