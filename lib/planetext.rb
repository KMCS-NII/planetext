require 'yaml'
require 'settingslogic'
require_relative 'extract'

module PlaneText
  class Config < Settingslogic
    source "config.yaml"
    suppress_errors true
    load!
  end


  class Extractor
    def self.extract(doc, conf={})
      conf = {
        remove_whitespace: true,
        replace_newlines: ' ',
        use_xpath: true,
        opaque_unknowns: true,
        newline: [],
        mark_displacement: true
      }.merge(conf)
      PaperVu::Extract::Document.new(doc, conf)
    end
  end
end
