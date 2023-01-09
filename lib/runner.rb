=begin

  Main class

=end
module Runner

  def self.run
    clear
    if help?
      open_manual
    else
      @@travail = CLI.components.first
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

  ##
  # Pour ouvrir le manuel
  # 
  def self.open_manual
    `open -a Preview "#{pdf_manual_path}"`
    puts "Manuel ouvert.".vert
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

  def self.folder # pour les précédences
    @@folder ||= mkdir(File.join(APP_FOLDER,'tmp'))
  end
end
