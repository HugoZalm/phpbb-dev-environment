---
title: "phpBB dev-omgeving: installatie en je eerste extensie"
author: wereldfietsers
lang: nl
date: 2026-10-23
---

# Inleiding

Deze handleiding helpt je om de ontwikkelomgeving voor het phpBB-forum op een nieuwe computer op te zetten. Je krijgt een compleet lokaal forum op `http://localhost:8080`, zonder dat je PHP, Apache of een database op je eigen computer hoeft te installeren. Daarna bouw je je eerste phpBB-extensie en leer je hoe je die verpakt en op een andere omgeving uitrolt.

Je gebruikt hiervoor Docker. Docker draait twee containers:

| Container | Wat erin zit | Waar je het voor gebruikt |
| --- | --- | --- |
| `web` | PHP 8.3 en Apache | Serveert phpBB op poort 8080 |
| `db` | MariaDB 10.11 | Bewaart de forumdatabase |

De phpBB-bestanden staan in de map `phpbb/` op je computer. Die map wordt in de `web`-container gekoppeld aan `/var/www/html`. Je extensiecode staat in `extensions/hugozalm/` en wordt gekoppeld aan `/var/www/html/ext/hugozalm`. Daardoor kun je gewoon in je eigen editor werken: wijzigingen zijn direct zichtbaar in het forum.

De omgeving gebruikt:

- phpBB 3.3.19
- PHP 8.3
- MariaDB 10.11
- Docker Compose

> **Let op:** de databasewachtwoorden in dit project zijn alleen bedoeld voor lokaal gebruik. Gebruik ze nooit op een forum dat publiek bereikbaar is.

In deze handleiding zijn de commando's vooral geschreven voor Windows PowerShell. Waar macOS of Linux anders werkt, staat dat erbij. Alle commando's worden uitgevoerd vanuit de hoofdmap van het project, tenzij iets anders vermeld staat.

# Vereisten

Je hebt het volgende nodig:

- Docker Desktop op Windows of macOS, of Docker Engine met de Compose-plugin op Linux.
- Git.
- Een editor, bijvoorbeeld Visual Studio Code.
- Een moderne browser.

Je hebt **geen** lokale PHP-installatie en **geen** lokale MariaDB-installatie nodig. Alles draait in Docker.

## Docker installeren

Download Docker Desktop via [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/). Installeer het programma en start het. Op Windows kan Docker vragen om WSL 2 in te schakelen; volg dan de aanwijzingen van Docker.

Op Linux installeer je Docker Engine en de Compose-plugin via de documentatie van je distributie. Controleer daarna of Docker werkt:

```bash
docker --version
docker compose version
```

Op Windows open je PowerShell. Controleer daar:

```powershell
docker --version
docker compose version
git --version
```

Als Docker Desktop nog niet volledig is gestart, krijg je een foutmelding dat de Docker-engine niet bereikbaar is. Wacht tot Docker Desktop meldt dat de engine draait en probeer het opnieuw.

# Project ophalen

Haal de repository op met Git:

```powershell
git clone https://github.com/HugoZalm/phpbb-dev-environment.git
cd phpbb-dev-environment
```

Op macOS of Linux gebruik je dezelfde commando's in een terminal.

Na het klonen zie je ongeveer deze structuur:

```text
|--extensions               <- maak je zelf en vul je aan met extenties
|--phpbb-dev-environment/
|  -- .env
|  -- .gitignore
|  -- Dockerfile
|  -- compose.yaml
|  -- documentation/
|     -- installatie.md
|     -- installatie.pdf
|     -- installatie.epub
|     -- Dockerfile
|     -- build.ps1
|     -- pdf-header.tex
|  -- phpbb/                 <- maak je zelf aan en vul je met phpBB
```

De map `phpbb/` en `extensions` zitten bewust niet in de repository. phpBB is software van derden en je extensiecode staat lokaal in de map `extensions/`. De `.gitignore` zorgt ervoor dat Git de map phpbb niet meeneemt.


# extension-map
Maak de map voor je extensies aan vanuit de map boven phpbb-dev-environment:

```powershell
New-Item -ItemType Directory -Force -Path .\extensions
```

Op macOS of Linux:

```bash
mkdir -p extensions/hugozalm
```

> **Ter info:**  Plaats je de map op een andere locatie, wijzig dan de `EXTENSIONS_PATH` variabele in `.env`-file. Je kan relatieve en absolute padnamen gebruiken (bijvoorbeeld `EXTENSIONS_PATH=C:\Users\HugoZalm\Documents\extensions`)

# phpBB downloaden

