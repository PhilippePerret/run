#!/usr/bin/env ruby -U
require_relative 'lib/required'
begin
  Runner.run
rescue InterruptionVolontaire
  # silently quit
  puts "\n\nAbandon…".orange
rescue TTY::Reader::InputInterrupt
  # silently quit
end
