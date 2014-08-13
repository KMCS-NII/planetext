#!/usr/bin/env ruby

require 'bundler/setup'
require_relative '../lib/planetext'
require 'slim'
require 'sass'
require 'coffee-script'
require 'fileutils'
require 'set'

module PlaneText



  class App < Sinatra::Application
    include PlaneText::Common

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
      # import dataset -> AJAX PUT dataset/:name, client redirect TODO
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

    get '/dataset/:dataset' do |dataset|
      dataset_dir = get_dataset_dir(dataset)
      progress_file = get_progress_file(dataset, session[:session_id])
      doc_limit = session[:doc_limit] || 5

      selectors, unknown_standoffs, processed_files, all_files =
        *find_unknowns(dataset_dir, progress_file, doc_limit)

      if processed_files == all_files
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
            autosubmit: autosubmit,
            doc_limit: doc_limit,
            progress: {
              done: processed_files,
              total: all_files
            }
          }
        }
      end
    end

    CONTENT_TYPES = {
      'html' => 'text/html',
      'xhtml' => 'application/xhtml+xml',
      'xml' => 'text/xml'
    }

    get '/dataset/:dataset/file/:file' do |dataset, filename|
      dataset_dir = get_dataset_dir(dataset)
      file = File.join(dataset_dir, filename)
      ensure_sandboxed(file, dataset_dir)
      begin
        content = File.read(file)
        if file =~ /\.(xml|x?html)/
          extension = $1
          progress_file = get_progress_file(dataset, session[:session_id])
          progress_data = get_progress_data(progress_file)
          as_html = extension == 'html'
          opts = {
            displaced: to_xpath(progress_data[:tags][:independent]),
            ignored: to_xpath(progress_data[:tags][:decoration]),
            replaced: to_xpath(progress_data[:tags][:object]),
            removed: to_xpath(progress_data[:tags][:metainfo]),
            file_name: filename,
            as_html: as_html
          }
          doc = extract(content, opts)
          puts doc.enriched_xml.class
          content_type CONTENT_TYPES[extension]
          doc.enriched_xml
        else
          content
        end
      rescue Errno::ENOENT
        halt 404, 'Not found'
      end
    end

    get '/dataset/:dataset/progress' do |dataset|
      get_dataset_dir(dataset) # for ensure_sandboxed
      progress_file = get_progress_file(dataset, session[:session_id])
      content_type 'application/x-yaml'
      attachment dataset + ".yaml"
      File.read(progress_file)
    end

    COLUMNS = [:independent, :decoration, :object, :metainfo]
    post '/dataset/:dataset/step' do |dataset|
      get_dataset_dir(dataset) # for ensure_sandboxed
      progress_file = get_progress_file(dataset, session[:session_id])
      progress_data = get_progress_data(progress_file)
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
      session[:autosubmit] = params[:autosubmit] == "true" if params[:autosumbit]
      session[:doc_limit] = params[:doc_limit].to_i if params[:doc_limit]
      ""
    end
  end
end
