=begin

  Script pour update la version d'un fichier ou d'un dossier

  :args, dans les données de l'étape, doit être défini avec :
  '{"format":"version_ou_autre([0-9]+)-([0-9]+)-([0-9]+)"'}
  Ce sont particulièrement les "([0-9]+)" qui sont importants et
  permettront de fixer le nom correctement.

=end
module Runner
class Script
  attr_reader :folder
  def run(args, folder)
    @folder = folder
    # 
    # Un dossier backup doit exister
    # 
    File.exist?(backup_folder) || raise(StepError.new("Je ne trouve aucun dossier dont le nom comporte 'backup'… Je ne peux pas procéder au backup."))
    
    # 
    # Le format qui doit permettre de reconnaitre le fichier/dossier
    # 
    format_init     = args['format']
    filename_format = Regexp.new(args['format'])
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
          q.choice "#{vm.to_i+1}.0.0"
          q.choice "#{vm}.#{vs.to_i + 1}.0"
          q.choice "#{vm}.#{vs}.#{vp.to_i + 1}"
          q.choice "Ne pas la modifier", nil
          q.per_page 4
        end

        unless new_numbers.nil?
          new_version = "#{format_init}" 
          new_numbers.split('.').each do |v|
            new_version = new_version.sub(/\(?\[0\-9\]\+\)?/, v)
          end
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
    puts "Je dois apprendre à upgrader #{filename.inspect} avec #{new_version}".jaune
    methode = File.directory?(pth) ? :cp_r : :cp
    FileUtils.send(methode, pth, "#{backup_folder}/")
    FileUtils.mv(pth, File.join(File.dirname(pth),new_version))
    puts "Backup de #{old_version.inspect} effectuée et nouvelle version #{new_version.inspect} définie.".vert
  end

  def backup_folder
    @backup_folder ||= begin
      bfolder = nil
      Dir["#{folder}/*"].each do |pth|
        if File.directory?(pth) && File.basename(pth).downcase.match?(/backup/)
          bfolder = pth
          break
        end
      end
      bfolder
    end
  end
end
end #/module Runner
