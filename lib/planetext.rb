require 'yaml'

$config = File.open('config.yaml') { |f| YAML::load(f) }