Download phpBB 3.3.19 via de officiële downloadpagina: [phpbb.com/downloads](https://www.phpbb.com/downloads/). Kies de nieuwste stabiele versie in de 3.3-serie als 3.3.19 niet meer aangeboden wordt.

Pak het gedownloade archief uit. Je krijgt dan een map met daarin onder andere:

```text
app.php
common.php
config/
ext/
install/
styles/
vendor/
```

De inhoud van die map moet **direct** in `phpbb/` staan. Let dus op dat je niet per ongeluk een extra map krijgt, zoals `phpbb/phpBB3/app.php`. Dit is goed:

```text
phpbb-dev-environment/
|-- compose.yaml
|-- Dockerfile
|-- phpbb/
|   |-- app.php
|   |-- common.php
|   |-- config/
|   |-- ext/
|   |-- install/
|   `-- styles/
`-- extensions/
    `-- hugozalm/
```

Dit is fout, omdat de bestanden dan één map te diep staan:

```text
phpbb/
`-- phpBB3/
    |-- app.php
    `-- common.php
```

Op Windows kun je het archief met de rechtermuisknop uitpakken en de inhoud daarna naar `phpbb/` verplaatsen. Op macOS gebruik je het contextmenu en op Linux bijvoorbeeld `unzip`.

Controleer daarna of `app.php` op de juiste plek staat:

```powershell
Test-Path .\phpbb\app.php
```

De uitvoer moet `True` zijn. Op macOS of Linux gebruik je:

```bash
ls phpbb/app.php
```

# Containers starten

Start de containers vanuit de hoofdmap van het project:

```powershell
docker compose up -d --build
```

De eerste keer duurt dit langer. Docker bouwt dan de PHP/Apache-image en downloadt de MariaDB-image. Daarna starten beide containers.

Controleer de status:

```powershell
docker compose ps
```

Je ziet nu twee services. De `web`-container moet draaien en de `db`-container moet gezond zijn. De database heeft een healthcheck, waardoor de webcontainer pas start als de database klaar is.

Bekijk eventueel de logboeken:

```powershell
docker compose logs -f web
```

Met `Ctrl+C` stop je alleen het volgen van de logboeken; de container blijft draaien.

Open daarna je browser:

```text
http://localhost:8080
```

Je ziet nu de installatiepagina van phpBB.

Als poort 8080 al door een ander programma gebruikt wordt, krijg je een foutmelding. Zie het hoofdstuk [Problemen oplossen](#problemen-oplossen) voor een oplossing.

# phpBB installeren

De installatie gebeurt in je browser. Doorloop de stappen van de phpBB-installer. Bij de database-instellingen gebruik je de gegevens die in `compose.yaml` staan.

| Instelling | Waarde |
| --- | --- |
| Databasetype | MySQL / MariaDB met MySQLi |
| Databaseserver | `db` |
| Databasepoort | `3306` |
| Databasenaam | `phpbb` |
| Databasegebruiker | `phpbb` |
| Databasewachtwoord | `devpassword` |
| Tabelprefix | `phpbb_` |

De databaseserver is `db`, niet `localhost`. De database draait namelijk in een aparte container. Docker zorgt ervoor dat de naam `db` binnen het Docker-netwerk naar de databasecontainer verwijst.

Voor het beheerdersaccount kies je zelf lokale gegevens. Gebruik bijvoorbeeld:

| Instelling | Voorbeeldwaarde |
| --- | --- |
| Beheerdersnaam | `admin` |
| E-mailadres | `admin@example.com` |
| Wachtwoord | `change-me` |

Kies een wachtwoord dat je lokaal kunt onthouden. Gebruik deze voorbeeldwaarden niet op een publiek forum.

Rond de installatie af. Als de installer om SMTP-instellingen vraagt, kun je die overslaan; je hebt lokaal geen mailserver nodig.

Na de installatie is het forum bereikbaar op:

```text
http://localhost:8080
```

Het beheerderspaneel vind je op:

```text
http://localhost:8080/adm
```

Als de installer geen verbinding met de database kan maken, controleer dan of de databasecontainer gezond is:

```powershell
docker compose ps
docker compose logs db
```

# De installatiemap verwijderen

Na een geslaagde installatie moet je de map `phpbb/install/` verwijderen of hernoemen. Zolang die map bestaat, blijft phpBB waarschuwen en is je forum niet veilig in gebruik.

Op Windows:

```powershell
Remove-Item -Recurse -Force .\phpbb\install
```

Op macOS of Linux:

```bash
rm -rf phpbb/install
```

Herlaad daarna het forum. De waarschuwing zou nu weg moeten zijn.

> **Let op:** verwijder de installatiemap pas nadat de installatie helemaal is afgerond. Heb je hem toch te vroeg verwijderd, pak dan phpBB opnieuw uit en kopieer alleen de map `install/` terug.

# De extensiemap begrijpen

phpBB verwacht extensies in deze structuur:

```text
phpBB/ext/vendor-naam/extensienaam/
```

De leveranciersnaam en de extensienaam mogen alleen uit kleine letters en cijfers bestaan. Streepjes, underscores en hoofdletters zijn niet toegestaan. In dit project gebruiken we:

- Leverancier: `hugozalm`
- Extensie: `hello`

De extensie komt dus in phpBB terecht als:

```text
ext/hugozalm/hello/
```

In dit project staat de broncode echter niet in `phpbb/ext/`, maar in de map `extensions/hugozalm/` op je computer. `compose.yaml` koppelt die map aan de container via een tussenmap: ext-external en een script (in comand). Dit zorgt er voor dat de originele extenties in /var/www/html/ext/ niet overschreven worden of verdwijnen:

```text
extensions/  ->  /var/www/html/ext-external/
```

Daardoor werk je in je eigen editor en ziet phpBB de bestanden direct. Je hoeft na een codewijziging dus niet opnieuw te bouwen.

De mappenstructuur voor de extensie wordt:

```text
extensions/
`-- hugozalm/
    `-- hello/
        |-- composer.json
        |-- acp/
        |-- adm/
        |-- config/
        |-- controller/
        |-- event/
        |-- language/
        |-- migrations/
        `-- styles/
```

Controleer vanuit de container of de map zichtbaar is:

```powershell
docker compose exec web ls ext/hugozalm
```

> **PS: ** In dit voorbeeld gebruiken we `hugozalm` als vendornaam en `hello` als extensie-naam. Je kan meerdere vendornamen met meerdere extenties aan de extension-map toevoegen. Die worden dan allemall automatisch geladen

# Extensies in aparte Git-repositories beheren

Door de map `extensions/` buiten phpBB-dev-environment (het git-project) te plaatsen, kan elke map in `extensions/` zonder probleem zijn eigen Git-repository hebben. De ontwikkelomgeving blijft dan los van je extensierepositories.

## Waarom dit handig is

- **Losse ontwikkeling**: je kunt je extensie in een apart repository ontwikkelen, met eigen branches, commits en releases.
- **Makkelijk delen**: anderen kunnen je extensie clonen zonder dat ze de hele ontwikkelomgeving nodig hebben.
- **Meerdere extensies**: je kunt voor `extensions/vendor1/extensionA`, `extensions/vendor1/extensionB`, `extensions/vendor2/extensionA`, etc. allemaal een eigen remote koppelen.

## Een bestaande extensie clonen direct in de juiste map

Als je een al bestaande extensierepo wilt gebruiken, kun je deze direct op de juiste plek clonen. Zorg ervoor dat je de mapstructuur respecteert: de extensie moet eindigen in `extensions/<vendornaam>/<extensienaam>/` zodat hij gekoppeld wordt aan `ext/<vendornaam>/<extensienaam>/` in de container.

Verwijder eerst eventueel een bestaande lege map (indien aanwezig):

```powershell
Remove-Item -Recurse -Force .\extensions\hugozalm\mijn-extensie
git clone https://github.com/jouw-gebruiker/phpbb-ext-mijn-extensie.git .\extensions\hugozalm\mijn-extensie
```

Op macOS of Linux:

```bash
rm -rf extensions/hugozalm/mijn-extensie
git clone https://github.com/jouw-gebruiker/phpbb-ext-mijn-extensie.git extensions/hugozalm/mijn-extensie
```

Nadat je gekloond hebt, kun je de extensie direct inschakelen in het forum zoals beschreven in het volgende hoofdstuk. De koppeling via `compose.yaml` werkt gewoon, ongeacht of er een `.git`-map in de extensie zit.

# Je eerste extensie: Hello

We bouwen een kleine extensie die in de forumbalk `Hello <naam>` toont. De naam wordt één keer in het beheerderspaneel ingesteld en geldt voor het hele forum. Is de naam leeg, dan wordt er niets getoond.

De extensie bestaat uit de volgende onderdelen:

| Bestand of map | Functie |
| --- | --- |
| `composer.json` | Metadata: naam, versie en phpBB-compatibiliteit |
| `config/services.yml` | Registreert de ACP-controller en de event-listener |
| `event/main_listener.php` | Vult de taal en de groetnaam in de template |
| `styles/prosilver/template/event/overall_header_navigation_prepend.html` | Toont de groet in de forumbalk |
| `controller/acp_controller.php` | Verwerkt het instellingenformulier in de ACP |
| `acp/main_info.php` | Definieert het ACP-menu en de rechten |
| `acp/main_module.php` | Laadt de ACP-pagina |
| `adm/style/acp_hello_body.html` | Het formulier in het beheerderspaneel |
| `migrations/install_acp_module.php` | Maakt de configuratie en het ACP-menu aan |
| `language/en/common.php` | Engelse teksten voor de groet |
| `language/en/info_acp_hello.php` | Engelse teksten voor het ACP-menu |
| `language/nl/common.php` | Nederlandse teksten voor de groet |
| `language/nl/info_acp_hello.php` | Nederlandse teksten voor het ACP-menu |

De extensie heeft geen `ext.php`. Dat is geen fout: als dat bestand ontbreekt, gebruikt phpBB automatisch de basisklasse `\phpbb\extension\base`. Wil je later eigen enable- of disable-logica toevoegen, dan kun je alsnog een `ext.php` maken.

## Mappen aanmaken

Maak eerst de mappenstructuur aan. Op Windows:

```powershell
$ext = "extensions\hugozalm\hello"
New-Item -ItemType Directory -Force -Path "$ext\config", "$ext\event", "$ext\controller", "$ext\acp", "$ext\adm\style", "$ext\migrations", "$ext\language\en", "$ext\language\nl", "$ext\styles\prosilver\template\event"
```

Op macOS of Linux:

```bash
mkdir -p extensions/hugozalm/hello/{config,event,controller,acp,adm/style,migrations,language/en,language/nl,styles/prosilver/template/event}
```

## `composer.json`

Dit bestand vertelt phpBB dat de map een extensie is. De `name` moet overeenkomen met de mapstructuur: `hugozalm/hello`.

```json
{
    "name": "hugozalm/hello",
    "type": "phpbb-extension",
    "description": "Greets every visitor with a board-wide \"Hello <name>\" in the forum header.",
    "homepage": "",
    "version": "1.0.0-dev",
    "time": "2026-10-18",
    "license": "GPL-2.0-only",
    "authors": [
        {
            "name": "Hugo",
            "role": "Developer"
        }
    ],
    "require": {
        "php": "^7.2 || ^8.0",
        "composer/installers": "^1.0 || ^2.0"
    },
    "extra": {
        "display-name": "Hello",
        "soft-require": {
            "phpbb/phpbb": ">=3.3,<3.4"
        }
    }
}
```

De `soft-require` geeft aan welke phpBB-versies worden ondersteund. De `version` gebruik je later bij het uitbrengen van een nieuwe versie.

## `config/services.yml`

phpBB gebruikt dependency injection om objecten aan elkaar te koppelen. In dit bestand registreer je de controller voor het beheerderspaneel en de listener voor forumevents.

```yaml
services:
    hugozalm.hello.controller.acp:
        class: hugozalm\hello\controller\acp_controller
        arguments:
            - '@config'
            - '@language'
            - '@log'
            - '@request'
            - '@template'
            - '@user'

    hugozalm.hello.listener:
        class: hugozalm\hello\event\main_listener
        arguments:
            - '@config'
            - '@template'
        tags:
            - { name: event.listener }
```

De argumenten komen overeen met de volgorde van de constructor in de controller en de listener. De tag `event.listener` zorgt ervoor dat phpBB de listener daadwerkelijk aanroept.

## `event/main_listener.php`

De listener luistert naar twee phpBB-events:

- `core.user_setup`: laadt de taalbestanden van de extensie.
- `core.page_header`: maakt de groetnaam beschikbaar aan de template.

```php
<?php
/**
 *
 * Hello. An extension for the phpBB Forum Software package.
 *
 * @copyright (c) 2026 Hugo
 * @license GNU General Public License, version 2 (GPL-2.0)
 *
 */

namespace hugozalm\hello\event;

/**
 * @ignore
 */
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

/**
 * Hello Event listener.
 */
class main_listener implements EventSubscriberInterface
{
	/** @var \phpbb\config\config */
	protected $config;

	/** @var \phpbb\template\template */
	protected $template;

	/**
	 * Constructor
	 *
	 * @param \phpbb\config\config		$config		Config object
	 * @param \phpbb\template\template	$template	Template object
	 */
	public function __construct(\phpbb\config\config $config, \phpbb\template\template $template)
	{
		$this->config	= $config;
		$this->template	= $template;
	}

	/**
	 * Map phpBB core events to the listener methods that should handle those events
	 *
	 * @return array
	 */
	public static function getSubscribedEvents()
	{
		return [
			'core.user_setup'		=> 'load_language_on_setup',
			'core.page_header'		=> 'assign_greeting_name',
		];
	}

	/**
	 * Load common language files during user setup
	 *
	 * @param \phpbb\event\data	$event	Event object
	 */
	public function load_language_on_setup($event)
	{
		$lang_set_ext = $event['lang_set_ext'];
		$lang_set_ext[] = [
			'ext_name' => 'hugozalm/hello',
			'lang_set' => 'common',
		];
		$event['lang_set_ext'] = $lang_set_ext;
	}

	/**
	 * Make the greeting name available to the template
	 */
	public function assign_greeting_name()
	{
		$this->template->assign_var('HELLO_NAME', $this->config['hugozalm_hello_name']);
	}
}
```

De configuratiesleutel `hugozalm_hello_name` wordt later door de migratie aangemaakt. De listener leest die waarde bij iedere paginaweergave en zet hem in de template als `HELLO_NAME`.

## Template voor de header

Deze template wordt vóór de navigatielinks in de header van prosilver ingevoegd. Het bestand staat in `styles/prosilver/template/event/` en heet `overall_header_navigation_prepend.html`. De naam van het bestand bepaalt bij welk event hij hoort.

```html
{% if HELLO_NAME %}
<li class="header-hello" data-skip-responsive="true">
	<span>{{ lang('HELLO_GREETING', HELLO_NAME) }}</span>
</li>
{% endif %}
```

Is `HELLO_NAME` leeg, dan rendert de template niets. Anders verschijnt er een lijstitem met de vertaalde groet. De taalsleutel `HELLO_GREETING` bevat `%s`, dat door de tweede parameter wordt vervangen.

## Taalbestanden

phpBB-extensies hebben minimaal Engelse taalbestanden nodig. De Nederlandse bestanden worden gebruikt wanneer het forum op Nederlands staat.

### `language/en/common.php`

```php
<?php
/**
 *
 * Hello. An extension for the phpBB Forum Software package.
 *
 * @copyright (c) 2026 Hugo
 * @license GNU General Public License, version 2 (GPL-2.0)
 *
 */

if (!defined('IN_PHPBB'))
{
	exit;
}

if (empty($lang) || !is_array($lang))
{
	$lang = [];
}

// DEVELOPERS PLEASE NOTE
//
// All language files should use UTF-8 as their encoding and the files must not contain a BOM.
//
// Placeholders can now contain order information, e.g. instead of
// 'Page %s of %s' you can (and should) write 'Page %1$s of %2$s', this allows
// translators to re-order the output of data while ensuring it remains correct
//
// You do not need this where single placeholders are used, e.g. 'Message %d' is fine
// equally where a string contains only two placeholders which are used to wrap text
// in a url you again do not need to specify an order e.g., 'Click %sHERE%s' is fine
//
// Some characters you may want to copy&paste:
// ’ » “ ” …
//

$lang = array_merge($lang, [

	'HELLO_GREETING'			=> 'Hello %s',

	'ACP_HELLO_NAME'			=> 'Name',
	'ACP_HELLO_NAME_EXPLAIN'	=> 'The name to greet all visitors with in the forum header. Leave this empty to hide the greeting.',
	'ACP_HELLO_NAME_TOO_LONG'	=> 'The name you entered is too long, it may not be longer than %d characters.',
	'ACP_HELLO_SETTING_SAVED'	=> 'Settings have been saved successfully!',
]);
```

### `language/en/info_acp_hello.php`

```php
<?php
/**
 *
 * Hello. An extension for the phpBB Forum Software package.
 *
 * @copyright (c) 2026 Hugo
 * @license GNU General Public License, version 2 (GPL-2.0)
 *
 */

if (!defined('IN_PHPBB'))
{
	exit;
}

if (empty($lang) || !is_array($lang))
{
	$lang = [];
}

// DEVELOPERS PLEASE NOTE
//
// All language files should use UTF-8 as their encoding and the files must not contain a BOM.
//
// Placeholders can now contain order information, e.g. instead of
// 'Page %s of %s' you can (and should) write 'Page %1$s of %2$s', this allows
// translators to re-order the output of data while ensuring it remains correct
//
// You do not need this where single placeholders are used, e.g. 'Message %d' is fine
// equally where a string contains only two placeholders which are used to wrap text
// in a url you again do not need to specify an order e.g., 'Click %sHERE%s' is fine
//
// Some characters you may want to copy&paste:
// ’ » “ ” …
//

$lang = array_merge($lang, [
	'ACP_HELLO_TITLE'	=> 'Hello Module',
	'ACP_HELLO'			=> 'Hello Settings',

	'LOG_ACP_HELLO_SETTINGS'	=> '<strong>Hello settings updated</strong>',
]);
```

### `language/nl/common.php`

```php
<?php
/**
 *
 * Hello. An extension for the phpBB Forum Software package.
 *
 * @copyright (c) 2026 Hugo
 * @license GNU General Public License, version 2 (GPL-2.0)
 *
 */

if (!defined('IN_PHPBB'))
{
	exit;
}

if (empty($lang) || !is_array($lang))
{
	$lang = [];
}

// DEVELOPERS PLEASE NOTE
//
// All language files should use UTF-8 as their encoding and the files must not contain a BOM.
//
// Placeholders can now contain order information, e.g. instead of
// 'Page %s of %s' you can (and should) write 'Page %1$s of %2$s', this allows
// translators to re-order the output of data while ensuring it remains correct
//
// You do not need this where single placeholders are used, e.g. 'Message %d' is fine
// equally where a string contains only two placeholders which are used to wrap text
// in a url you again do not need to specify an order e.g., 'Click %sHERE%s' is fine
//
// Some characters you may want to copy&paste:
// ’ » “ ” …
//

$lang = array_merge($lang, [

	'HELLO_GREETING'			=> 'Hallo %s',

	'ACP_HELLO_NAME'			=> 'Naam',
	'ACP_HELLO_NAME_EXPLAIN'	=> 'De naam waarmee alle bezoekers in de forumbovenbalk begroet worden. Laat leeg om de begroeting te verbergen.',
	'ACP_HELLO_NAME_TOO_LONG'	=> 'De ingevoerde naam is te lang, hij mag maximaal %d tekens lang zijn.',
	'ACP_HELLO_SETTING_SAVED'	=> 'De instellingen zijn succesvol opgeslagen!',
]);
```

### `language/nl/info_acp_hello.php`

```php
<?php
/**
 *
 * Hello. An extension for the phpBB Forum Software package.
 *
 * @copyright (c) 2026 Hugo
 * @license GNU General Public License, version 2 (GPL-2.0)
 *
 */

if (!defined('IN_PHPBB'))
{
	exit;
}

if (empty($lang) || !is_array($lang))
{
	$lang = [];
}

// DEVELOPERS PLEASE NOTE
//
// All language files should use UTF-8 as their encoding and the files must not contain a BOM.
//
// Placeholders can now contain order information, e.g. instead of
// 'Page %s of %s' you can (and should) write 'Page %1$s of %2$s', this allows
// translators to re-order the output of data while ensuring it remains correct
//
// You do not need this where single placeholders are used, e.g. 'Message %d' is fine
// equally where a string contains only two placeholders which are used to wrap text
// in a url you again do not need to specify an order e.g., 'Click %sHERE%s' is fine
//
// Some characters you may want to copy&paste:
// ’ » “ ” …
//

$lang = array_merge($lang, [
	'ACP_HELLO_TITLE'	=> 'Hello-module',
	'ACP_HELLO'			=> 'Hello-instellingen',

	'LOG_ACP_HELLO_SETTINGS'	=> '<strong>Hello-instellingen bijgewerkt</strong>',
]);
```

## `controller/acp_controller.php`

De controller verwerkt het formulier in het beheerderspaneel. Hij controleert het formuliertoken, leest de naam uit, controleert de lengte, slaat de waarde op in de configuratie en schrijft een regel in het beheerderslogboek.

```php
<?php
/**
 *
 * Hello. An extension for the phpBB Forum Software package.
 *
 * @copyright (c) 2026 Hugo
 * @license GNU General Public License, version 2 (GPL-2.0)
 *
 */

namespace hugozalm\hello\controller;

/**
 * Hello ACP controller.
 */
class acp_controller
{
	/** @var \phpbb\config\config */
	protected $config;

	/** @var \phpbb\language\language */
	protected $language;

	/** @var \phpbb\log\log */
	protected $log;

	/** @var \phpbb\request\request */
	protected $request;

	/** @var \phpbb\template\template */
	protected $template;

	/** @var \phpbb\user */
	protected $user;

	/** @var string Custom form action */
	protected $u_action;

	/**
	 * Constructor.
	 *
	 * @param \phpbb\config\config		$config		Config object
	 * @param \phpbb\language\language	$language	Language object
	 * @param \phpbb\log\log			$log		Log object
	 * @param \phpbb\request\request	$request	Request object
	 * @param \phpbb\template\template	$template	Template object
	 * @param \phpbb\user				$user		User object
	 */
	public function __construct(\phpbb\config\config $config, \phpbb\language\language $language, \phpbb\log\log $log, \phpbb\request\request $request, \phpbb\template\template $template, \phpbb\user $user)
	{
		$this->config	= $config;
		$this->language	= $language;
		$this->log		= $log;
		$this->request	= $request;
		$this->template	= $template;
		$this->user		= $user;
	}

	/**
	 * Display the options a user can configure for this extension.
	 *
	 * @return void
	 */
	public function display_options()
	{
		// Add our common language file
		$this->language->add_lang('common', 'hugozalm/hello');

		// Create a form key for preventing CSRF attacks
		add_form_key('hugozalm_hello_acp');

		// Create an array to collect errors that will be output to the user
		$errors = [];

		// Is the form being submitted to us?
		if ($this->request->is_set_post('submit'))
		{
			// Test if the submitted form is valid
			if (!check_form_key('hugozalm_hello_acp'))
			{
				$errors[] = $this->language->lang('FORM_INVALID');
			}

			$name = $this->request->variable('hello_name', '', true);

			if (utf8_strlen($name) > 255)
			{
				$errors[] = $this->language->lang('ACP_HELLO_NAME_TOO_LONG', 255);
			}

			// If no errors, process the form data
			if (empty($errors))
			{
				// Set the greeting name
				$this->config->set('hugozalm_hello_name', $name);

				// Add option settings change action to the admin log
				$this->log->add('admin', $this->user->data['user_id'], $this->user->ip, 'LOG_ACP_HELLO_SETTINGS');

				// Option settings have been updated and logged
				// Confirm this to the user and provide link back to previous page
				trigger_error($this->language->lang('ACP_HELLO_SETTING_SAVED') . adm_back_link($this->u_action));
			}
		}

		$s_errors = !empty($errors);

		// Set output variables for display in the template
		$this->template->assign_vars([
			'S_ERROR'		=> $s_errors,
			'ERROR_MSG'		=> $s_errors ? implode('<br>', $errors) : '',

			'U_ACTION'		=> $this->u_action,

			'HELLO_NAME'	=> $this->config['hugozalm_hello_name'],
		]);
	}

	/**
	 * Set custom form action.
	 *
	 * @param string	$u_action	Custom form action
	 * @return void
	 */
	public function set_page_url($u_action)
	{
		$this->u_action = $u_action;
	}
}
```

De methode `set_page_url()` krijgt de URL van de ACP-pagina van `main_module.php`. Zonder die URL kan het formulier niet naar de juiste pagina versturen.

## `acp/main_info.php`

Dit bestand definieert het ACP-menu. De module komt onder de categorie `ACP_CAT_DOT_MODS`, dat is het tabblad **Extensions** in het beheerderspaneel. De `auth`-regel koppelt de pagina aan de extensie en aan de algemene beheerdersrechten.

```php
<?php
/**
 *
 * Hello. An extension for the phpBB Forum Software package.
 *
 * @copyright (c) 2026 Hugo
 * @license GNU General Public License, version 2 (GPL-2.0)
 *
 */

namespace hugozalm\hello\acp;

/**
 * Hello ACP module info.
 */
class main_info
{
	public function module()
	{
		return [
			'filename'	=> '\hugozalm\hello\acp\main_module',
			'title'		=> 'ACP_HELLO_TITLE',
			'modes'		=> [
				'settings'	=> [
					'title'	=> 'ACP_HELLO',
					'auth'	=> 'ext_hugozalm/hello && acl_a_board',
					'cat'	=> ['ACP_HELLO_TITLE'],
				],
			],
		];
	}
}
```

## `acp/main_module.php`

De module laadt de controller uit de container, stelt de templatenaam en paginatitel in en geeft de formulier-URL door.

```php
<?php
/**
 *
 * Hello. An extension for the phpBB Forum Software package.
 *
 * @copyright (c) 2026 Hugo
 * @license GNU General Public License, version 2 (GPL-2.0)
 *
 */

namespace hugozalm\hello\acp;

/**
 * Hello ACP module.
 */
class main_module
{
	public $page_title;
	public $tpl_name;
	public $u_action;

	/**
	 * Main ACP module
	 *
	 * @param int    $id   The module ID
	 * @param string $mode The module mode (for example: manage or settings)
	 * @throws \Exception
	 */
	public function main($id, $mode)
	{
		global $phpbb_container;

		/** @var \hugozalm\hello\controller\acp_controller $acp_controller */
		$acp_controller = $phpbb_container->get('hugozalm.hello.controller.acp');

		// Load a template from adm/style for our ACP page
		$this->tpl_name = 'acp_hello_body';

		// Set the page title for our ACP page
		$this->page_title = 'ACP_HELLO_TITLE';

		// Make the $u_action url available in our ACP controller
		$acp_controller->set_page_url($this->u_action);

		// Load the display options handle in our ACP controller
		$acp_controller->display_options();
	}
}
```

## `adm/style/acp_hello_body.html`

Dit is het formulier dat je in het beheerderspaneel ziet. Het gebruikt de standaard phpBB-opmaak en bevat een formuliertoken tegen CSRF.

```html
{% include 'overall_header.html' %}

<h1>{{ lang('ACP_HELLO_TITLE') }}</h1>

{% if S_ERROR %}
	<div class="errorbox">
		<h3>{{ lang('WARNING') }}</h3>
		<p>{{ ERROR_MSG }}</p>
	</div>
{% endif %}

<form id="hugozalm_hello_acp" name="hugozalm_hello_acp" method="post" action="{{ U_ACTION }}">

	<fieldset>
		<legend>{{ lang('SETTINGS') }}</legend>
		<dl>
			<dt><label for="hello_name">{{ lang('ACP_HELLO_NAME') }}{{ lang('COLON') }}</label><br><span>{{ lang('ACP_HELLO_NAME_EXPLAIN') }}</span></dt>
			<dd><input type="text" id="hello_name" name="hello_name" size="40" maxlength="255" value="{{ HELLO_NAME }}"></dd>
		</dl>
	</fieldset>

	<fieldset class="submit-buttons">
		<input class="button1" type="submit" id="submit" name="submit" value="{{ lang('SUBMIT') }}">
		{{ S_FORM_TOKEN }}
	</fieldset>

</form>

{% include 'overall_footer.html' %}
```

## `migrations/install_acp_module.php`

Een migratie past de database en de ACP-module aan wanneer de extensie voor het eerst wordt ingeschakeld. Deze migratie doet twee dingen:

- Ze voegt de configuratiesleutel `hugozalm_hello_name` toe met een lege standaardwaarde.
- Ze voegt de ACP-module toe onder het tabblad Extensions.

```php
<?php
/**
 *
 * Hello. An extension for the phpBB Forum Software package.
 *
 * @copyright (c) 2026 Hugo
 * @license GNU General Public License, version 2 (GPL-2.0)
 *
 */

namespace hugozalm\hello\migrations;

class install_acp_module extends \phpbb\db\migration\migration
{
	public function effectively_installed()
	{
		return isset($this->config['hugozalm_hello_name']);
	}

	public static function depends_on()
	{
		return ['\phpbb\db\migration\data\v320\v320'];
	}

	public function update_data()
	{
		return [
			['config.add', ['hugozalm_hello_name', '']],

			['module.add', [
				'acp',
				'ACP_CAT_DOT_MODS',
				'ACP_HELLO_TITLE',
			]],
			['module.add', [
				'acp',
				'ACP_HELLO_TITLE',
				[
					'module_basename'	=> '\hugozalm\hello\acp\main_module',
					'modes'				=> ['settings'],
				],
			]],
		];
	}
}
```

`effectively_installed()` zorgt ervoor dat phpBB de migratie niet opnieuw uitvoert als de configuratiesleutel al bestaat. `depends_on()` geeft aan dat deze migratie pas mag lopen na de standaardmigraties van phpBB 3.2.0.

## Bestanden controleren

Controleer voordat je de extensie inschakelt of alle bestanden op de juiste plek staan:

```powershell
docker compose exec web find ext/hugozalm/hello -type f
```

Controleer de PHP-syntax van alle bestanden:

```powershell
docker compose exec web sh -lc "find ext/hugozalm/hello -name '*.php' -exec php -l {} \;"
```

Je wilt bij elk bestand `No syntax errors detected` zien.

# Extensie inschakelen

Open het beheerderspaneel op `http://localhost:8080/adm` en ga naar:

```text
ACP -> Customise -> Manage extensions
```

Je ziet **Hello** nu onder de uitgeschakelde extensies staan. Klik op **Enable**. phpBB voert dan de migratie uit en maakt de configuratiesleutel en het ACP-menu aan.

Je kunt de extensie ook vanaf de commandoregel inschakelen:

```powershell
docker compose exec -T web php bin/phpbbcli.php extension:show
docker compose exec -T web php bin/phpbbcli.php extension:enable hugozalm/hello
docker compose exec -T web php bin/phpbbcli.php cache:purge
```

Controleer daarna of de extensie actief is:

```powershell
docker compose exec -T web php bin/phpbbcli.php extension:show
```

## De groet instellen

Na het inschakelen verschijnt er een nieuw tabblad **Extensions** in het beheerderspaneel. Ga naar:

```text
ACP -> Extensions -> Hello Module -> Hello Settings
```

Vul een naam in en klik op **Submit**. Open daarna het forum. Je ziet bovenaan, vóór de navigatielinks, bijvoorbeeld:

```text
Hello Wereldfietsers
```

Laat het veld leeg en klik opnieuw op **Submit** om de groet te verbergen.

## Extensie uitschakelen

Schakel de extensie uit via **ACP -> Customise -> Manage extensions -> Hello -> Disable**, of via de commandoregel:

```powershell
docker compose exec -T web php bin/phpbbcli.php extension:disable hugozalm/hello
docker compose exec -T web php bin/phpbbcli.php cache:purge
```

Als je de extensie daarna weer inschakelt, worden nieuwe migraties uitgevoerd. Dat is handig tijdens de ontwikkeling: pas je een migratie aan, schakel de extensie dan uit en weer in.

> **Let op:** gebruik **Delete data** alleen als je de extensie echt wilt verwijderen. Daarbij worden de configuratie en de ACP-module uit de database verwijderd. De bestanden in `extensions/hugozalm/hello/` blijven staan.

# Dagelijks gebruik

Deze commando's gebruik je vaak tijdens de ontwikkeling.

| Taak | Commando |
| --- | --- |
| Containers starten | `docker compose up -d` |
| Containers stoppen | `docker compose stop` |
| Gestopte containers weer starten | `docker compose start` |
| Containers stoppen en verwijderen | `docker compose down` |
| Opnieuw bouwen na wijziging in `Dockerfile` | `docker compose up -d --build` |
| Logboeken van de webserver volgen | `docker compose logs -f web` |
| Logboeken van de database volgen | `docker compose logs -f db` |
| Shell in de webcontainer openen | `docker compose exec web bash` |
| PHP-versie controleren | `docker compose exec web php -v` |
| Extensies tonen | `docker compose exec -T web php bin/phpbbcli.php extension:show` |
| Extensie inschakelen | `docker compose exec -T web php bin/phpbbcli.php extension:enable hugozalm/hello` |
| Extensie uitschakelen | `docker compose exec -T web php bin/phpbbcli.php extension:disable hugozalm/hello` |
| Extensiegegevens verwijderen | `docker compose exec -T web php bin/phpbbcli.php extension:purge hugozalm/hello` |
| Cache legen | `docker compose exec -T web php bin/phpbbcli.php cache:purge` |
| Database openen | `docker compose exec db mariadb -u phpbb -pdevpassword phpbb` |

`docker compose down` laat het databasevolume staan. Je forumdata blijft dus bewaard. Gebruik `docker compose down -v` alleen als je de database echt wilt verwijderen; daarna moet je phpBB opnieuw installeren en ben je de forumdata kwijt.

## Bestanden aanpassen

Je bewerkt de extensiebestanden gewoon in `extensions/hugozalm/hello/` met je editor. De container ziet dezelfde bestanden via de koppeling naar `ext/hugozalm`.

- PHP-wijzigingen zijn meestal direct zichtbaar na het herladen van de pagina.
- Templatewijzigingen kunnen een cache-purge nodig hebben.
- Nieuwe of gewijzigde migraties voer je uit door de extensie uit en weer in te schakelen.
- Na een wijziging in `services.yml` kan een cache-purge nodig zijn.

Cache legen via de commandoregel:

```powershell
docker compose exec -T web php bin/phpbbcli.php cache:purge
```

# Code bewaren in een git-repo
Zoals gezegd, kan je elke extensie in een eigen git-repo bewaren. Dit doe je zo:

Vanuit de hoofdmap van het project:

### 1) Ga naar de extensiemap

Op Windows (PowerShell):

```powershell
cd .\extensions\hugozalm\hello
```

Op macOS of Linux:

```bash
cd extensions/hugozalm/hello
```

### 2) Initialiseer een eigen repository

```bash
git init
```

### 3) Voeg bestanden toe en commit

```bash
git add .
git commit -m "Init hello extension"
```

Stel eventueel de standaardbranch in op `main`:

```bash
git branch -M main
```

### 4) Koppel aan een remote repository

Maak eerst een leeg repository aan op GitHub, GitLab of een andere Git-host (bijvoorbeeld `https://github.com/HugoZalm/phpbb-ext-hello.git`). Voeg deze daarna toe als remote:

```bash
git remote add origin https://github.com/HugoZalm/phpbb-ext-hello.git
git push -u origin main
```

Vanaf nu kun je vanuit deze map gewoon `git add`, `git commit`, `git push`, `git pull`, etc. gebruiken. Vanuit de hoofdmap van de ontwikkelomgeving wordt `extensions/hugozalm/hello` volledig genegeerd, dus `git status` daar toont niets van deze extensie.

# Verpakken en uitrollen

Als de extensie klaar is, wil je hem misschien op een andere phpBB-omgeving installeren. phpBB heeft in de kern geen knop om een ZIP-bestand via de ACP te uploaden. Je uploadt de uitgepakte bestanden via FTP/SFTP of het bestandsbeheer van je hosting, of je gebruikt de commandoregel op de server.

## Versie verhogen

Verhoog vóór een release de `version` in `composer.json` en werk `time` bij:

```json
"version": "1.0.0",
"time": "2026-10-23",
```

Gebruik een duidelijke versienummering, bijvoorbeeld `1.0.0`, `1.0.1` of `1.1.0`. Verhoog het versienummer bij iedere release.

Controleer ook:

- Of `README.md` en de licentie kloppen.
- Of er geen testbestanden, `.git`-mappen of lokale wachtwoorden in de extensie zitten.
- Of de extensie alleen bestanden bevat die echt nodig zijn.

## ZIP-bestand maken

De inhoud van de ZIP moet deze structuur hebben:

```text
hello-1.0.0.zip
`-- hugozalm/
    `-- hello/
        |-- acp/
        |-- adm/
        |-- composer.json
        |-- config/
        |-- controller/
        |-- event/
        |-- language/
        |-- migrations/
        `-- styles/
```

Let op: de map `hugozalm/hello/` moet de bovenste map in de ZIP zijn. Als je alleen de map `hello/` zipt, krijgt de gebruiker na het uitpakken `ext/hello/` in plaats van `ext/hugozalm/hello/`.

Op Windows kun je een tijdelijke map maken en daarin de juiste structuur opbouwen:

```powershell
New-Item -ItemType Directory -Force -Path .\build\hugozalm | Out-Null
Copy-Item .\extensions\hugozalm\hello .\build\hugozalm\hello -Recurse -Force
Compress-Archive -Path .\build\hugozalm -DestinationPath .\hello-1.0.0.zip -Force
Remove-Item .\build -Recurse -Force
```

Op macOS of Linux:

```bash
mkdir -p build/hugozalm
cp -R extensions/hugozalm/hello build/hugozalm/
(cd build && zip -r ../hello-1.0.0.zip hugozalm)
rm -rf build
```

## Installeren op een andere omgeving

Volg deze stappen op het doelsysteem:

1. Maak een back-up van de bestanden en de database van het forum.
2. Pak de ZIP uit en upload de map naar de phpBB-installatie, zodat dit ontstaat:

   ```text
   phpBB/ext/hugozalm/hello/
   ```

3. Zorg op Linux voor de juiste bestandsrechten. De webserver moet de bestanden kunnen lezen en moet kunnen schrijven in `cache/`, `files/`, `store/` en `config.php`.
4. Ga in het beheerderspaneel naar **Customise -> Manage extensions**.
5. Zoek **Hello** bij de uitgeschakelde extensies en klik op **Enable**.
6. Leg de cache leeg via **ACP -> General -> Purge the cache** of via de commandoregel:

   ```bash
   php bin/phpbbcli.php cache:purge
   ```

7. Open het forum en controleer of de groet werkt. Stel daarna de naam in via **ACP -> Extensions -> Hello Module -> Hello Settings**.

## Een extensie bijwerken

Voor een nieuwe versie op een bestaand forum:

1. Maak een back-up van de database en de extensiemap.
2. Schakel de extensie uit in **Manage extensions**.
3. Vervang de map `ext/hugozalm/hello/` door de inhoud van de nieuwe ZIP.
4. Schakel de extensie weer in. Nieuwe migraties worden nu uitgevoerd.
5. Leg de cache leeg en test de extensie.

Verwijder de extensie niet met **Delete data** als je alleen een update doet. Daarmee verwijder je de configuratie en de databasegegevens van de extensie.

## Gevorderd: buildscripts en releases

Voor grotere extensies kun je het buildscript van de phpBB Skeleton Extension gebruiken. Dat script kan een schone ZIP maken en bestanden zoals tests en Git-bestanden overslaan. Je kunt de ZIP ook als release op GitHub publiceren. Zorg in dat geval voor een duidelijke changelog en een verhoogd versienummer in `composer.json`.

# Problemen oplossen

## Poort 8080 is al in gebruik

Je krijgt een foutmelding zoals `port is already allocated`. Een ander programma gebruikt poort 8080. Pas in `compose.yaml` de poort aan:

```yaml
ports:
  - "8081:80"
```

Start daarna opnieuw:

```powershell
docker compose up -d
```

Het forum staat dan op `http://localhost:8081`.

Controleer op Windows welk programma de poort gebruikt:

```powershell
Get-NetTCPConnection -LocalPort 8080
```

Op macOS of Linux:

```bash
lsof -i :8080
```

## De installer kan geen verbinding maken met de database

Controleer eerst of de databasecontainer draait en gezond is:

```powershell
docker compose ps
docker compose logs db
```

Gebruik bij de installatie als databaseserver `db`, niet `localhost`. De waarden moeten overeenkomen met `compose.yaml`:

```text
db
3306
phpbb
phpbb
devpassword
```

Als je de databasegegevens in `compose.yaml` hebt aangepast, gebruik dan dezelfde waarden in de installer.

## De extensie verschijnt niet in de lijst

Controleer het volgende:

- De map heet precies `extensions/hugozalm/hello`.
- De leverancier en de extensienaam zijn lowercase en bevatten geen streepjes of underscores.
- `composer.json` is geldige JSON en de `name` is `hugozalm/hello`.
- De bestanden zijn zichtbaar in de container:

  ```powershell
  docker compose exec web ls ext/hugozalm/hello
  ```

- De cache is leeggemaakt:

  ```powershell
  docker compose exec -T web php bin/phpbbcli.php cache:purge
  ```

Controleer daarna opnieuw **Manage extensions**.

## De extensie inschakelen mislukt

Bekijk de foutmelding in de ACP en de logboeken:

```powershell
docker compose logs -f web
```

Controleer de PHP-syntax:

```powershell
docker compose exec web sh -lc "find ext/hugozalm/hello -name '*.php' -exec php -l {} \;"
```

Controleer of de migratie de juiste namespace en klassenaam heeft. De namespace moet `hugozalm\hello\migrations` zijn en de klasse moet `install_acp_module` heten.

Als een migratie halverwege is gestopt, schakel de extensie dan uit en weer in. Lukt dat niet, controleer dan de extensiestatus:

```powershell
docker compose exec -T web php bin/phpbbcli.php extension:show
```

## Wijzigingen zijn niet zichtbaar

- Leg de cache leeg.
- Herlaad de pagina met `Ctrl+F5`.
- Schakel de extensie uit en weer in als je een migratie hebt gewijzigd.
- Controleer of je het juiste bestand hebt aangepast en of de map in de container dezelfde is als op je computer.

## Het forum geeft een foutpagina of een witte pagina

Bekijk de logboeken van de webcontainer:

```powershell
docker compose logs -f web
```

Controleer of alle PHP-bestanden geldig zijn en of de extensie de juiste phpBB-versie ondersteunt. Zet de extensie indien nodig uit:

```powershell
docker compose exec -T web php bin/phpbbcli.php extension:disable hugozalm/hello
docker compose exec -T web php bin/phpbbcli.php cache:purge
```

## De ACP-module ontbreekt

De module wordt door de migratie aangemaakt. Als je de extensie al had ingeschakeld voordat de migratie bestond, schakel de extensie dan uit en weer in. Controleer daarna of **Hello Module** onder het tabblad **Extensions** staat.

## Bestandsrechten op Linux of macOS

Op Windows en macOS regelt Docker Desktop de toegang tot de gekoppelde mappen meestal automatisch. Op Linux kan de webserver geen schrijfrechten hebben op `cache/`, `files/`, `store/` of `config.php`. Zorg dan dat de gebruiker van de webserver in de container kan schrijven. Gebruik bij voorkeur de Docker-gebruikersmapping of pas de rechten van de genoemde mappen aan. Test daarna opnieuw.

## De database resetten

`docker compose down -v` verwijdert ook het databasevolume. Daarna moet je phpBB opnieuw installeren en ben je de forumdata kwijt. Kopieer voor de nieuwe installatie de map `install/` uit een verse phpBB-download terug en verwijder dan ook `phpbb/config.php`. Gebruik dit alleen als je zeker weet dat je een schone omgeving wilt:

```powershell
docker compose down -v
docker compose up -d --build
```

# Verder leren

De officiële phpBB-documentatie is de beste plek om verder te lezen:

- [phpBB downloaden](https://www.phpbb.com/downloads/)
- [Installatievereisten voor phpBB 3.3](https://www.phpbb.com/support/docs/en/3.3/ug/quickstart/installation_requirements/)
- [phpBB 3.3 extensiedocumentatie](https://area51.phpbb.com/docs/dev/3.3.x/extensions/)
- [Tutorial: Getting Started](https://area51.phpbb.com/docs/dev/3.3.x/extensions/tutorial_basics.html)
- [phpBB Skeleton Extension](https://area51.phpbb.com/docs/dev/3.3.x/extensions/skeleton_extension.html)

Belangrijke onderwerpen om daarna te leren:

- Events en listeners, om phpBB op de juiste momenten uit te breiden.
- Controllers en routes, voor eigen pagina's en formulieren.
- Migraties, voor wijzigingen in de database en het beheerderspaneel.
- Templates en taalbestanden, voor de gebruikersinterface.
- Rechten en permissies, zodat functies alleen zichtbaar zijn voor de juiste gebruikers.

Tips voor de verdere ontwikkeling:

- Houd je extensiecode in Git.
- Test tegen de phpBB-versie en PHP-versie die je echt ondersteunt.
- Verhoog het versienummer bij iedere release.
- Maak een back-up voordat je een extensie op een bestaand forum bijwerkt.
- Gebruik duidelijke foutmeldingen en test ook met een lege configuratie.
