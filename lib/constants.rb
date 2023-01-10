
APP_FOLDER = File.dirname(__dir__)
puts "APP_FOLDER = #{APP_FOLDER.inspect}"

TRAVAUX_FOLDER = mkdir(File.join(APP_FOLDER,'_travaux_'))
SCRIPTS_FOLDER = mkdir(File.join(APP_FOLDER,'scripts'))

CHOIX_RENONCER = {name:"Renoncer".orange, value: nil}

IDE = "Sublime Text"
IDE_CMD = 'subl -n "%s"'
