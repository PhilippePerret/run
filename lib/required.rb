require 'clir'
require 'osascript'
require 'yaml'
require 'json'
require 'fileutils'
require 'precedences'

require_relative 'constants'
require_relative 'runner'
require_relative 'ctravail_class'
require_relative 'step_class'

CLI.set_options_table({c: :choose})
