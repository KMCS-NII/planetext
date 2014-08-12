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
    using HashRefinement

    def extract(doc, conf={})
      conf = {
        remove_whitespace: false,
        replace_newlines: ' ',
        use_xpath: true,
        opaque_unknowns: true,
        newline: [],
        mark_displacement: true
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

    # XXX this might function better as a class
    def find_unknowns(dataset_dir, progress_file, limit=1)
      progress_data = get_progress_data(progress_file)

      processed_files = []
      unknown_standoffs = []
      processed_files = progress_data[:processed_files]
      all_files = Dir.chdir(dataset_dir) { |dir|
        Dir['**/*.{xml,xhtml,html}']
      }
      unprocessed_files = all_files - processed_files
      unprocessed_files = unprocessed_files.take(limit) if limit > 0
      selectors = {
        displaced: to_xpath(progress_data[:tags][:independent]),
        ignored: to_xpath(progress_data[:tags][:decoration]),
        replaced: to_xpath(progress_data[:tags][:object]),
        removed: to_xpath(progress_data[:tags][:metainfo])
      }
      unprocessed_files.each do |xml_file_name|
        xml_file = File.absolute_path(xml_file_name, dataset_dir)
        xml = File.read(xml_file)
        as_html = xml_file_name[-5..-1] == '.html'
        opts = {
          file_name: xml_file_name,
          as_html: as_html
        }.merge(selectors)
        doc = extract(xml, opts)
        unknown_standoffs += doc.unknown_standoffs
        processed_files << xml_file_name if doc.unknown_standoffs.empty?
      end
      progress_data[:processed_files] = processed_files
      save_progress_file(progress_file, progress_data)

      selectors = progress_data[:tags].hmap { |type, selector_list|
        selector_texts = selector_list.map { |selector_array|
          to_selector(*selector_array)
        }
        [type, selector_texts]
      }

      [selectors, unknown_standoffs, processed_files.length, all_files.length]
    end

  end
end
