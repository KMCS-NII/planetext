#!/usr/bin/env ruby

require_relative '../lib/planetext'

class PlaneText < Sinatra::Application
  set :haml, format: :html5
  enable :sessions
  set :session_secret, $config[:webapp][:session_secret]

  configure :production do
    set :haml, ugly: true
    set :clean_trace, true
  end


  get '/' do
    $config.inspect
  end
end
