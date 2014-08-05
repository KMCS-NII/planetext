#!/usr/bin/env ruby

require 'bundler/setup'
require_relative '../lib/planetext'
require 'slim'
require 'sass'
require 'coffee-script'
require 'fileutils'
require 'set'

module PlaneText
  module HashRefinement
    refine Hash do
      def hmap
        Hash[self.map {|k, v| yield k, v }]
      end
    end
  end


  class App < Sinatra::Application
    using HashRefinement

    set :haml, format: :html5
    set :method_override, true
    set :static, true
    set :public_folder, File.join(settings.root, 'app/public')
    puts settings.public_folder
    set :views, File.join(settings.root, 'app/views')
    enable :sessions
    set :session_secret, Config.webapp.session_secret

    configure :production do
      set :haml, ugly: true
      set :clean_trace, true
    end

    Config['datadir'] ||= File.join(settings.root, 'data')

    def ensure_sandboxed(subdir, dir)
      abs_subdir = File.expand_path(subdir)
      abs_dir = File.expand_path(dir)
      halt 403 unless abs_subdir[0, abs_dir.length] == abs_dir
    end

    get '/' do
      # choose dataset -> dataset/:name
      # import dataset -> AJAX PUT dataset/:name, client redirect
      # delete dataset -> AJAX DELETE datasets/:name
      datasets = Dir[File.join(Config.datadir, '*')].
        map { |file| File.basename(file) }
      slim :index, locals: {
        datasets: datasets
      }
    end

    delete '/dataset/:dataset' do |dataset|
      ensure_sandboxed(dataset, Config.datadir)
      FileUtils.rm_rf(dataset)
    end


    def get_dataset_dir(dataset)
      File.join(Config.datadir, dataset).tap do |dataset_dir|
        ensure_sandboxed(dataset_dir, Config.datadir)
        halt 404 unless File.directory?(dataset_dir)
      end
    end

    def get_progress_file(dataset, sid)
      sid = session[:session_id]
      session_root = File.absolute_path(Config.webapp.session_dir || 'sessions', settings.root)
      session_dir = File.join(session_root, sid)
      ensure_sandboxed(session_dir, session_root)
      FileUtils.mkdir_p(session_dir)
      File.join(session_dir, dataset)
    end

    def save_progress_file(progress_file, progress_data)
      File.write(progress_file, YAML.dump(progress_data))
    end

    def get_progress_data(progress_file, dataset_dir)
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

    class JSONableSortedSet < SortedSet
      def to_json(*args)
        to_a.to_json(*args)
      end
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

    def unknown_tree(unknown_standoffs)
      {}.tap { |unknowns|
        unknown_standoffs.each do |standoff|
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

    get '/dataset/:dataset' do |dataset|
      dataset_dir = get_dataset_dir(dataset)
      progress_file = get_progress_file(dataset, session[:session_id])
      progress_data = get_progress_data(progress_file, dataset_dir)

      processed_files = []
      unknown_standoffs = []
      processed_files = progress_data[:processed_files]
      all_files = Dir.chdir(dataset_dir) { |dir|
        Dir['**/*.{xml,xhtml,html}']
      }
      unprocessed_files = all_files - processed_files
      limit = Config.webapp.files_at_once || 1
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
        opts = { file_name: xml_file_name }.merge(selectors)
        doc = Extractor.extract(xml, opts)
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

      if processed_files.length == all_files.length
        slim :done, {
          locals: {
            selectors: selectors
          }
        }
      else
        autosubmit = session[:autosubmit]
        autosubmit = true if autosubmit.nil?
        slim :step, {
          locals: {
            unknowns: unknown_tree(unknown_standoffs),
            selectors: selectors,
            dataset_url: url("/dataset/#{dataset}"),
            app_url: url("/"),
            autosubmit: autosubmit
          }
        }
      end
    end

    COLUMNS = [:independent, :decoration, :object, :metainfo]
    post '/dataset/:dataset/step' do |dataset|
      dataset_dir = get_dataset_dir(dataset)
      progress_file = get_progress_file(dataset, session[:session_id])
      progress_data = get_progress_data(progress_file, dataset_dir)
      changes = JSON.parse(params[:changes])
      changes.each do |change|
        pos = change["pos"].to_i
        selector = change["selector"]
        column = change["column"]
        previous = change["previous"]
        md = /^([^\]\[]+)(?:\[([^:]*)(?::\s*([^\]]*))?\])?/.match(selector)
        halt 403, "Invalid selector #{selector}" unless md
        _, tag, attr, values = *md
        data = [tag, attr, *(values || "").split].compact

        if previous && !previous.empty?
          previous = previous.to_sym
          halt 403, "Invalid origin column #{previous}" unless COLUMNS.include?(previous)
          deleted = progress_data[:tags][previous].delete(data)
          progress_data[:processed_files] = [] if deleted
        end

        if column && !column.empty?
          column = column.to_sym
          halt 403, "Invalid target column #{column}" unless COLUMNS.include?(column)
          if pos == -1
            progress_data[:tags][column] << data
          else
            progress_data[:tags][column].insert(pos, data)
          end
        end
      end
      save_progress_file(progress_file, progress_data)
      ""
    end

    post '/config' do
      params.keep_if { |key, value| %w(autosubmit).include? key }
      session[:autosubmit] = params[:autosubmit] == "true"
      pp params
      pp session
      ""
    end
  end
end
