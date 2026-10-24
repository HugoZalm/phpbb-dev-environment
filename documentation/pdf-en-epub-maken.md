---
title: "PDF en EPUB maken met build.ps1"
author: wereldfietsers
lang: nl
date: 2026-10-24
---

# PDF en EPUB maken

Met `build.ps1` zet je een Markdown-bestand uit de map `phpbb-dev-environment/documentation/` om naar een PDF, een EPUB of allebei. Het script gebruikt [pandoc](https://pandoc.org/) en LaTeX, maar die hoef je niet zelf te installeren: alles draait in een Docker-container.

## Wat je nodig hebt

- **Docker Desktop**, gestart. Het script stopt met een foutmelding als Docker niet bereikbaar is.
- **Windows PowerShell** (of PowerShell 7).
- Een **Markdown-bestand** in de map `phpbb-dev-environment/documentation/`.

De volgende bestanden in die map gebruikt het script ook. Laat ze daar staan:

| Bestand | Waarvoor |
| --- | --- |
| `Dockerfile` | Bouwt de image met pandoc en LaTeX |
| `pdf-header.tex` | Extra LaTeX-instellingen voor de PDF, zoals het afbreken van lange coderegels |

## Snel aan de slag

Voer dit uit vanuit de hoofdmap van het project:

```powershell
.\phpbb-dev-environment\documentation\build.ps1
```

Dit zet `installatie.md` om naar `installatie.pdf` en `installatie.epub`. Beide bestanden komen in dezelfde map als het bronbestand.

> **Let op:** de eerste keer duurt het lang. Docker downloadt dan de pandoc/LaTeX-image (ongeveer 1 GB). Daarna wordt die image hergebruikt.

## Een ander bestand omzetten

Gebruik `-Source` met de bestandsnaam:

```powershell
.\phpbb-dev-environment\documentation\build.ps1 -Source mijn-handleiding.md
```

De uitvoerbestanden krijgen dezelfde naam als het bronbestand: `mijn-handleiding.pdf` en `mijn-handleiding.epub`.

Geef bij `-Source` alleen de bestandsnaam op, geen pad. Het bestand moet in de map `documentation/` staan, want Docker kan alleen die map zien.

## Alleen een PDF of alleen een EPUB

Gebruik `-Target`:

```powershell
# Alleen de PDF
.\phpbb-dev-environment\documentation\build.ps1 -Target Pdf

# Alleen de EPUB
.\phpbb-dev-environment\documentation\build.ps1 -Target Epub

# Combineren met een ander bronbestand
.\phpbb-dev-environment\documentation\build.ps1 -Source mijn-handleiding.md -Target Pdf
```

## Alle parameters

| Parameter | Standaard | Betekenis |
| --- | --- | --- |
| `-Source` | `installatie.md` | Het Markdown-bestand dat je wilt omzetten |
| `-Target` | `All` | `All`, `Pdf` of `Epub` |
| `-ImageTag` | `phpbb-docs-pandoc:3.11` | Naam van de lokale Docker-image. Meestal hoef je dit niet te veranderen |

## Je Markdown-bestand voorbereiden

Begin je bestand met een blok met gegevens (YAML front matter). Pandoc gebruikt dit voor de titelpagina:

```yaml
---
title: "Titel van je document"
author: wereldfietsers
lang: nl
date: 2026-10-24
---
```

Houd verder rekening met het volgende:

- **Kopniveau 1 (`#`) wordt een hoofdstuk.** In de PDF begint elk hoofdstuk op een nieuwe pagina.
- **Hoofdstukken en paragrafen worden automatisch genummerd.** Zet zelf geen nummers in je koppen.
- **De inhoudsopgave** bevat kopniveau 1 en 2 (`#` en `##`).
- **Codeblokken** krijgen syntaxkleuring als je de taal opgeeft, bijvoorbeeld ` ```powershell `.

## Wat het script maakt

**PDF:** A4, marges van 2,5 cm, lettergrootte 11 pt, Nederlandse woordafbreking, titelpagina, inhoudsopgave en klikbare blauwe links.

**EPUB:** titelpagina, inhoudsopgave en genummerde hoofdstukken. Na het maken controleert het script of de EPUB een geldige structuur heeft.

Bestaande PDF- en EPUB-bestanden met dezelfde naam worden zonder waarschuwing overschreven.

## Problemen oplossen

| Melding | Oplossing |
| --- | --- |
| `Docker is niet bereikbaar` | Start Docker Desktop en wacht tot het klaar is met opstarten |
| `Bronbestand niet gevonden` | Controleer de bestandsnaam en of het bestand in `documentation/` staat |
| `Geef alleen een bestandsnaam op ..., geen pad` | Laat het pad weg bij `-Source`, bijvoorbeeld `-Source handleiding.md` in plaats van `-Source docs\handleiding.md` |
| `PDF-generatie mislukt` of `EPUB-generatie mislukt` | Lees de uitvoer van pandoc erboven. Vaak gaat het om een fout in de Markdown of een teken dat LaTeX niet kent |
| `running scripts is disabled on this system` | Start het script met: `powershell -ExecutionPolicy Bypass -File .\phpbb-dev-environment\documentation\build.ps1` |

## Deze handleiding zelf omzetten

Dit bestand kun je ook met het script omzetten:

```powershell
.\phpbb-dev-environment\documentation\build.ps1 -Source pdf-en-epub-maken.md
```
