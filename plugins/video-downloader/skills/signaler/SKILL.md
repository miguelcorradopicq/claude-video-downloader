---
name: signaler
description: Signale un problème ou propose une amélioration du téléchargeur de vidéos à son auteur, sous forme de ticket sur le dépôt GitHub du projet. À utiliser quand l'utilisateur dit « signale ce bug », « ça ne marche pas avec ce site », « j'aimerais que l'outil fasse… », « propose une amélioration ».
---

# Signaler un problème ou proposer une amélioration

Réponds en français. Le dépôt est `miguelcorradopicq/claude-video-downloader`.

1. Rédige le ticket avec l'utilisateur :
   - **Titre** court ;
   - **Type** : problème ou idée ;
   - **Description** : ce qui était attendu et ce qui s'est passé, ou l'amélioration souhaitée ;
   - pour un problème : le site concerné, le message d'erreur (dernières lignes du script), le système (Windows ou Mac) et la version de yt-dlp (`yt-dlp --version`).
2. **Confidentialité** : le ticket sera public. Retire les chemins contenant le nom d'utilisateur, les adresses e-mail, les liens de posts privés et toute information personnelle. Montre le texte final à l'utilisateur et **attends son accord explicite** avant de l'envoyer.
3. Envoi :
   - si `gh auth status` indique qu'il est connecté à GitHub : `gh issue create --repo miguelcorradopicq/claude-video-downloader --title "<titre>" --body "<texte>" --label "<bug ou amélioration>"` (sans `--label` si l'étiquette est refusée) ;
   - sinon : donne-lui le lien https://github.com/miguelcorradopicq/claude-video-downloader/issues/new/choose et le texte prêt à coller (il lui faut un compte GitHub gratuit).
4. Donne le lien du ticket créé.
