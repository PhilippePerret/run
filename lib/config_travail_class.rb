module Runner
class ConfigTravail
  class << self

    def create_new
      puts "Je dois apprendre à créer une nouvelle configuration de travail."
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
  def setup
    optional_steps = []
    steps = setup_steps.map do |step_data|
        Step.new(self, step_data)
      end.reject do |step|
        next unless step.optional?
        optional_steps << step.as_choice
        true
      end
    # 
    # On propose les étapes optionnelles pour choisir celles qu'on
    # doit exécuter.
    # 
    if optional_steps.count > 0
      steps += Q.multi_select("Étapes optionnelles :".jaune, optional_steps, **{per_page: optional_steps.count, help:'(cocher celles à exécuter et jouer la touche Entrée)'})
    end
    # 
    # On effectue toutes les étapes
    # 
    steps.each(&:execute)
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

end #/class ConfigTravail
end #/module Runner
