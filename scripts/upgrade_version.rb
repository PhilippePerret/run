=begin

  Script pour updater la version d'un fichier ou d'un dossier

  Dans une étape, mettre :

  :type: 'script'
  :path: 'upgrade_version'
  :args: '{
    "format":"version_ou_autre([0-9]+)-([0-9]+)-([0-9]+)"'
    # Ce sont particulièrement les "([0-9]+)" qui sont importants et
    # permettront de fixer le nom correctement.
     
    "backup_folder": "path/to/folder"
    # Seulement si le dossier de backup ne se trouve pas au même
    # niveau que le fichier lui-même.
  }
=end
module Runner
class Script
  attr_reader :folder
  def run(args, folder)

    @folder = folder
    # 
    # Un dossier backup doit exister
    # 
    define_backup_folder(args)
    File.exist?(backup_folder) || raise(StepError.new("Je ne trouve aucun dossier dont le nom comporte 'backup'… Je ne peux pas procéder au backup."))
    args[:format].nil?  || raise(StepError.new("Ce script n'attend plus d'argument :format, mais :prefix et/ou :suffix…"))
    # 
    # Le format qui doit permettre de reconnaitre le fichier/dossier
    # 
    format_init     = "#{args[:prefix]}%s#{args[:suffix]}".strip.freeze
    filename_format = Regexp.new(format_init % "([0-9]+)\.([0-9]+)\.([0-9]+)").freeze

    # 
    # Pour savoir si on a bien trouver quelque chose à updater
    # 
    ok = false
    # 
    # Chercher l'élément qui matche ce format
    # 
    Dir["#{folder}/*"].each do |pth|
      filename = File.basename(pth)
      if filename.match?(filename_format)
        # puts "Le file #{filename.inspect} répond au format."
        # On demande la nouvelle version
        _, vm, vs, vp = filename.match(filename_format).to_a
        new_numbers = Q.select("Quel nouveau numéro de version pour #{filename} ?".jaune, **{show_help:false}) do |q|
          q.choice "#{vm}.#{vs}.#{vp.to_i + 1}"
          q.choice "#{vm}.#{vs.to_i + 1}.0"
          q.choice "#{vm.to_i+1}.0.0"
          q.choice "Ne pas la modifier", nil
          q.per_page 4
        end

        unless new_numbers.nil?
          new_version = format_init % new_numbers
          if new_version == format_init
            new_version = "v#{new_numbers}"
            puts "Je n'ai pas pu actualiser le numéro de version correctement. J'ai mis le nom standard #{new_version.inspect}".orange
          end
          backup_and_upgrade(pth, filename, new_version)
          ok = true
        else
          ok = true # ne pas modifier
        end
      end
    end
    if ok
      return true
    else
      raise StepError.new("Je n'ai pas pu trouver de dossier/fichier qui correspondait au format #{format_init.inspect}… Je ne peux pas produire de backup.")    
    end
  end

  def backup_and_upgrade(pth, filename, new_version)
    old_version = File.basename(pth)
    # 
    # Le nouveau nom, en fonction du fait qu'il y a une extension
    # ou non
    # 
    dst = File.join(File.dirname(pth),"#{new_version}#{File.extname(pth) unless File.directory?(pth)}")
    # 
    # La méthode à employer si c'est un dossier ou si c'est un 
    # fichier.
    # 
    methode = File.directory?(pth) ? :cp_r : :cp
    # 
    # On fait la copie de l'élément dans le dossier backup
    # 
    FileUtils.send(methode, pth, "#{backup_folder}/")
    # 
    # On change le nom
    # 
    FileUtils.mv(pth, dst)
    puts "Backup de #{old_version.inspect} effectuée et nouvelle version #{File.basename(dst).inspect} définie.".vert
  end

  # @return [String] Le path du chemin vers le dossier des backups
  # (attention : le dossier des backups du dossier courant, pas 
  #  celui de l'application 'backup' qui surveille un fichier)
  def backup_folder
    @backup_folder ||= define_backup_folder(nil)
  end

  def define_backup_folder(args)
    @backup_folder = args[:backup_folder] and return if args && args.key?(:backup_folder)
    bfolder = nil
    debug? && puts("backup_folder cherché dans #{folder.inspect}")
    Dir["#{folder}/*"].each do |pth|
      if File.directory?(pth) && File.basename(pth).downcase.match?(/backup/)
        bfolder = pth
        break
      end
    end
    debug? && puts("backup_folder trouvé : #{bfolder.inspect}")
    # 
    # Si le dossier backup n'a pas été trouvé, il est créé
    # 
    if bfolder.nil?
      bfolder = File.join(folder,'xbackup')
      mkdir(bfolder)
    end
    # 
    # On retourne le chemin d'accès au dossier backup
    # 
    return bfolder
  end
end
end #/module Runner
