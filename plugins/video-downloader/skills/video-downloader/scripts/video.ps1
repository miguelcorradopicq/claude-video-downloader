<#
.SYNOPSIS
  Télécharge une vidéo (yt-dlp) et/ou la prépare : version WhatsApp (meilleure qualité sous la limite) et/ou version Max.

.DESCRIPTION
  Compatible Windows PowerShell 5.1 et PowerShell 7 (Windows, macOS, Linux). Nécessite yt-dlp, ffmpeg et ffprobe.

  Version WhatsApp : la meilleure qualité possible sous la limite, sans jamais gonfler le fichier.
    1. Déjà en H.264/AAC et sous la limite -> simple copie (remux), aucune perte.
    2. Sinon, le script MESURE la vidéo : trois extraits de 15 s encodés en CRF 22 à chaque hauteur
       (1080, 720, 540, 480, 360 sur le petit côté) ; il garde la plus haute qui tient.
    3. Encodage final en 2 passes au plus petit de (budget, débit d'un CRF 18).
  Version Max : le meilleur fichier fourni par le site, sans réencodage.
  LesDeux : les deux fichiers, suffixés « - WhatsApp » et « - Max ».

  Réglages (dossier, version par défaut, limite, navigateur) : ~/.video-downloader.json,
  créés ou modifiés avec -Enregistrer.

.EXAMPLE
  ./video.ps1 "https://youtu.be/xxxx"
  ./video.ps1 "https://youtu.be/xxxx" -Mode Max
  ./video.ps1 -Enregistrer -Dossier "D:\Vidéos" -Mode WhatsApp
  ./video.ps1 -Reglages
  ./video.ps1 -Verifier
  ./video.ps1 -InstallerOutils
#>
param(
  [Parameter(Position = 0)][string]$Source,
  [ValidateSet('WhatsApp', 'Max', 'LesDeux')][string]$Mode,
  [string]$Dossier,
  [double]$LimiteMo = 0,
  [string]$Navigateur,     # navigateur dont on reprend la connexion : chrome, edge, firefox, safari, brave
  [switch]$SansNavigateur, # avec -Enregistrer : ne plus utiliser de navigateur par défaut
  [int]$CrfPlancher = 22,  # qualité minimale acceptée pour choisir la résolution
  [int]$CrfPlafond = 18,   # qualité « transparente » : au-delà, inutile de dépenser des octets
  [switch]$Enregistrer,
  [switch]$Reglages,
  [switch]$Verifier,
  [switch]$InstallerOutils
)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
$surWindows = ($PSVersionTable.PSEdition -eq 'Desktop') -or $IsWindows
$surMac = (-not $surWindows) -and $IsMacOS
$nulDev = if ($surWindows) { 'NUL' } else { '/dev/null' }
$maison = [Environment]::GetFolderPath('UserProfile')
$cheminReglages = Join-Path $maison '.video-downloader.json'

# --- Réglages ---------------------------------------------------------------
$cfg = [pscustomobject]@{ Dossier = (Join-Path $maison 'Downloads'); Mode = 'WhatsApp'; LimiteMo = 178; Navigateur = '' }
$existe = Test-Path -LiteralPath $cheminReglages
if ($existe) {
  $lu = Get-Content -LiteralPath $cheminReglages -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($lu.OutDir) { $cfg.Dossier = $lu.OutDir }        # ancien format
  if ($lu.TargetMiB) { $cfg.LimiteMo = $lu.TargetMiB }  # ancien format
  foreach ($k in 'Dossier', 'Mode', 'LimiteMo', 'Navigateur') { if ($null -ne $lu.$k -and "$($lu.$k)" -ne '') { $cfg.$k = $lu.$k } }
  if ($cfg.Mode -eq 'Both') { $cfg.Mode = 'LesDeux' }
}
function Show-Reglages {
  Write-Host ("REGLAGES : {0} ({1})" -f $cheminReglages, $(if (Test-Path -LiteralPath $cheminReglages) { 'enregistrés' } else { 'pas encore créés, valeurs par défaut' }))
  Write-Host ("  Dossier    : {0}" -f $cfg.Dossier)
  Write-Host ("  Mode       : {0}" -f $cfg.Mode)
  Write-Host ("  LimiteMo   : {0}" -f $cfg.LimiteMo)
  Write-Host ("  Navigateur : {0}" -f $(if ($cfg.Navigateur) { $cfg.Navigateur } else { '(aucun)' }))
}
if ($Enregistrer) {
  if ($Dossier) { $cfg.Dossier = $Dossier }
  if ($Mode) { $cfg.Mode = $Mode }
  if ($LimiteMo -gt 0) { $cfg.LimiteMo = $LimiteMo }
  if ($Navigateur) { $cfg.Navigateur = $Navigateur }
  if ($SansNavigateur) { $cfg.Navigateur = '' }
  New-Item -ItemType Directory -Force -Path $cfg.Dossier | Out-Null
  [IO.File]::WriteAllText($cheminReglages, ($cfg | ConvertTo-Json), (New-Object Text.UTF8Encoding $false))
  Write-Host 'REGLAGES enregistrés.'
  Show-Reglages
  if (-not $Source) { return }
}
if ($Reglages) { Show-Reglages; return }

# --- Outils -----------------------------------------------------------------
function Update-Path {
  if ($surWindows) {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
  } elseif (Test-Path '/opt/homebrew/bin') { $env:PATH = "/opt/homebrew/bin:/usr/local/bin:$env:PATH" }
}
# deno : moteur JavaScript dont yt-dlp a besoin pour YouTube (sans lui, certains formats manquent ou échouent).
# Il est installé avec les autres outils, mais son absence ne bloque pas un téléchargement.
function Get-Manquants([switch]$AvecDeno) {
  $outils = @('yt-dlp', 'ffmpeg', 'ffprobe'); if ($AvecDeno) { $outils += 'deno' }
  $outils | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }
}
Update-Path
if ($InstallerOutils) {
  $m = Get-Manquants -AvecDeno
  if (-not $m) { Write-Host 'OUTILS OK : yt-dlp, ffmpeg, ffprobe et deno sont déjà installés.' }
  elseif ($surWindows) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw "winget est introuvable. Installe « App Installer » depuis le Microsoft Store, puis relance." }
    if ($m -contains 'yt-dlp') { winget install --id yt-dlp.yt-dlp -e --silent --accept-source-agreements --accept-package-agreements | Out-Host }
    if ($m -contains 'ffmpeg' -or $m -contains 'ffprobe') { winget install --id Gyan.FFmpeg -e --silent --accept-source-agreements --accept-package-agreements | Out-Host }
    if ($m -contains 'deno') { winget install --id DenoLand.Deno -e --silent --accept-source-agreements --accept-package-agreements | Out-Host }
  } elseif ($surMac) {
    if (-not (Get-Command brew -ErrorAction SilentlyContinue)) { throw "Homebrew est introuvable. Installe-le depuis https://brew.sh, puis relance." }
    brew install yt-dlp ffmpeg deno | Out-Host
  } else { throw "Installe yt-dlp, ffmpeg et deno avec le gestionnaire de paquets de ta distribution." }
  Update-Path
  $m = Get-Manquants -AvecDeno
  if ($m) { Write-Host "OUTILS MANQUANTS après installation : $($m -join ', '). Ferme et rouvre l'application Claude, puis relance -Verifier." }
  else { Write-Host 'OUTILS OK : yt-dlp, ffmpeg, ffprobe et deno sont installés.' }
  return
}
if ($Verifier) {
  $m = Get-Manquants -AvecDeno
  if ($m) { Write-Host "OUTILS MANQUANTS : $($m -join ', ')" } else { Write-Host 'OUTILS OK : yt-dlp, ffmpeg, ffprobe, deno' }
  Show-Reglages
  return
}
$manquants = Get-Manquants
if ($manquants) { throw "Outils manquants : $($manquants -join ', '). Lance d'abord le script avec -InstallerOutils." }
if (-not (Get-Command deno -ErrorAction SilentlyContinue)) { Write-Host "DENO MANQUANT : yt-dlp en a besoin pour YouTube. Lance le script avec -InstallerOutils pour l'ajouter." }
if (-not $Source) { throw 'Donne un lien ou un fichier vidéo.' }
if (-not $Dossier) { $Dossier = $cfg.Dossier }
if (-not $Mode) { $Mode = $cfg.Mode }
if ($LimiteMo -le 0) { $LimiteMo = [double]$cfg.LimiteMo }
if (-not $Navigateur -and -not $SansNavigateur) { $Navigateur = $cfg.Navigateur }
$ffmpeg = (Get-Command ffmpeg).Source
$ffprobe = (Get-Command ffprobe).Source

