module Runner
class ConfigTravail
  class << self

    def create_new
      wconfig_name = Q.ask("Nom de ce travail : ".jaune) || return
      wconfig_id   = wconfig_name.normalize.downcase.gsub(/( |::|:)/, '_')
      wconfig_id   = Q.ask("Son identifiant simple unique : ".jaune, **{default: wconfig_id})
      # 
      # On crée son fichier
      # 
      wconfig = new(wconfig_id)
      wconfig.create(**{name: wconfig_name})
      Runner.open_manual if Q.yes?("Dois-je ouvrir le manuel ?".jaune)
      # 
      # On ouvre toujours le fichier
      # 
      wconfig.open_config_file
      # 
      # On retourne l'instance
      # 
      return wconfig
    end

  end #/<< self

###################       INSTANCE      ###################
  
  attr_reader :id
  def initialize(wconfig_id)
    @id = wconfig_id
  end

  ##
  # = main =
  # 
  # Méthode principale pour installer le travail courant
  # 
  # @note
  #   Avec l'option -c/--choose, on n'ouvre que les étapes voulues
  # 
  def setup
    optional_steps = []
    open_steps     = [] # étapes d'ouverture
    steps = setup_steps.map do |step_data|
        Step.new(self, step_data)
      end.reject do |step|
        # 
        # En mode "choisir les étapes à jouer", on prend toutes les
        # étapes
        # 
        next if mode_choose?
        # 
        # Sinon, on ne garde que certaines étapes
        # 
        next unless step.optional? || step.opener?
        optional_steps << step if step.optional?
        open_steps     << step if step.opener?
        true
      end
    if mode_choose?
      # 
      # En mode pour choisir les étapes à jouer (-c/-choose)
      # (dans ce mode, toutes les étapes, même les étapes non 
      #  optionnelles, peuvent être passées)
      #
      steps.reject do |step|
        Q.no?("Dois-je jouer : #{step.aname} ? ('Y' pour oui)".jaune)
      end.each(&:execute)
    else
      #
      # En mode normal
      # 
      # 
      # On propose les étapes optionnelles pour choisir celles qu'on
      # doit exécuter.
      # 
      if optional_steps.count > 0
        choices = optional_steps.map do |step| 
          step.runit = false 
          step.as_choice
        end
        optional_steps_choosen = Q.multi_select("Étapes optionnelles :".jaune, choices, **{per_page: optional_steps.count, help:'(cocher celles à exécuter et jouer la touche Entrée)'})
        optional_steps_choosen.each {|step| step.runit = true}
        steps += optional_steps_choosen
      end
      # 
      # On effectue toutes les étapes hors ouvertures
      # 
      steps.each(&:execute)
      # 
      # On effecture les étapes d'ouverture en dernier
      # 
      open_steps.each(&:execute)
    
    end

  rescue InterruptionVolontaire => e
    raise e
  end

  # --- Functional Methods ---

  def open_config_file
    `subl -n "#{path}"`
  end

  def create(new_data)
    new_data.merge!(created_at: Time.now.strftime("%d/%m/%Y"), setup: [])
    @data = new_data.to_yaml
    save
  end

  def save
    File.write(path, data)
  end

  # Pour archiver le travail
  def archive
    FileUtils.mv(path, archive_path)
  end

  # Pour désarchiver un travail
  def unarchive
    FileUtils.mv(archive_path, path)
  end

  # - Predicate Methods -

  def mode_choose? 
    :TRUE == @enmodechoose ||= true_or_false(CLI.option(:choose))
  end

  # --- Data ---

  def name            ; @name           ||= data[:name]   end
  def setup_steps     ; @setup_steps    ||= data[:setup]  end
  def default_folder  ; @default_folder ||= data[:folder] end

  def data
    @data ||= YAML.load_file(path, **{aliases: true, symbolize_names: true})
  end

  def path
    @path ||= File.join(TRAVAUX_FOLDER,"#{id}.yaml")
  end

  def archive_path
    @archive_path ||= File.join(ARCHIVES_FOLDER,"#{id}.yaml")
  end

end #/class ConfigTravail
end #/module Runner
