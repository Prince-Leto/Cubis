# Règles et comportements

## Attaquer

Le but est d'être le dernier joueur encore propre. Pour y parvenir, il faut faire vomir les autres joueurs en les faisant boire.
Pour faire boire un joueur : `!buffalo <nick>`

De base, vous devez attendre 30 secondes avant de pouvoir redistribuer un buffalo. Ce temps est réduit de 3 secondes par buffalo que vous avez dans le sang.

Attention ! Un joueur peut vous renvoyer votre buffalo s'il boit de la bonne main. De base cette probabilité est de 1 sur 4, mais augmente en fonction du nombre de verre de la cible.
* À 0 verre, la cible à une probabilité de 1 sur 4 de vous renvoyer le verre
* À 1 verre, la cible à une probabilité de 1 sur 6 de vous renvoyer le verre
* À 2 verres, la cible à une probabilité de 1 sur 8 de vous renvoyer le verre
* ...
* À 9 verres, la cible à une probabilité de 1 sur 22 de vous renvoyer le verre

Lorsque vous faites vomir quelqu'un vous - que vous lui avez donné le buffalo fatal - pouvez regagner de la propreté :
* + 1 de propreté s'il vomi 2 à 5 verres
* + 2 de propreté s'il vomi 6 à 9 verres

## Se défendre

Pour vous défendre, vous pouvez utiliser la commande `!water <nick>` pour partager un verre d'eau avec quelqu'un. Cela réduira le nombre de buffalo de votre partenaire de boisson de 2, et le votre de 1.

Le temps d'attente entre deux verres d'eau est de 60 secondes, et vous avez 1 chance sur 6 que cela échoue.

## Vomir

Quand quelqu'un fait un buffalo, il a des chances de vomir. Ces chances augmentent en fonction du nombre de verres consommés.
* Pour 1 verre, les chances de vomir sont de 1 sur 9
* Pour 2 verres, les chances de vomir sont de 1 sur 8
* ...
* Pour 9 verres, les chances de vomir sont de 1 sur 1

Quand un joueur vomi, il le fait sur un des joueurs pris au hasard parmi les joueurs encore propres - y compris lui même.

Celui qui vomi perds la moitié du nombre de verres de propreté, à l'arrondi inférieur.
La cible perd, quant à elle, l'intégralité du nombre de verres en propreté.

## Événement spécial

Lorsque quelqu'un vomi, il y a 1 chance sur 4 qu'un événement spécial ait lieu. Le joueur va vomir, mais vous avez 10 secondes pour vous cacher. Celui qui vomi aussi peut prendre la peine de se protéger. Un joueur propre sera choisi au hasard parmi ceux qui ne se sont pas cachés. Si tout le monde s'est caché, la personne qui vomi, se vomira dessus.

## Consulter les données de la partie

Le jeu n'affiche pas les consommations et l'état de propreté des joueurs. Il faut le lui demander.
Faites `!etat` pour connaître l'état d'ébriété des joueurs et `!propre` pour connaître leur propreté.

## Redémarrer une partie

Faites `!voterestart` pour indiquer que vous souhaitez redémarrer une partie. Il faudra la majorité absolue des joueurs actifs depuis ces cinq dernière minutes pour que le jeu redémarre.

## Je suis une fille

Par défaut, tout joueur est un homme. Si vous êtes une femme, et que vous souhaitez que les phrases soit adaptées et conjuguées conformément à votre sexe, il vous faut l'indiquer. Pour ce faire, entrer la commande : `!sexe : f`.

Si, finalement, vous vous rendez compte que vous êtes un homme, tapez la commande : `!sexe : m`