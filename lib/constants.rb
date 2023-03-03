
APP_FOLDER = File.dirname(__dir__)
# puts "APP_FOLDER = #{APP_FOLDER.inspect}"

class InterruptionVolontaire < StandardError; end

TRAVAUX_FOLDER  = mkdir(File.join(APP_FOLDER,'_travaux_'))
ARCHIVES_FOLDER = mkdir(File.join(TRAVAUX_FOLDER,'archives'))
SCRIPTS_FOLDER  = mkdir(File.join(APP_FOLDER,'scripts'))

CHOIX_RENONCER = {name:"Renoncer".orange, value: nil}

IDE = "Sublime Text"
IDE_CMD = 'subl -n "%s"'
