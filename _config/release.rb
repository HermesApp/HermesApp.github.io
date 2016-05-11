#!/usr/bin/env ruby
# Usage: ruby release.rb version path/to/versions.xml path/to/CHANGELOG.md 10.10
# Example: ruby release.rb 1.2.0 ./build/Release/versions.xml ./CHANGELOG.md 10.10

require 'rubygems'
require 'redcarpet'
require 'nokogiri'
require 'yaml'

$version               = ARGV[0]
$versions_xml_fragment = ARGV[1]
$changelog_md          = ARGV[2]
$deployment_target     = ARGV[3]

$html_root = File.expand_path '../..', __FILE__


def log_information(message)
    print `tput setaf 2` if ENV['TERM']
    print '==>>> INFO: '
    print `tput sgr0` if ENV['TERM']
    puts "#{message}"
end

# Updates the release YAML.
def update_release_yaml
    release_yaml = File.join $html_root, '_data/release.yml'
    release_data = YAML.load_file(release_yaml)
    release_data['hermes_download'] = "https://github.com/HermesApp/Hermes/releases/download/v#{$version}/Hermes-#{$version}.zip"
    release_data['deployment_target'] = $deployment_target

    log_information "Updating Hermes release information in #{File.basename release_yaml} to #{$version}"
    YAML.dump(release_data, File.open(release_yaml, 'wb'))
end

# Take new_xml fragment and inject into versions.xml located in GH Pages root.
def update_versions_xml
    versions_xml = File.expand_path('../../versions.xml', __FILE__)
    new_xml = File.read($versions_xml_fragment).gsub("\t", '  ')
    log_information "Injecting new xml fragment (#{$versions_xml_fragment}) into #{versions_xml}"

    contents = Nokogiri::XML File.read(versions_xml)
    has_item = contents.css('item title').any? do |node|
      if node.content == "Version #{$version}"
        node.parent.replace contents.fragment(new_xml)
      end
    end

    if !has_item
      contents.css('language').first.add_next_sibling contents.fragment(new_xml)
    end

    File.open(versions_xml, 'wb') { |f| f << contents.to_xhtml(:indent => 2) }
end

# Render CHANGELOG.md and install into GH Pages root.
def render_changelog_md
    changelog_html = File.join($html_root, '/changelog.html')
    log_information "Rendering changelog (#{$changelog_md} -> #{changelog_html})"

    File.open(changelog_html, 'wb') { |f|
      f << Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(File.read($changelog_md))
    }
end


update_release_yaml
update_versions_xml
render_changelog_md
