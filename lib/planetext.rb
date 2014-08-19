require 'yaml'
require 'settingslogic'
require_relative 'extract'

module HashRefinement
  refine Hash do
    def hmap
      Hash[self.map {|k, v| yield k, v }]
    end
  end
end

module PlaneText

  class Config < Settingslogic
    source "config.yaml"
    suppress_errors true
    load!
  end

  module Common

    def extract(doc, conf={})
      conf = {
        remove_whitespace: false,
        replace_newlines: ' ',
        use_xpath: true,
        opaque_unknowns: true,
        newline: [],
        mark_displacement: false
      }.merge(conf)
      PaperVu::Extract::Document.new(doc, conf)
    end


    def save_progress_file(progress_file, progress_data)
      File.write(progress_file, YAML.dump(progress_data))
    end

    def get_progress_data(progress_file)
      # find the user data pertaining to current dataset
      if File.exist?(progress_file)
        YAML.load(File.read(progress_file))
      else
        {
          processed_files: [],
          tags: {
            independent: [],
            decoration: [],
            object: [],
            metainfo: []
          }
        }
      end
    end

    def to_xpath(selectors)
      selectors.map { |tag, attr, *values|
        xpath = "//#{tag}"
        if !values.empty?
          values.each do |value|
            xpath += "[contains(concat(' ', normalize-space(@#{attr}), ' '), ' #{value} ')]"
          end
        elsif attr
          xpath += "[@#{attr}]"
        end
        xpath
      }
    end

    def to_selector(tag, attr=nil, *values)
      if !values.empty?
        "#{tag}[#{attr}: #{values.join(' ')}]"
      elsif attr
        "#{tag}[#{attr}]"
      else
        "#{tag}"
      end
    end

  end

  class UnknownSearcher
    include Common
    using HashRefinement

    attr_reader :selectors, :unknown_standoffs, :done, :total
    def initialize(dataset_dir, progress_file, limit=1)
      progress_data = get_progress_data(progress_file)

      @unknown_standoffs = []
      all_files = Dir.chdir(dataset_dir) { |dir|
        Dir['**/*.{xml,xhtml,html}']
      }
      processed_files = progress_data[:processed_files] || all_files
      unprocessed_files = all_files - processed_files
      @selectors = {
        displaced: to_xpath(progress_data[:tags][:independent]),
        ignored: to_xpath(progress_data[:tags][:decoration]),
        replaced: to_xpath(progress_data[:tags][:object]),
        removed: to_xpath(progress_data[:tags][:metainfo])
      }
      dirty_files = 0
      unprocessed_files.each do |xml_file_name|
        xml_file = File.absolute_path(xml_file_name, dataset_dir)
        xml = File.read(xml_file)
        as_html = xml_file_name[-5..-1] == '.html'
        opts = {
          file_name: xml_file_name,
          as_html: as_html
        }.merge(@selectors)
        doc = extract(xml, opts)
        @unknown_standoffs += doc.unknown_standoffs
        if doc.unknown_standoffs.empty?
          processed_files << xml_file_name
        else
          dirty_files += 1
          break if dirty_files >= limit
        end
      end
      if processed_files.length == all_files.length
        progress_data.delete(:processed_files)
      else
        progress_data[:processed_files] = processed_files
      end
      save_progress_file(progress_file, progress_data)

      @selectors = progress_data[:tags].hmap { |type, selector_list|
        selector_texts = selector_list.map { |selector_array|
          to_selector(*selector_array)
        }
        [type, selector_texts]
      }

      @done = processed_files.length
      @total = all_files.length
    end

    def insert_standoff_data(unknowns, standoff, attr_name)
      attr = unknowns[standoff.name][attr_name] ||= [
        {}, # words
        [], # instances
        {} # distinct combos TODO
      ]
      instance_data = [
        standoff.start_offset, # start
        standoff.end_offset, # end
        standoff.file_name, # file name
        standoff.attributes[attr_name] # value
      ]
      index = attr[1].size
      attr[1] << instance_data
      [attr, index]
    end

    def tree
      {}.tap { |unknowns|
        @unknown_standoffs.each do |standoff|
          unknowns[standoff.name] ||= {}
          if standoff.attributes.empty?
            attr, index = *insert_standoff_data(unknowns, standoff, '')
          else
            standoff.attributes.each do |name, values|
              attr, index = *insert_standoff_data(unknowns, standoff, name)
              words = values.split(/\s+/)
              if words.empty?
                (attr[0][''] ||= []) << index
              else
                words.each do |word|
                  (attr[0][word] ||= []) << index
                end
              end
            end
          end
        end
      }
    end
  end

end
