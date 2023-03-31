require 'clir'
require 'osascript'
require 'yaml'
require 'json'
require 'fileutils'
require 'precedences'

require_relative 'constants'
require_relative 'runner'
require_relative 'ctravail'
require_relative 'step'
require_relative 'args'

CLI.set_options_table({c: :choose})
