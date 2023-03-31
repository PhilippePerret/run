=begin
  Class Runner::Args
  ------------------
  Gestion des arguments

  Pour ne pas avoir à se préoccuper de la clé pour récupérer des
  arguments. Dans un script, on peut faire indifféremment :
    args['file']
    args[:file]
    args.file
  Ces trois codes renverront toujours la valeur de 'file' dans la
  propriété 'args' du setup
=end
module Runner
class ConfigTravail
class Step
class Args

  attr_reader :raw_data, :data

  # @param [String|Hash] raw_data Données telles qu'elles sont définies dans le setup
  def initialize(raw_data)
    @raw_data = raw_data.dup
    #
    # +raw_data+ peut avoir différents formats, dont String et Hash,
    # il faut la traiter pour obtenir une vraie table
    # 
    parse_raw_data
    #
    # Évalue certaines valeurs (par exemple, transforme les 
    # expressions régulières en Regexp)
    # 
    eval_data
  end

  def [](key)
    data[key.to_s] || data[key.to_sym]
  end

  def method_missing(methode, *args, &block)
    if self.data.key?(methode.to_s) || self.data.key?(methode.to_sym)
      self[methode]
    else
      raise NoMethodError.new(methode)
    end
  end

  private

    def eval_data
      @data.each do |k, v|
        case v
        when /^\// then @data.merge!(k => eval(v))
        end
      end
    end

    def parse_raw_data
      @data = 
      case raw_data
      when Hash   then raw_data
      when String then eval(raw_data)
      # when String then JSON.parse(raw_data)
      else raise "Je ne sais pas traité l'argument #{raw_data.inspect}::#{raw_data.class}"
      end
    end

end #/clas Args
end #/class Step
end #/class ConfigTravail
end #/module Runner
