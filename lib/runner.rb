=begin

  Main class

=end
module Runner

  def self.run
    clear
    command = ARGV.first
    # command = CLI.components.first # POURQUOI EST-CE QUE ÇA NE FONCTIONNE PAS ????
    # puts "CLI.components = #{CLI.components.inspect}"
    if help?
      open_manual
    elsif command == 'open'
      open_something(ARGV[1])
    else
      puts "(`run -h' pour ouvrir le manuel)".gris
      @@travail = command
      while travail_invalid?
        @@travail = choose_travail || return
        if @@travail == :new
          @@travail = ConfigTravail.create_new
          return
        end
      end
      # 
      # Installer ce travail
      # 
      @@travail.is_a?(ConfigTravail) || @@travail = ConfigTravail.new(@@travail)
      @@travail.setup
    end
  end


  # @return [Boolean] si le travail (@@travail) est valide
  def self.travail_invalid?
    not(@@travail.is_a?(ConfigTravail)) &&
    !File.exist?(File.join(TRAVAUX_FOLDER, "#{@@travail}.yaml"))
  end

  def self.choose_travail
    choices = Dir["#{TRAVAUX_FOLDER}/*.yaml"].map do |pth|
      {name: YAML.load_file(pth,**{symbolize_names:true})[:name], value: File.basename(pth, File.extname(pth))}
    end
    choices = choices_with_precedences(choices) + [{name: "Nouvelle configuration de travail".bleu, value: :new} ]
    Q.select("Travail à installer : ".jaune, choices, **{per_page:choices.count, show_help: false})    
  end

  def self.pdf_manual_path
    @@pdf_manual_path ||= File.join(APP_FOLDER,'Manual','Manuel-fr.pdf')  
  end

  def self.md_manual_path
    @@md_manual_path ||= File.join(APP_FOLDER,'Manual','Manuel-fr.md')  
  end

  def self.folder # pour les précédences
    @@folder ||= mkdir(File.join(APP_FOLDER,'tmp'))
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
    choices = choices_with_precedences(WHAT_TO_OPEN,'open')
    Q.select("Ouvrir…".jaune, choices, **{per_page: choices.count})
  end

WHAT_TO_OPEN = [
  {name:"Le dossier des scripts"      , value: 'scripts'},
  {name:'Le dossier des travaux'      , value: 'travaux'},
  {name:'Le manuel de l’application'  , value: 'manuel'},
  {name:'L’application dans l’IDE'    , value: 'ide'}
]
end
