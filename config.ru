#require './hellomonkey'
#require './secondperson'
require './fullfeatured'

$stdout.sync = true

run Sinatra::Application
