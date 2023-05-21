module Runner

  def self.display_help
    less(AIDE_MINI)
  end


AIDE_MINI = <<-TEXT
*****************************
 AIDE DE LA COMMANDE #{'run'.bleu}
*****************************

#{'run'.bleu}

    Affiche la liste des travaux enregistrés et actifs, pour en
    choisir un à installer.

#{'run <ref>'.bleu}

    Installe, s'il le trouve, le travail qui correspond à <ref>.
    <ref> peut être un bout de l'identifiant ou du titre humain
    du travail à installer.

#{'run -h'.bleu}

    Affiche cette aide rapide.

#{'run help'.bleu}

    Affiche le manuel complet.


#{'run archive[ <ref>]'.bleu}

    Permet d'archiver un travail qui n'est plus utilisé (mais qui
    pourrait l'être à l'avenir).
    <ref> peut être un bout de l'identifiant ou du titre humain
    du travail à installer. S'il n'est pas fourni, c'est la liste
    des travaux courants qui est affichée.

#{'run unarchive[ <ref>]'.bleu}

    Permet de désarchiver, c'est-à-dire de remettre dans la liste 
    des travaux courants, un travail précédemment archivé.
    <ref> peut être un bout de l'identifiant ou du titre humain
    du travail à installer. S'il n'est pas fourni, c'est la liste
    des travaux archivés qui est fournie.

OPTIONS
*******

  -h        Affiche l'aide

  -c        "c" comme  "Choisir". Avec cette option, chaque étape
            du run devient optionnelle, c'est-à-dire qu'on demande
            avant chacune d'elle s'il faut l'exécuter. Permet de n'en
            exécuter que quelques-unes.

TEXT
end #/module Runner
