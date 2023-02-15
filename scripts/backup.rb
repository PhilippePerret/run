=begin

Pour "suivre" (backuper) un fichier

=end
require 'osascript'

module Runner
class Script

attr_reader :folder

  def run(args, folder)
    @folder = folder
  
    #
    # On doit trouver le fichier à suivre, entendu que très souvent
    # il porte un nom variable.
    # 
    src = File.join(folder, args['file'])
    unless File.exist?(src)
      regpath = /#{args['file']}$/
      Dir["#{File.dirname(src)}/*"].each do |pth|
        src = pth and break if pth.match?(regpath)
      end
    end
    # 
    # Vérification ultime
    # 
    if src.nil? || not(File.exist?(src))
      puts "ERREUR : Le fichier à suivre (backup) est introuvable, je dois renoncer…".rouge
      puts "Note : il  est défini par #{args['file'].inspect} dans le dossier #{folder.inspect}".rouge
      return
    end

    #
    # Information
    # 
    # puts "Surveiller le fichier #{File.basename(src)}".bleu

    # 
    # Le dossier dans lequel il faut se placer
    # 
    # osascript buggue quand il doit écrire un tilde, si la lettre
    # suivante peut être tildée. Il faut le traiter ici, en remplaçant
    # le tilde par son action pour l'obtenir (n + option, espace)
    # 
    # puts "Dans : #{File.dirname(src).inspect}".bleu
    fld = File.dirname(src)
    if fld.match?(/~/)
      fld = fld.split("~").map do |el|
        [el, {key:'n', modifiers:[:option]}, ' ']
      end.flatten
      2.times{fld.pop} # pour enlever les 2 derniers
      fld.unshift("cd \"")
      fld.push("\"")
      puts "Nouveau fld : #{fld.inspect}" if debug?
      # return
    else
      fld = ["cd \"#{fld}\""]
    end
    # puts "(corrigé : #{fld.inspect})".gris

    # 
    # On se place dans le dossier et on lance la commande backup
    # par un osascript
    # 
    run_in_terminal({key:'n', modifiers:[:command]}, **{delay:0.6})
    run_fast_in_terminal(fld << :RETURN)
    run_in_terminal("backup \"#{File.basename(src)}\"\n")
  end

  def run_in_terminal(keys, **options)
    Osascript::Key.press(keys, 'Terminal', **options)
  end
  def run_fast_in_terminal(keys, **options)
    Osascript::Key.press(keys, 'Terminal', **options.merge(delay:0.01)) 
  end

end #/class Script
end #/module Runner
