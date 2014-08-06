#encoding: UTF-8
require 'cinch'
require_relative 'Plugin'
require_relative 'Cubis'

bot = Cinch::Bot.new do
  configure do |c|
    c.nick = "Cubis"
    # c.password = "password"
    c.server = "irc.iiens.net"
    c.channels = ["#cubis"]
    c.plugins.plugins = [Cinch::PluginManagement, Cinch::Plugins::Cubis]
  end
end

bot.start