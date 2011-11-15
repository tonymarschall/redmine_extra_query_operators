require 'redmine'
require 'dispatcher'
require 'extra_query_operators_patch'

unless Redmine::Plugin.registered_plugins.keys.include?(:redmine_extra_query_operators)
	Redmine::Plugin.register :redmine_extra_query_operators do
	  name 'Extra query operators plugin'
	  author 'Vitaly Klimov'
	  author_url 'mailto:vvk@snowball.ru'
	  description 'Extra query operators plugin for Redmine'
	  version '0.0.4'
	end
end

Dispatcher.to_prepare :redmine_extra_query_operators do
  require_dependency 'query'

  unless Query.included_modules.include? ExtraQueryOperators::Patches::QueryModelPatch
    Query.send(:include, ExtraQueryOperators::Patches::QueryModelPatch)
  end
end
