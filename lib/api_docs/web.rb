require 'yaml'
require 'sinatra/base'
require "bundler/setup"

module ApiDocs
  class Web < Sinatra::Base
    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end

    dir = File.expand_path(File.dirname(__FILE__))

    set :public_folder, "#{dir}/assets"
    set :views,  "#{dir}/views"

    helpers do
      def controllers
        @controllers ||= begin
          Dir.glob(ApiDocs.config.docs_path.join('**/*.yml')).sort.inject({}) do |memo, file_path|
            obj = Content.new(file_path, memo.count)
            obj.order = -1 if obj.header_content.present?

            memo[File.basename(file_path, '.yml')] = obj
            memo
          end.sort_by {|k,v| v.order}
        end
      end

      def asset_path
        self.class.public_folder
      end

      def stylesheets
        @stylesheets ||= begin
          ["bootstrap.min.css", "main.css"].map{|file| File.read("#{asset_path}/#{file}")}.join("\n")
        end
      end

      def javascripts
        @javascripts ||= begin
          ["jquery.min.js", "bootstrap.min.js"].map{|file| File.read("#{asset_path}/#{file}")}.join("\n")
        end
      end

      def markdown_not_exist? controller_name
        !File.exist?(ApiDocs.config.docs_path.join("#{controller_name}.md"))
      end
    end

    get '/' do
      haml :index
    end

  end

  class Content < Struct.new(:file_path, :order)
    def content
      YAML.load_file(file_path)
    end

    def header_content
      File.exist?(markdown_path) ? File.read(markdown_path) : nil
    end

    private
    def markdown_path
      file_path.gsub(File.extname(file_path), ".md")
    end
  end
end
