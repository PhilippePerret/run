module Runner

  def self.archiver
    msg_fin = "Travail “#{@@travail.name}” archivé."
    @@travail.archive
    puts msg_fin.vert
  end

  def self.desarchiver
    anciens_travaux = Dir["#{ARCHIVES_FOLDER}/*.yaml"]
    if anciens_travaux.count == 0
      puts "Aucun travail n'est archivé… Je ne peux pas en désarchiver.".orange
    else
      oldw = anciens_travaux.map do |pth|
        dw = YAML.load_file(pth, **{symbolize_names: true})
        {name: dw[:name], value: File.basename(pth, File.extname(pth))}
      end << {name:'Renoncer'.bleu, value: nil}
      wconfig_id = Q.select("Désarchiver le travail :".jaune, oldw, **{per_page:oldw.count, show_help:false})
      wconfig_id || return
      travail = ConfigTravail.new(wconfig_id)
      travail.unarchive
      puts "Travail “#{travail.name}” désarchivé avec succès.".vert
    end
  end

end #/module Runner
