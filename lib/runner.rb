=begin

  Main class

=end
module Runner

  def self.run
    clear
    # 
    # On prend l'argument juste après la commande 'run', qui peut
    # être soit une sous-commande, soit un identifiant de travail
    # à lancer (par exemple )
    command = ARGV.first
    if help?
      if command == 'help'
        open_manual
      else
        require_relative 'help'
        display_help
      end
    else
      case command
      when 'archive', 'archiver'
        require_relative 'archive'
        ensure_travail(ARGV[1]) || return
        archiver
      when 'unarchive', 'desarchive', 'desarchiver', 'désarchiver'
        require_relative 'archive'
        desarchiver
      when 'manuel', 'manual'
        open_something('manuel')
      when 'open', 'ouvre'              
        open_something(ARGV[1])
      else
        puts "(`run -h' pour ouvrir le manuel de Run)".gris
        ensure_travail(command) || return
        # 
        # Installer ce travail
        # 
        puts "Ouverture de #{@@travail.name.inspect}…".bleu
        @@travail.setup
      end
    end
  end


  def self.ensure_travail(command)
    @@travail = analyse_commande(command)
    return if @@travail === false # renoncement
    memo_travail_for_precedences if travail_valid?
    until travail_valid?
      @@travail = choose_travail || return
      if @@travail == :new
        @@travail = ConfigTravail.create_new
        return false
      end
    end
    @@travail.is_a?(ConfigTravail) || @@travail = ConfigTravail.new(@@travail)
  end

  # @return true si le travail @@travail est un travail valide
  def self.travail_valid?
    @@travail.is_a?(ConfigTravail) || File.exist?(File.join(TRAVAUX_FOLDER, "#{@@travail}.yaml")) || File.exist?(File.join(ARCHIVES_FOLDER, "#{@@travail}.yaml"))
  end

  # # @return [Boolean] si le travail (@@travail) est valide
  # def self.travail_invalid?
  #   # not(@@travail.is_a?(ConfigTravail)) || # c'était && avant…
  #   not(@@travail.is_a?(ConfigTravail)) && # bizarre, quand même… mais ça ne marche pas si c'est '||'
  #   !File.exist?(File.join(TRAVAUX_FOLDER, "#{@@travail}.yaml"))
  # end

  def self.choose_travail
    choices = Dir["#{TRAVAUX_FOLDER}/*.yaml"].map do |pth|
      begin
        {name: YAML.load_file(pth,**{symbolize_names:true})[:name], value: File.basename(pth, File.extname(pth))}
      rescue Psych::SyntaxError => e
        puts "Problème rencontré avec le fichier #{pth} : #{e.message}".rouge
        nil
      end
    end.compact + [{name: "Nouvelle configuration de travail".bleu, value: :new} ]

    precedencize(choices, precedences_file) do |q|
      q.question "Choisissez le travail :"
    end
  end

  def self.precedences_file
    @@precedences_file ||= File.join(folder_tmp,'travaux.precedences')
  end

  def self.pdf_manual_path
    @@pdf_manual_path ||= File.join(APP_FOLDER,'Manual','Manuel-fr.pdf')  
  end

  def self.md_manual_path
    @@md_manual_path ||= File.join(APP_FOLDER,'Manual','Manuel-fr.md')  
  end

  def self.folder_tmp # pour les précédences
    @@folder_tmp ||= mkdir(File.join(APP_FOLDER,'tmp'))
  end

  # --- Commmande Open ---

  def self.open_something(what)
    what ||= choose_what_to_open || return
    case what
    when 'scripts'  then open_folder(SCRIPTS_FOLDER)
    when 'travaux'  then open_folder(TRAVAUX_FOLDER)
    when 'manuel', 'manual'   then open_manual
    when 'ide'      then `subl -n "#{APP_FOLDER}"`
    else
      puts "Je ne sais pas comment ouvrir #{what.inspect}…".rouge
    end
  end

  ##
  # Ouvrir le manuel
  def self.open_manual
    if CLI.options[:dev]
      `open -a "Typora" "#{md_manual_path}"`
    else
      `open -a Preview "#{pdf_manual_path}"`
      puts "(ajouter l'option '--dev' pour ouvrir le fichier markdown)".gris
    end
    puts "Manuel ouvert.".vert
  end

  ##
  # Ouvrir le dossier +folder_path+ dans le Finder
  def self.open_folder(folder_path)
    `open -a Finder "#{folder_path}"`
  end

  ## Pour choisir ce qu'il faut ouvrir
  # @return [String] La clé de ce qu'il faut ouvrir. C'est WHAT_TO_OPEN
  # pour voir les valeurs possibles.
  # 
  def self.choose_what_to_open
    precedencize(WHAT_TO_OPEN, File.join(folder_tmp,'open.precedences')) do |q|
      q.question "Ouvrir…"
    end
  end


  private

    # Lorsqu'on donne à la commande le nom du travail à ouvrir, on
    # ne passe pas par sa mémorisation pour les précédences. Cette
    # méthode permet de palier ce problème.
    def self.memo_travail_for_precedences
      set_precedence(@@travail.id, precedences_file)
    end

    # Méthode qui va prendre la command donnée par l'utilisateur 
    # après la commande principale 'run' et voir si ça n'est pas
    # l'identifiant ou le titre d'une commande connue.
    # Si plusieurs commandes ont été trouvées, on les propose, si
    # une seule convient, on la prend.
    # 
    # @note : la recherche se fait aussi bien sur les noms que sur 
    # les identifiants, en cherchant d'abord dans les identifiants
    # 
    # @return [ConfigTravail] La configuration de travail trouvée,
    # choisie, ou nil
    # 
    def self.analyse_commande(cmd_ini)
      cmd_ini || return
      cmd = cmd_ini.dup
      # 
      # Si c'est l'identifiant exact
      return ConfigTravail.new(cmd) if File.exist?(File.join(TRAVAUX_FOLDER,"#{cmd}.yaml"))
      # 
      # On compare aux identifiants existants
      # 
      regcmd = /#{Regexp.escape(cmd)}/i
      goods = Dir["#{TRAVAUX_FOLDER}/*.yaml"].select do |pth|
        File.affix(pth).match?(regcmd)
      end
      
      if goods.empty?
        # 
        # Ce n'est pas possible que l'utilisateur ait rentré
        # n'importe quoi… (hum hum)… On va rechercher dans les noms
        # des installations
        # 
        goods = Dir["#{TRAVAUX_FOLDER}/*.yaml"].select do |pth| 
          wname = YAML.load_file(pth,**{symbolize_names:true})[:name]
          wname.match?(regcmd)
        end
      end

      # 
      # On teste le résultat trouvé
      #   1) Si aucun, on s'en retourne avec nil
      #   2) Si un seul, on le retourne
      #   3) Si plusieurs, on demande à choisir
      # 
      if goods.empty?
        puts "Aucun identifiant ni aucun nom ne contient #{cmd_ini.inspect}…".rouge
        return nil
      elsif goods.count == 1
        return ConfigTravail.new(File.affix(goods.first))
      else
        # 
        # Plusieurs candidats possibles, il faut proposer à 
        # l'utilisateur de choisir celui qui convient
        # 
        goods = goods.map {|pth| ConfigTravail.new(File.affix(pth))}      
      end


      # 
      # On choisit parmi les choix possible
      choices = goods.map { |w| {name:w.name, value: w} }
      choices << {name: "Choisir un autre travail".bleu, value: nil}
      choices << {name: "Renoncer".orange, value: false}
      Q.select("Quel travail ouvrir : ".jaune, choices, **{per_page:choices.count, show_help:false})
    end

WHAT_TO_OPEN = [
  {name:"Le dossier des scripts"      , value: 'scripts'},
  {name:'Le dossier des travaux'      , value: 'travaux'},
  {name:'Le manuel de l’application'  , value: 'manuel'},
  {name:'L’application dans l’IDE'    , value: 'ide'}
] + [{name:"Renoncer".orange, value: nil}]
end
