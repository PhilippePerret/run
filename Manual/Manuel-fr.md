# Manuel français du runner

La commande `run` permet d'installer sur le bureau, dans les applications une configuration de travail quelconque.

## Création de la nouvelle configuration de travail

Jouer dans un Terminal (n’importe où) :

~~~bash
> run 
~~~

… choisir "Nouvelle configuration de travail" et suivre la procédure.

## Configuration d’un travail

### Nom humain de la configuration de travail

~~~yaml
---
name: "Nom du travail"
# ...
~~~

> C’est ce nom qui apparait dans la liste pour choisir un travail.

<a name="config-default-folder"></a>

### Dossier par défaut de la configuration

Si ce dossier est défini, il sera utilisé dès qu’un chemin d’accès ne sera pas trouvé tel quel.

~~~yaml
---
# ...
folder: "path/to/existing/folder"
# ...
~~~

<a name="config-steps"></a>

### Étapes de la configuration

Tout ce qu'il y a à installer se trouve dans la propriété `setup` du fichier `YAML` de la configuration de travail.

> Pour ouvrir ce manuel, jouer `run -h/--help`

Ce paramètre contient les étapes (`steps`) à jouer pour obtenir une installation complète.

### Ouverture d’un fichier

Pour ouvrir un fichier spécifique :

~~~yaml
:setup:
	- type: open
		path: path/to/file # peut être relatif à :folder
		app: application optionnelle # sinon l’application par défaut
		bounds: [top, left, width, height]
~~~

### Ouverture d’un dossier

~~~yaml
:setup:
	- type: open
		path: path/to/folder # peut être relatif à :folder
		bounds: [top, left, width, height]
		
~~~

### Jouer un script

Ce script doit se trouver dans le dossier `script` de `Run` ou être spécifié par chemin d’accès complet.

~~~yaml
:setup:
	- type: script
		path: mon_script
		args: '{"key":"value", "key2":"value2",...}' # format JSON
~~~

