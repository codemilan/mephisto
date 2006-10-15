require 'tzinfo'
require 'zip/zipfilesystem'
require 'dispatcher'
require 'coderay'
require 'ruby_pants'
require 'xmlrpc_patch'

RAILS_PATH = Pathname.new(File.expand_path(RAILS_ROOT))

ActiveRecord::Base.observers = [:article_observer, :comment_observer]

Inflector.inflections do |inflect|
  #inflect.plural /^(ox)$/i, '\1en'
  #inflect.singular /^(ox)en/i, '\1'
  #inflect.irregular 'person', 'people'
  inflect.uncountable %w( audio )
end

class << Dispatcher
  def register_liquid_tags
    [CoreFilters, DropFilters, UrlFilters].each { |f| Liquid::Template.register_filter f }
    Liquid::Template.register_tag(:textile,     Mephisto::Liquid::Textile)
    Liquid::Template.register_tag(:commentform, Mephisto::Liquid::CommentForm)
    Liquid::Template.register_tag(:head,        Mephisto::Liquid::Head)
  end
  
  def reset_application_with_plugins!
    returning reset_application_without_plugins! do
      register_liquid_tags
    end
  end
  
  alias_method_chain :reset_application!, :plugins
end

Dispatcher.register_liquid_tags
# http://rails.techno-weenie.net/tip/2005/12/23/make_fixtures
ActiveRecord::Base.class_eval do
  # person.dom_id #-> "person-5"
  # new_person.dom_id #-> "person-new"
  # new_person.dom_id(:bare) #-> "new"
  # person.dom_id(:person_name) #-> "person-name-5"
  def dom_id(prefix=nil)
    display_id = new_record? ? "new" : id
    prefix ||= self.class.name.underscore
    prefix != :bare ? "#{prefix.to_s.dasherize}-#{display_id}" : display_id
  end

  # Write a fixture file for testing
  def self.to_fixture(fixture_path = nil)
    File.open(File.expand_path(fixture_path || "test/fixtures/#{table_name}.yml", RAILS_ROOT), 'w') do |out|
      YAML.dump find(:all).inject({}) { |hsh, record| hsh.merge(record.id => record.attributes) }, out
    end
  end

  def referenced_cache_key
    "[#{[id, self.class.name] * ':'}]"
  end
end

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.update \
  :standard  => '%B %d, %Y @ %I:%M %p',
  :stub      => '%B %d', # XXX what is the meaning of stub in this context?  (Basically it means short)
  :time_only => '%I:%M %p',
  :plain     => '%B %d %I:%M %p',
  :mdy       => '%B %d, %Y',
  :my        => '%B %Y'

# Time.now.to_ordinalized_s :long
# => "February 28th, 2006 21:10"
module ActiveSupport::CoreExtensions::Time::Conversions
  def to_ordinalized_s(format = :default)
    format = ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS[format] 
    return to_default_s if format.nil?
    strftime(format.gsub(/%d/, '_%d_')).gsub(/_(\d+)_/) { |s| s.to_i.ordinalize }
  end
end

class Time
  class << self
    # Used for getting multifield attributes like those generated by a 
    # select_datetime into a new Time object. For example if you have 
    # following <tt>params={:meetup=>{:"time(1i)=>..."}}</tt> just do 
    # following:
    #
    # <tt>Time.parse_from_attributes(params[:meetup], :time)</tt>
    def parse_from_attributes(attrs, field, method=:gm)
      attrs = attrs.keys.sort.grep(/^#{field.to_s}\(.+\)$/).map { |k| attrs[k] }
      attrs.any? ? Time.send(method, *attrs) : nil
    end
  end

  def to_delta(delta_type = :day)
    case delta_type
      when :year then self.class.delta(year)
      when :month then self.class.delta(year, month)
      else self.class.delta(year, month, day)
    end
  end
      
  def self.delta(year, month = nil, day = nil)
    from = Time.local(year, month || 1, day || 1)
    
    to = 
      if !day.blank?
        from.advance :days => 1
      elsif !month.blank?
        from.advance :months => 1
      else
        from.advance :years => 1
      end
    return [from.midnight, to.midnight-1]
  end
end

# need to make pathname safe for windows!
Pathname.class_eval do
  def read(*args)
    returning '' do |s|
      File.open @path, 'rb' do |f|
        s << f.read
      end
    end
  end
end

class MissingTemplateError < StandardError
  attr_reader :template_type, :templates
  def initialize(template_type, templates)
    @template_type = template_type
    @templates     = templates
    super "No template found for #{template_type}, checked #{templates.to_sentence}."
  end
end

class ThemeError < StandardError
  attr_reader :theme
  def initialize(theme, message)
    @theme = theme
    super message
  end
end