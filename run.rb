#!/usr/bin/env ruby -U
require_relative 'lib/required'
begin
  Runner.run
rescue TTY::Reader::InputInterrupt
  # silently quit
end
