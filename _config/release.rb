#!/usr/bin/env ruby
# Usage: ruby release.rb version path/to/versions.xml path/to/CHANGELOG.md
# Example: ruby release.rb 1.2.0 ./build/Release/versions.xml ./CHANGELOG.md

require 'rubygems'
require 'redcarpet'
require 'nokogiri'

include Redcarpet

version               = ARGV[0]
versions_xml_fragment = ARGV[1]
changelog_md          = ARGV[2]

html_root = File.expand_path '../..', __FILE__


# Updates the hermes_download_url YML key to parameter url.
hermes_download_url = 'hermes_download_url:'
hermes_download_url_regex = /^#{Regexp.quote(hermes_download_url)}.*$/
version_url = "https://s3.amazonaws.com/alexcrichton-hermes/Hermes-#{version}.zip"
config_yml = File.join html_root, '_config.yml'
puts "Updating Hermes download URL in #{File.basename config_yml} to #{version_url}"

contents = File.read(config_yml)
contents = contents.gsub(hermes_download_url_regex, "#{hermes_download_url} #{version_url}")
File.open(config_yml, 'wb') { |f| f << contents }


# Take new_xml fragment and inject into versions.xml located in GH Pages root.
versions_xml = File.expand_path('../../versions.xml', __FILE__)
new_xml = File.read(versions_xml_fragment).gsub("\t", '  ')
puts "Injecting new xml fragment (#{versions_xml_fragment}) into #{versions_xml}"

contents = Nokogiri::XML File.read(versions_xml)
has_item = contents.css('item title').any? do |node|
  if node.content == "Version #{version}"
    node.parent.replace contents.fragment(new_xml)
  end
end

if !has_item
  contents.css('language').first.add_next_sibling contents.fragment(new_xml)
end

File.open(versions_xml, 'wb') { |f| f << contents.to_xhtml(:indent => 2) }


# Render CHANGELOG.md and install into GH Pages root.
changelog_html = File.join(html_root, '/changelog.html')
puts "Rendering changelog (#{changelog_md} -> #{changelog_html})"

File.open(changelog_html, 'wb') { |f|
  f << Markdown.new(Render::HTML).render(File.read(changelog_md))
}
