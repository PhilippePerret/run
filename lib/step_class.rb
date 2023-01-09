module Runner

class StepError < StandardError; end

class ConfigTravail
class Step

  attr_reader :wconfig
  attr_reader :data
  def initialize(wconfig, step_data)
    @wconfig  = wconfig
    @data     = step_data
  end

  # = main =
  # 
  # Méthode principale qui joue l'étape
  # 
  def setup
    self.send(type.to_sym)  
  rescue StepError => e
    puts "#{e.message}\nJe dois renoncer à jouer cette étape.".rouge
  end

  # --- Step Methods ---

  ##
  # Un script à lancer
  # 
  def script
    load path
    Runner::Script.new.run(args, wconfig.default_folder)
  rescue Exception => e
    puts "Une erreur est survenue : #{e.message}".rouge
  end

  def open
    if File.directory?(path)
      # Ouverture d'un dossier
      `open -a Finder "#{path}"`
      @app = 'Finder'
    else
      # Ouverture d'un fichier
      cmd = app.nil? ? "open '#{path}'" : "open -a '#{app}' '#{path}'"
      `#{cmd}`
    end
    if bounds
      if app.nil?
        raise StepError.new("Pour pouvoir régler le bounds, il faut préciser l'application.")
      else
        bounds[2] = bounds[2] + bounds[0]
        bounds[3] = bounds[3] + bounds[1]
        Osascript.set_window_bounds(app, bounds)
      end
    end
  end

  ##
  # Pour jouer le code transmis
  # 
  def code
    case lang
    when 'ruby'
      eval(cmd)
    when 'applescript'
      `osascript -e "#{cmd}"`
    when 'bash'
      `#{cmd}`
    when 'python'
      raise StepError.new("Je ne sais pas encore interpréter du code python.")
    end
  rescue Exception => e
    puts "Problème avec la commande #{cmd.inspect} : #{e.message}".rouge
    return false
  end

  # --- Predicate Methods ---

  def script?
    type == :script
  end

  # --- Data ---

  # Toutes les données qui peuvent être définies dans une
  # étape dans le fichier YAML de la configuration.

  def type        ; @type     ||= data[:type].to_sym      end
  def lang        ; @lang     ||= data[:lang]             end
  def cmd         ; @cmd      ||= data[:cmd]              end
  def app         ; @app      ||= data[:app]              end
  def args        ; @args     ||= JSON.parse(data[:args]) end
  def bounds      ; @bounds   ||= data[:bounds]           end
  def path
    @path ||= begin
      pth = data[:path]
      unless File.exist?(pth)
        pth = 
          if script?
            File.join(SCRIPTS_FOLDER, "#{pth}.rb")
          else
            File.join(wconfig.default_folder, pth) 
          end
      end
      File.exist?(pth) || raise(StepError.new("Impossible de trouver le fichier/dossier #{pth.inspect}…"))
      pth
    end
  end

end #/class Step
end #/class ConfigTravail
end #/module Runner