$travail = Join-Path ([IO.Path]::GetTempPath()) ('video-downloader-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $travail, $Dossier | Out-Null
$suffixe = $Mode -eq 'LesDeux'

try {
  # --- 1. Source ------------------------------------------------------------
  $telecharge = $false
  if ($Source -match '^https?://') {
    $url = $Source
    # Liens courts LinkedIn et paramètres de partage : on résout et on nettoie
    if ($url -match '^https?://lnkd\.in/') {
      try {
        $h = New-Object System.Net.Http.HttpClient
        $r = $h.GetAsync($url).GetAwaiter().GetResult()
        $url = $r.RequestMessage.RequestUri.AbsoluteUri
        $h.Dispose()
      } catch { }
    }
    if ($url -match 'linkedin\.com/') { $url = ($url -split '\?')[0] }
    $ytArgs = @('--ignore-config', '--no-progress', '--no-playlist',
      '-f', 'bv*[vcodec^=avc1]+ba[ext=m4a]/bv*+ba/b', '--merge-output-format', 'mp4',
      '-o', '%(uploader,channel,creator|Video)s - %(title).80B [%(id).40B].%(ext)s',
      '--windows-filenames', '-P', $travail)
    if ($Navigateur) { $ytArgs += @('--cookies-from-browser', $Navigateur) }
    $ytArgs += $url
    & yt-dlp @ytArgs | Out-Host
    $src = Get-ChildItem -LiteralPath $travail -File |
      Where-Object { $_.Extension -notin '.part', '.ytdl', '.json', '.jpg', '.webp', '.png', '.vtt', '.srt' } |
      Sort-Object Length -Descending | Select-Object -First 1 -ExpandProperty FullName
    if (-not $src) { throw "ECHEC DU TELECHARGEMENT : aucune vidéo récupérée. Si le site demande d'être connecté, relance avec -Navigateur chrome (ou edge, firefox, safari)." }
    $telecharge = $true
  } else { $src = (Resolve-Path -LiteralPath $Source).Path }
  $base = [IO.Path]::GetFileNameWithoutExtension($src)
  $ext = [IO.Path]::GetExtension($src)

  function Get-Info($f) {
    $j = & $ffprobe -v error -show_entries 'format=duration,size:stream=codec_type,codec_name,width,height,bit_rate' -of json $f | Out-String | ConvertFrom-Json
    $v = $j.streams | Where-Object { $_.codec_type -eq 'video' } | Select-Object -First 1
    $a = $j.streams | Where-Object { $_.codec_type -eq 'audio' } | Select-Object -First 1
    [pscustomobject]@{
      Dur = [double]$j.format.duration; Size = [double]$j.format.size
      W = [int]$v.width; H = [int]$v.height; V = $v.codec_name
      A = $(if ($a) { $a.codec_name } else { $null }); ABps = $(if ($a -and $a.bit_rate) { [double]$a.bit_rate } else { 0 })
    }
  }
  function Get-Filtre($h) { "scale='if(gt(iw,ih),-2,$h)':'if(gt(iw,ih),$h,-2)'" }

  # --- 2. Version Max -------------------------------------------------------
  if ($Mode -in 'Max', 'LesDeux') {
    if ($telecharge) {
      $nom = if ($suffixe) { "$base - Max$ext" } else { "$base$ext" }
      $dest = Join-Path $Dossier $nom
      if ($suffixe) { Copy-Item -LiteralPath $src -Destination $dest -Force }
      else { Move-Item -LiteralPath $src -Destination $dest -Force; $src = $dest }
      Write-Host ("MAX      : {0}  ({1:N1} Mo)" -f $dest, ((Get-Item -LiteralPath $dest).Length / 1MB))
    } else { Write-Host 'MAX      : fichier local conservé tel quel.' }
  }

  # --- 3. Version WhatsApp --------------------------------------------------
  if ($Mode -in 'WhatsApp', 'LesDeux') {
    $info = Get-Info $src
    $budget = $LimiteMo * 1MB * 0.985          # marge : l'encodage 2 passes dépasse d'environ 1,3 %
    $nomSortie = if ($suffixe) { "$base - WhatsApp.mp4" } else { "$base.mp4" }
    $sortie = Join-Path $Dossier $nomSortie
    $tmp = Join-Path $travail 'sortie.mp4'

    if ($info.V -eq 'h264' -and ($info.A -eq 'aac' -or -not $info.A) -and $info.Size -le $budget) {
      & $ffmpeg -y -hide_banner -loglevel error -i $src -c copy -movflags +faststart $tmp
      $comment = 'copiée sans réencodage (déjà compatible, aucune perte)'
    } else {
      if ($info.A -eq 'aac' -and $info.ABps -gt 0 -and $info.ABps -le 132000) { $aArgs = @('-c:a', 'copy'); $abps = $info.ABps }
      elseif ($info.A) { $ab = if ($info.Dur -gt 1200) { 96 } else { 128 }; $aArgs = @('-c:a', 'aac', '-b:a', "${ab}k", '-ac', '2', '-ar', '44100'); $abps = $ab * 1000 }
      else { $aArgs = @('-an'); $abps = 0 }

      $vb = ($budget * 8 / $info.Dur) - $abps   # débit vidéo disponible (bit/s)
      $petit = [math]::Min($info.W, $info.H)
      $echelle = @(1080, 720, 540, 480, 360) | Where-Object { $_ -le $petit }
      if (-not $echelle) { $echelle = @($petit) }

      function Get-DebitEchantillon($h, $crf) {
        $entier = $info.Dur -le 45
        $duree = if ($entier) { $info.Dur } else { 15 }
        $debuts = if ($entier) { @(0) } else { @(0.15, 0.5, 0.85) | ForEach-Object { [math]::Floor($_ * ($info.Dur - $duree)) } }
        $octets = 0; $secs = 0
        foreach ($s in $debuts) {
          $p = Join-Path $travail 'sonde.mp4'
          & $ffmpeg -y -hide_banner -loglevel error -ss $s -t $duree -i $src -an -vf (Get-Filtre $h) -c:v libx264 -preset veryfast -crf $crf -pix_fmt yuv420p $p
          $octets += (Get-Item -LiteralPath $p).Length; $secs += $duree
        }
        $octets * 8 / $secs
      }

      $h = $null
      foreach ($cand in $echelle) { if ((Get-DebitEchantillon $cand $CrfPlancher) -le $vb) { $h = $cand; break } }
      if ($h) { $cible = [math]::Min($vb, (Get-DebitEchantillon $h $CrfPlafond)); $pourquoi = "le CRF $CrfPlancher tient dans la limite" }
      else { $h = $echelle[-1]; $cible = $vb; $pourquoi = 'limite très serrée : plus basse résolution, tout le budget' }
      $cible = [math]::Max($cible, 150000)

      for ($essai = 1; $essai -le 2; $essai++) {
        $kb = [int]($cible / 1000)
        $v = @('-vf', (Get-Filtre $h), '-c:v', 'libx264', '-preset', 'slow', '-b:v', "${kb}k", '-maxrate', "$([int]($kb * 1.6))k",
          '-bufsize', "$($kb * 3)k", '-profile:v', 'high', '-pix_fmt', 'yuv420p', '-passlogfile', (Join-Path $travail 'passe'))
        & $ffmpeg -y -hide_banner -loglevel error -i $src @v -pass 1 -an -f mp4 $nulDev
        & $ffmpeg -y -hide_banner -loglevel error -i $src @v -pass 2 @aArgs -movflags +faststart $tmp
        if ((Get-Item -LiteralPath $tmp).Length -le $LimiteMo * 1MB) { break }
        $cible = $cible * 0.93                  # filet de sécurité : dépassement -> 7 % de moins
      }
      $comment = "réencodée en ${h}p, vidéo $([int]($cible / 1000)) kb/s ($pourquoi)"
    }
    Move-Item -LiteralPath $tmp -Destination $sortie -Force
    Write-Host ("WHATSAPP : {0}  ({1:N2} Mo)  {2}" -f $sortie, ((Get-Item -LiteralPath $sortie).Length / 1MB), $comment)
  }
} finally {
  Remove-Item -LiteralPath $travail -Recurse -Force -ErrorAction SilentlyContinue
}
