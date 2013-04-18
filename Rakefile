require 'rubygems'
require 'bundler/setup'
require 'jeweler'

Jeweler::Tasks.new do |gem|
  commit_date=DateTime.parse(`git log -1 --format=format:%ci`.chomp).strftime("%Y%m%d%H%I%M%S")
  gem.name = "contraction"
  gem.version = File.read("./VERSION")
  gem.summary = "A simple desgin-by-contract library"
  gem.description = "Using RDoc documentation as your contract definition, you get solid code, and good docs. Win-win!"
  gem.homepage = "https://github.com/thomasluce/contraction"
  gem.email = "thomas.luce@gmail.com"
  gem.authors = ["Thomas Luce"]

  # We don't have any, and I don't want bundler's stuff to just be jammed in
  # here.
  gem.dependencies.clear

  gem.files.reject! do |fn|
    fn =~ /^\.rspec.*$/ ||
    fn =~ /^\.rvmrc$/ ||
    fn =~ /^\.ruby-(version|gemset)$/ ||
    fn =~ /^Gemfile(\.lock)?$/ ||
    fn =~ /^Rakefile$/ ||
    fn =~ /^VERSION$/ ||
    fn =~ /^tmp\// ||
    fn =~ /^log\// ||
    fn =~ /^vendor\/cache\// ||
    fn =~ /^spec\//
  end
end
