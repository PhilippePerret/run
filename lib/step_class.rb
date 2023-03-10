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
  def execute
    debug? && puts("-> Exécution de : #{aname}".jaune)
    self.send(type.to_sym)  
  rescue InterruptionVolontaire => e
    raise e
  rescue StepError => e
    puts "#{e.message}\nJe dois renoncer à jouer cette étape.".rouge
  ensure
    debug? && puts("<- /fin de : #{aname}".jaune)
  end


  # --- Step Methods ---

  ##
  # Un script à lancer
  # 
  def script
    load path
    Runner::Script.new.run(args, wconfig.default_folder)
  rescue TTY::Reader::InputInterrupt
    raise InterruptionVolontaire.new
  rescue Exception => e
    puts "Une erreur est survenue : #{e.message}".rouge
    puts e.backtrace.join("\n").rouge if debug?
  end

  def open
    if File.directory?(path)
      open_folder
    else
      open_file
    end
    set_bounds if bounds
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

  # Une URL à rejoindre
  def url
    require 'cgi'
    uri = path.dup
    if args
      querystring = args.map{|k,v|"#{k}=#{CGI.escape(v)}"}.join('&')
      uri = "#{uri}?#{querystring}"
    end
    if app
      `open -a "#{app}" #{uri}`
    else
      `open #{uri}`
    end
  end

  # --- Predicate Methods ---

  def script?
    type == :script
  end

  def optional?
    opt == true
  end

  # @return [Boolean] true si c'est une étape d'ouverture
  def opener?
    type == :open
  end

  def url?
    type == :url
  end

  # --- Helpers ---

  def as_choice
    self.name || raise(StepError.new("Une étape optionnelle doit obligatoirement posséder un :name."))
    { name: self.name, value: self }    
  end

  # --- Volatile Data ---

  # @return [String] Un nom, toujours, désignant l'étape, au pire
  # l'objet-id
  def aname
    @aname ||= name || id || description || "step ##{object_id}"
  end

  # --- Data ---

  # Toutes les données qui peuvent être définies dans une
  # étape dans le fichier YAML de la configuration.

  def id          ; @id           ||= data[:id]               end
  def type        ; @type         ||= data[:type].to_sym      end
  def lang        ; @lang         ||= data[:lang]             end
  def name        ; @name         ||= data[:name]             end
  def cmd         ; @cmd          ||= data[:cmd]              end
  def opt         ; @opt          ||= data[:opt]              end
  def app         ; @app          ||= data[:app]              end
  def bounds      ; @bounds       ||= data[:bounds]           end
  def description ; @description  ||= data[:description]      end
  def args
    @args ||= begin
      case data[:args]
      when String then JSON.parse(data[:args]) 
      else data[:args]
      end
    end
  end
  def path        ; @path         ||= get_real_path           end

  private

    def get_real_path
      pth = data[:path]
      return pth if url?
      pth_ini = "#{pth}"
      return pth if not(pth.start_with?('.')) && File.exist?(pth)
      pth = File.expand_path(pth, wconfig.default_folder)
      return pth if File.exist?(pth)
      if script?
        pth = File.join(SCRIPTS_FOLDER, "#{pth_ini}.rb")
        return pth if File.exist?(pth)
      end
      raise StepError.new("Impossible de trouver le fichier/dossier #{pth.inspect}…")
    end

    def open_folder
      case app
      when 'IDE'
        open_folder_in_ide
      when NilClass, 'Finder'
        `open -a Finder "#{path}"`
        @app = 'Finder'
      else
        raise StepError.new("Je ne sais pas ouvrir un dossier avec l'application #{app.inspect}…")
      end      
    end

    def open_folder_in_ide
      unless defined?(IDE)
        raise StepError.new("Pour ouvrir un dossier dans un IDE, il faut définir la constante IDE dans les constants.")
      end
      unless defined?(IDE_CMD)
        raise StepError.new("Il faut indiquer la commande à utiliser pour ouvrir dans l'IDE défini, à l'aide de la constante IDE_CMD.")
      end
      # On joue la commande pour ouvrir dans l'IDE défini
      cmd = IDE_CMD % path
      puts "Command : #{cmd.inspect}".bleu if debug?
      `#{IDE_CMD % path}`
    end

    def open_file
      cmd = app.nil? ? "open '#{path}'" : "open -a '#{app}' '#{path}'"
      `#{cmd}`      
    end

    def set_bounds
      if app.nil?
        raise StepError.new("Pour pouvoir régler le bounds, il faut préciser l'application.")
      else
        bounds[2] = bounds[2] + bounds[0]
        bounds[3] = bounds[3] + bounds[1]
        Osascript.set_window_bounds(app, bounds)
      end      
    end
end #/class Step
end #/class ConfigTravail
end #/module Runner
