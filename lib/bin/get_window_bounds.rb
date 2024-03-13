#!/usr/bin/env ruby

require 'clir'
$: << "/Users/philippeperret/Programmes/Gems/osascript/lib"
require 'osascript'


puts "Je vais retourner les dimensions de la fenêtre de Finder courante"

res = Osascript.get_window_properties("Finder")
res = res[:bounds]
puts <<~EOT
Les dimensions de la fenêtre sont :
Left:   #{res[0]}
Top:    #{res[1]}
Width:  #{res[2]}
Height: #{res[3]}

Pour bounds : #{res.inspect}
EOT
