-- ============================================================
--  Games Database - PostgreSQL
--  Tables: genres, tags, games, game_genres, game_tags
-- ============================================================

CREATE EXTENSION IF NOT EXISTS vector;

-- Removed DROP TABLE statements to prevent clearing data on every app restart

-- ============================================================
--  GENRES
-- ============================================================
CREATE TABLE genres (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO genres (name) VALUES
    ('Action'),
    ('Adventure'),
    ('RPG'),
    ('Strategy'),
    ('Simulation'),
    ('Sports'),
    ('Racing'),
    ('Puzzle'),
    ('Horror'),
    ('Platformer'),
    ('Fighting'),
    ('Shooter'),
    ('Stealth'),
    ('Survival'),
    ('MMORPG'),
    ('Visual Novel'),
    ('Roguelike'),
    ('Metroidvania'),
    ('Sandbox'),
    ('Battle Royale');

-- ============================================================
--  TAGS
-- ============================================================
CREATE TABLE tags (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO tags (name) VALUES
    ('Multiplayer'),
    ('Single Player'),
    ('Co-op'),
    ('Open World'),
    ('Story Rich'),
    ('Atmospheric'),
    ('Difficult'),
    ('Relaxing'),
    ('Pixel Art'),
    ('3D'),
    ('2D'),
    ('Sci-Fi'),
    ('Fantasy'),
    ('Post-Apocalyptic'),
    ('Cyberpunk'),
    ('Historical'),
    ('Procedural Generation'),
    ('Crafting'),
    ('Exploration'),
    ('Stealth'),
    ('Turn-Based'),
    ('Real-Time'),
    ('Online'),
    ('Local Multiplayer'),
    ('Controller Support'),
    ('Moddable'),
    ('Dark Themes'),
    ('Humor'),
    ('Anime'),
    ('Sandbox'),
    ('Loot'),
    ('Competitive'),
    ('Casual'),
    ('Retro'),
    ('Horror'),
    ('Space'),
    ('Magic'),
    ('Zombies'),
    ('Robots'),
    ('Mythological');

-- ============================================================
--  GAMES
-- ============================================================
CREATE TABLE games (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(200) NOT NULL,
    developer       VARCHAR(200),
    publisher       VARCHAR(200),
    release_year    INT,
    platform        VARCHAR(100),
    rating          NUMERIC(3,1),   -- out of 10
    price_usd       NUMERIC(6,2),
    description     TEXT,
    embedding       VECTOR(1024)
);

INSERT INTO games (title, developer, publisher, release_year, platform, rating, price_usd, description) VALUES
-- 1-20
('The Witcher 3: Wild Hunt',      'CD Projekt Red',       'CD Projekt',          2015, 'PC/PS4/Xbox/Switch', 9.8, 39.99, 'Massive open-world RPG following Geralt of Rivia.'),
('Red Dead Redemption 2',          'Rockstar Games',       'Rockstar Games',      2018, 'PC/PS4/Xbox',        9.7, 59.99, 'Epic tale of life in America''s unforgiving heartland.'),
('The Legend of Zelda: BotW',      'Nintendo',             'Nintendo',            2017, 'Switch/WiiU',        9.7, 59.99, 'Open-air adventure through Hyrule.'),
('Dark Souls III',                  'FromSoftware',         'Bandai Namco',        2016, 'PC/PS4/Xbox',        9.2, 39.99, 'Challenging action-RPG in a dark fantasy world.'),
('God of War (2018)',               'Santa Monica Studio',  'Sony',                2018, 'PS4/PC',             9.6, 49.99, 'Kratos and his son journey through Norse mythology.'),
('Elden Ring',                      'FromSoftware',         'Bandai Namco',        2022, 'PC/PS5/Xbox',        9.5, 59.99, 'Open-world dark fantasy RPG by FromSoftware and G.R.R. Martin.'),
('Hollow Knight',                   'Team Cherry',          'Team Cherry',         2017, 'PC/Switch/PS4/Xbox', 9.4, 14.99, 'Challenging action-adventure in a vast underground kingdom.'),
('Sekiro: Shadows Die Twice',       'FromSoftware',         'Activision',          2019, 'PC/PS4/Xbox',        9.2, 59.99, 'Shinobi action set in late Sengoku Japan.'),
('Persona 5 Royal',                 'Atlus',                'Atlus',               2020, 'PS4/PC/Switch',      9.5, 59.99, 'Turn-based JRPG about high school students fighting corruption.'),
('Hades',                           'Supergiant Games',     'Supergiant Games',    2020, 'PC/Switch/PS/Xbox',  9.3, 24.99, 'Rogue-like dungeon crawler where you play as the son of Hades.'),
('Cyberpunk 2077',                  'CD Projekt Red',       'CD Projekt',          2020, 'PC/PS5/Xbox',        8.5, 59.99, 'Open-world action-RPG set in a dystopian future city.'),
('Grand Theft Auto V',              'Rockstar North',       'Rockstar Games',      2013, 'PC/PS5/Xbox',        9.2, 29.99, 'Open-world crime saga in Los Santos.'),
('Minecraft',                       'Mojang Studios',       'Xbox Game Studios',   2011, 'PC/Consoles/Mobile', 9.5,  26.95, 'Sandbox survival and creative building game.'),
('Portal 2',                        'Valve',                'Valve',               2011, 'PC/PS3/Xbox',        9.8, 19.99, 'Puzzle-platformer with mind-bending physics mechanics.'),
('Half-Life: Alyx',                 'Valve',                'Valve',               2020, 'PC VR',              9.4, 59.99, 'Groundbreaking VR shooter set in the Half-Life universe.'),
('Disco Elysium',                   'ZA/UM',                'ZA/UM',               2019, 'PC/PS/Xbox',         9.4, 39.99, 'Groundbreaking detective RPG with deep narrative choices.'),
('Divinity: Original Sin 2',        'Larian Studios',       'Larian Studios',      2017, 'PC/PS4/Xbox/Switch', 9.3, 44.99, 'Deep tactical RPG with rich storytelling and co-op.'),
('Monster Hunter: World',           'Capcom',               'Capcom',              2018, 'PC/PS4/Xbox',        9.0, 29.99, 'Hunt gigantic monsters across lush ecosystems.'),
('Doom Eternal',                    'id Software',          'Bethesda',            2020, 'PC/PS4/Xbox/Switch', 9.0, 39.99, 'Ultra-fast demonic shooter sequel.'),
('Control',                         'Remedy Entertainment', '505 Games',           2019, 'PC/PS5/Xbox',        8.7, 29.99, 'Supernatural action-adventure inside a brutalist government building.'),

-- 21-40
('Mass Effect Legendary Edition',   'BioWare',              'EA',                  2021, 'PC/PS4/Xbox',        9.5, 59.99, 'Remastered sci-fi RPG trilogy following Commander Shepard.'),
('Stardew Valley',                  'ConcernedApe',         'ConcernedApe',        2016, 'PC/Switch/PS4/Xbox',  9.4, 14.99, 'Charming farming RPG in a relaxing rural setting.'),
('Undertale',                       'Toby Fox',             'Toby Fox',            2015, 'PC/Switch/PS',       9.1, 9.99,  'RPG where you can befriend or fight every monster.'),
('Celeste',                         'Maddy Thorson',        'Matt Makes Games',    2018, 'PC/Switch/PS4/Xbox', 9.2, 19.99, 'Difficult platformer about climbing a mountain and facing anxiety.'),
('Outer Wilds',                     'Mobius Digital',       'Annapurna Interactive',2019,'PC/PS4/Xbox/Switch', 9.3, 24.99, 'Exploration mystery in a handcrafted solar system stuck in a loop.'),
('Slay the Spire',                  'MegaCrit',             'MegaCrit',            2019, 'PC/Switch/PS4/Xbox', 9.0, 24.99, 'Roguelike deck-builder with endless strategic depth.'),
('Sekiro: Shadows Die Twice',       'FromSoftware',         'Activision',          2019, 'PC/PS4/Xbox',        9.2, 59.99, 'Precise parry-focused action in feudal Japan.'),
('Bloodborne',                      'FromSoftware',         'Sony',                2015, 'PS4',                9.5, 19.99, 'Gothic horror action-RPG set in the cursed city of Yharnam.'),
('Death Stranding',                 'Kojima Productions',   'Sony',                2019, 'PC/PS4',             8.3, 39.99, 'Post-apocalyptic delivery game connecting a fractured America.'),
('Ghost of Tsushima',               'Sucker Punch',         'Sony',                2020, 'PS4/PS5',            9.0, 59.99, 'Open-world samurai adventure in feudal Japan.'),
('Fallout: New Vegas',              'Obsidian Entertainment','Bethesda',           2010, 'PC/PS3/Xbox',        9.2, 9.99,  'Post-apocalyptic RPG with choice-driven narrative in the Mojave.'),
('Baldur''s Gate 3',                'Larian Studios',       'Larian Studios',      2023, 'PC/PS5',             9.8, 59.99, 'Deep D&D RPG with unparalleled player freedom.'),
('Resident Evil Village',           'Capcom',               'Capcom',              2021, 'PC/PS5/Xbox',        9.0, 39.99, 'Gothic horror survival game with Lady Dimitrescu.'),
('Hitman 3',                        'IO Interactive',       'IO Interactive',      2021, 'PC/PS5/Xbox/Switch', 9.0, 59.99, 'Stylish stealth assassination sandbox.'),
('Deathloop',                       'Arkane Studios',       'Bethesda',            2021, 'PC/PS5/Xbox',        8.7, 39.99, 'Stylish time-loop shooter on a dangerous island.'),
('Returnal',                        'Housemarque',          'Sony',                2021, 'PS5/PC',             9.0, 59.99, 'Brutal third-person roguelike shooter on an alien planet.'),
('It Takes Two',                    'Hazelight Studios',    'EA',                  2021, 'PC/PS/Xbox/Switch',  9.4, 39.99, 'Co-op platformer about a couple trying to save their marriage.'),
('Cuphead',                         'Studio MDHR',          'Studio MDHR',         2017, 'PC/Xbox/PS4/Switch', 9.0, 19.99, '1930s cartoon-style run-and-gun with brutal boss fights.'),
('Ori and the Will of the Wisps',   'Moon Studios',         'Xbox Game Studios',   2020, 'PC/Xbox/Switch',     9.5, 29.99, 'Beautiful Metroidvania with emotional storytelling.'),
('INSIDE',                          'Playdead',             'Playdead',            2016, 'PC/PS4/Xbox/Switch', 9.2, 19.99, 'Dark cinematic puzzle-platformer from the makers of LIMBO.'),

-- 41-60
('Subnautica',                      'Unknown Worlds',       'Unknown Worlds',      2018, 'PC/PS4/Xbox/Switch', 9.1, 29.99, 'Underwater open-world survival and exploration.'),
('No Man''s Sky',                   'Hello Games',          'Hello Games',         2016, 'PC/PS/Xbox/Switch',  8.6, 59.99, 'Procedurally generated space exploration sandbox.'),
('Deep Rock Galactic',              'Ghost Ship Games',     'Coffee Stain',        2020, 'PC/PS/Xbox',         9.3, 29.99, 'Co-op first-person mining shooter on alien planets.'),
('Risk of Rain 2',                  'Hopoo Games',          'Gearbox Publishing',  2020, 'PC/PS4/Xbox/Switch', 9.0, 24.99, 'Third-person roguelike shooter with insane item stacking.'),
('Terraria',                        'Re-Logic',             'Re-Logic',            2011, 'PC/Consoles/Mobile', 9.5, 9.99,  '2D sandbox adventure with deep crafting and exploration.'),
('Dead Cells',                      'Motion Twin',          'Motion Twin',         2018, 'PC/Switch/PS4/Xbox', 9.2, 24.99, 'Roguelike Metroidvania with tight combat.'),
('Hollow Knight: Silksong',         'Team Cherry',          'Team Cherry',         2024, 'PC/Switch',          9.0, 19.99, 'Sequel to Hollow Knight following Hornet.'),
('Spiritfarer',                     'Thunder Lotus Games',  'Thunder Lotus',       2020, 'PC/Switch/PS4/Xbox', 9.0, 29.99, 'Cozy management game about ferrying spirits to the afterlife.'),
('LIMBO',                           'Playdead',             'Playdead',            2010, 'PC/PS3/Xbox/Switch', 8.8, 9.99,  'Atmospheric puzzle-platformer in a dark monochrome world.'),
('What Remains of Edith Finch',     'Giant Sparrow',        'Annapurna Interactive',2017,'PC/PS4/Xbox/Switch', 9.0, 19.99, 'Powerful narrative game exploring a family''s unusual deaths.'),
('Journey',                         'thatgamecompany',      'Sony',                2012, 'PS3/PS4/PC',         9.0, 14.99, 'Short, wordless adventure through ancient ruins.'),
('Valheim',                         'Iron Gate',            'Coffee Stain',        2021, 'PC/Xbox',            9.0, 20.99, 'Viking survival and crafting in a procedurally generated world.'),
('Factorio',                        'Wube Software',        'Wube Software',       2020, 'PC',                 9.6, 35.00, 'Complex factory-building strategy game on an alien planet.'),
('Dwarf Fortress',                  'Bay 12 Games',         'Kitfox Games',        2022, 'PC',                 9.0, 29.99, 'Notoriously deep colony simulation with ASCII roots.'),
('RimWorld',                        'Ludeon Studios',       'Ludeon Studios',      2018, 'PC',                 9.5, 34.99, 'Sci-fi colony management with AI storytellers.'),
('Satisfactory',                    'Coffee Stain Studios', 'Coffee Stain',        2020, 'PC',                 9.1, 29.99, 'First-person factory-building on an alien world.'),
('Planet Zoo',                      'Frontier Developments','Frontier',            2019, 'PC',                 8.8, 44.99, 'Detailed zoo management and construction simulator.'),
('Cities: Skylines',                'Colossal Order',       'Paradox Interactive', 2015, 'PC/PS4/Xbox/Switch', 9.0, 29.99, 'Modern take on the city-builder genre.'),
('Total War: Warhammer III',        'Creative Assembly',    'Sega',                2022, 'PC',                 9.0, 59.99, 'Grand strategy meets real-time battles in the Warhammer universe.'),
('Civilization VI',                 'Firaxis Games',        '2K Games',            2016, 'PC/Switch/PS4/Xbox', 9.0, 59.99, 'Turn-based strategy guiding a civilization from ancient times.'),

-- 61-80
('StarCraft II',                    'Blizzard',             'Blizzard',            2010, 'PC',                 9.0, 0.00,  'Premier real-time strategy game with e-sports legacy.'),
('Age of Empires IV',               'Relic Entertainment',  'Xbox Game Studios',   2021, 'PC',                 8.7, 49.99, 'Real-time strategy spanning multiple historical ages.'),
('XCOM 2',                          'Firaxis Games',        '2K Games',            2016, 'PC/PS4/Xbox/Switch', 9.0, 29.99, 'Turn-based tactical squad combat against alien invaders.'),
('Into the Breach',                 'Subset Games',         'Subset Games',        2018, 'PC/Switch',          9.0, 14.99, 'Perfect turn-based tactics in a tiny package.'),
('Invisible, Inc.',                 'Klei Entertainment',   'Klei Entertainment',  2015, 'PC/PS4',             8.7, 19.99, 'Turn-based stealth tactics in a corporate dystopia.'),
('Halo: The Master Chief Coll.',    '343 Industries',       'Xbox Game Studios',   2019, 'PC/Xbox',            9.0, 39.99, 'Remastered collection of iconic sci-fi shooters.'),
('Call of Duty: Modern Warfare II', 'Infinity Ward',        'Activision',          2022, 'PC/PS5/Xbox',        8.5, 69.99, 'Blockbuster military shooter with massive online modes.'),
('Titanfall 2',                     'Respawn Entertainment','EA',                  2016, 'PC/PS4/Xbox',        9.2, 19.99, 'Fast-paced shooter with mechs and incredible single-player.'),
('Apex Legends',                    'Respawn Entertainment','EA',                  2019, 'PC/PS/Xbox/Switch',  9.0, 0.00,  'Free-to-play battle royale with Titanfall movement.'),
('Overwatch 2',                     'Blizzard',             'Blizzard',            2022, 'PC/PS/Xbox/Switch',  7.8, 0.00,  'Hero-based team shooter, sequel to Overwatch.'),
('Valorant',                        'Riot Games',           'Riot Games',          2020, 'PC',                 8.5, 0.00,  'Tactical hero shooter from the makers of League of Legends.'),
('Counter-Strike 2',                'Valve',                'Valve',               2023, 'PC',                 8.8, 0.00,  'Updated version of the legendary tactical FPS.'),
('Dota 2',                          'Valve',                'Valve',               2013, 'PC',                 8.5, 0.00,  'Deep multiplayer online battle arena with 100+ heroes.'),
('League of Legends',               'Riot Games',           'Riot Games',          2009, 'PC',                 8.2, 0.00,  'The world''s most-played MOBA.'),
('Among Us',                        'Innersloth',           'Innersloth',          2018, 'PC/Mobile/Switch',   8.3, 4.99,  'Social deduction party game of crewmates vs. impostors.'),
('Phasmophobia',                    'Kinetic Games',        'Kinetic Games',       2020, 'PC',                 8.5, 13.99, 'Co-op paranormal investigation horror game.'),
('Left 4 Dead 2',                   'Valve',                'Valve',               2009, 'PC/Xbox',            9.1, 9.99,  'Cooperative zombie survival shooter.'),
('Back 4 Blood',                    'Turtle Rock Studios',  'WB Games',            2021, 'PC/PS/Xbox',         7.8, 39.99, 'Spiritual successor to Left 4 Dead with card system.'),
('Dying Light 2',                   'Techland',             'Techland',            2022, 'PC/PS5/Xbox/Switch', 8.2, 59.99, 'Parkour zombie survival in a post-apocalyptic city.'),
('The Last of Us Part I',           'Naughty Dog',          'Sony',                2022, 'PS5/PC',             9.5, 69.99, 'Remade masterpiece of post-apocalyptic storytelling.'),

-- 81-100
('The Last of Us Part II',          'Naughty Dog',          'Sony',                2020, 'PS4/PS5',            9.3, 59.99, 'Brutal emotional sequel continuing Ellie''s journey.'),
('Uncharted 4',                     'Naughty Dog',          'Sony',                2016, 'PS4/PS5/PC',         9.1, 49.99, 'Cinematic adventure game following Nathan Drake.'),
('Spider-Man (2018)',                'Insomniac Games',      'Sony',                2018, 'PS4/PS5',            9.2, 39.99, 'Superhero open-world action with thrilling web-swinging.'),
('Spider-Man: Miles Morales',       'Insomniac Games',      'Sony',                2020, 'PS5/PS4/PC',         9.0, 49.99, 'Standalone expansion starring the second Spider-Man.'),
('Horizon Zero Dawn',               'Guerrilla Games',      'Sony',                2017, 'PS4/PC',             8.8, 29.99, 'Post-apocalyptic RPG hunting robotic dinosaurs.'),
('Horizon Forbidden West',          'Guerrilla Games',      'Sony',                2022, 'PS5/PS4/PC',         9.0, 69.99, 'Sequel expanding the world of machine-filled wilderness.'),
('Ratchet & Clank: Rift Apart',     'Insomniac Games',      'Sony',                2021, 'PS5/PC',             9.0, 69.99, 'Dimension-hopping platformer showcasing PS5 tech.'),
('Astro''s Playroom',               'Team Asobi',           'Sony',                2020, 'PS5',                9.0, 0.00,  'Delightful PS5 tech demo and celebration of PlayStation history.'),
('Demon''s Souls (Remake)',         'Bluepoint Games',      'Sony',                2020, 'PS5',                9.0, 69.99, 'Stunning remake of FromSoftware''s legendary RPG.'),
('Final Fantasy XVI',               'Square Enix',          'Square Enix',         2023, 'PS5/PC',             8.7, 69.99, 'Action-focused mainline Final Fantasy in a dark medieval world.'),
('Final Fantasy XIV',               'Square Enix',          'Square Enix',         2013, 'PC/PS5',             9.2, 39.99, 'MMORPG with acclaimed story expansions including Endwalker.'),
('Nier: Automata',                  'PlatinumGames',        'Square Enix',         2017, 'PC/PS4/Xbox/Switch', 9.3, 29.99, 'Philosophical action-RPG starring android warriors.'),
('Ghostwire: Tokyo',                'Tango Gameworks',      'Bethesda',            2022, 'PC/PS5/Xbox',        8.2, 39.99, 'Action-adventure clearing Tokyo of supernatural spirits.'),
('Hi-Fi Rush',                      'Tango Gameworks',      'Bethesda',            2023, 'PC/Xbox/PS5',        9.0, 29.99, 'Rhythm action game with a killer soundtrack.'),
('Tunic',                           'Andrew Shouldice',     'Finji',               2022, 'PC/Xbox/Switch/PS',  9.0, 29.99, 'Charming isometric adventure inspired by Zelda and Dark Souls.'),
('Sifu',                            'Sloclap',              'Sloclap',             2022, 'PC/PS5/PS4/Switch',  8.8, 39.99, 'Martial arts brawler where you age each time you die.'),
('Ghostrunner',                     'One More Level',       '505 Games',           2020, 'PC/PS5/Xbox/Switch', 8.8, 29.99, 'Hardcore first-person slasher in a cyberpunk tower.'),
('Katana ZERO',                     'Askiisoft',            'Devolver Digital',    2019, 'PC/Switch',          9.0, 14.99, 'Stylish neo-noir action platformer with time manipulation.'),
('Hotline Miami',                   'Dennaton Games',       'Devolver Digital',    2012, 'PC/PS3/PS4/Switch',  9.0, 9.99,  'Brutal top-down action game drenched in neon.'),
('Neon White',                      'Angel Matrix',         'Annapurna Interactive',2022,'PC/Switch',          9.2, 24.99, 'Speed-running card shooter in a vivid heavenly world.'),

-- 101-120
('Dredge',                          'Black Salt Games',     'Team17',              2023, 'PC/Switch/PS/Xbox',  8.8, 24.99, 'Fishing adventure with dark, Lovecraftian undertones.'),
('Dave the Diver',                  'Mintrocket',           'Nexon',               2023, 'PC/Switch',          9.0, 19.99, 'Dive for fish by day, run a sushi restaurant by night.'),
('Cocoon',                          'Geometric Interactive','Annapurna Interactive',2023,'PC/Switch/PS/Xbox',  9.0, 24.99, 'Mind-bending puzzle game about worlds within worlds.'),
('Jusant',                          'DON''T NOD',           'DON''T NOD',          2023, 'PC/PS5/Xbox',        8.5, 24.99, 'Meditative climbing game up a mysterious tall tower.'),
('Sea of Stars',                    'Sabotage Studio',      'Sabotage Studio',     2023, 'PC/Switch/PS/Xbox',  9.0, 34.99, 'Turn-based RPG homage to classic 16-bit JRPGs.'),
('Chained Echoes',                  'Matthias Linda',       'Deck13',              2022, 'PC/Switch/PS/Xbox',  9.0, 24.99, 'Indie JRPG inspired by Final Fantasy VI and Chrono Trigger.'),
('Cassette Beasts',                 'Bytten Studio',        'Raw Fury',            2023, 'PC/Switch/Xbox',     8.8, 19.99, 'Monster-collecting RPG with fusion mechanics.'),
('Tinykin',                         'Splashteam',           'tinyBuild',           2022, 'PC/Switch/PS/Xbox',  8.7, 19.99, 'Colorful Pikmin-like platformer in a house full of tiny bugs.'),
('A Short Hike',                    'adamgryu',             'adamgryu',            2019, 'PC/Switch',          9.2, 7.99,  'Cozy 30-minute hike to a mountain peak.'),
('Unpacking',                       'Witch Beam',           'Humble Games',        2021, 'PC/Switch/PS/Xbox',  8.8, 19.99, 'Zen puzzle game about unpacking boxes and telling a story.'),
('Venba',                           'Visai Games',          'Visai Games',         2023, 'PC/Switch/PS/Xbox',  8.5, 14.99, 'Cooking game about a family''s cultural identity.'),
('Citizen Sleeper',                 'Jump Over the Age',    'Fellow Traveller',    2022, 'PC/Switch/PS/Xbox',  9.0, 19.99, 'Tabletop-inspired RPG about survival and belonging.'),
('Pentiment',                       'Obsidian Entertainment','Xbox Game Studios',  2022, 'PC/Xbox',            9.0, 19.99, 'Historical narrative adventure in 16th-century Bavaria.'),
('As Dusk Falls',                   'Interior Night',       'Xbox Game Studios',   2022, 'PC/Xbox',            8.3, 29.99, 'Interactive drama spanning two families over 30 years.'),
('The Forgotten City',              'Modern Storyteller',   'Dear Villagers',      2021, 'PC/PS/Xbox/Switch',  9.0, 24.99, 'Mystery RPG in an ancient Roman city stuck in a time loop.'),
('Heaven''s Vault',                 'Inkle',                'Inkle',               2019, 'PC/PS4/Switch',      8.2, 19.99, 'Narrative adventure about deciphering a lost language.'),
('Spiritfall',                      'Gentle Giant',         'Gentle Giant',        2023, 'PC',                 8.3, 14.99, 'Roguelike platform fighter with fast blessings system.'),
('Void Stranger',                   'System Erasure',       'Playism',             2023, 'PC',                 8.5, 14.99, 'Cryptic puzzle game full of secrets and mystery.'),
('Pizza Tower',                     'Tour De Pizza',        'Tour De Pizza',       2023, 'PC',                 9.2, 11.99, 'Frantic Wario Land-inspired platformer with insane speed.'),
('Bomb Rush Cyberfunk',             'Team Reptile',         'Team Reptile',        2023, 'PC/Switch/PS/Xbox',  8.5, 29.99, 'Jet Set Radio spiritual successor with graffiti and flow.'),

-- 121-140
('Lies of P',                       'Round8 Studio',        'Neowiz',              2023, 'PC/PS5/Xbox',        8.8, 59.99, 'Souls-like retelling of Pinocchio set in a dark Belle Époque city.'),
('Lords of the Fallen (2023)',      'Hexworks',             'CI Games',            2023, 'PC/PS5/Xbox',        8.2, 59.99, 'Souls-like dual-world action RPG.'),
('Star Wars Jedi: Survivor',        'Respawn Entertainment','EA',                  2023, 'PC/PS5/Xbox',        9.0, 69.99, 'Cal Kestis continues his journey as a Jedi on the run.'),
('Armored Core VI',                 'FromSoftware',         'Bandai Namco',        2023, 'PC/PS5/Xbox',        8.9, 59.99, 'FromSoftware''s return to their mech franchise.'),
('Alan Wake 2',                     'Remedy Entertainment', '505 Games',           2023, 'PC/PS5/Xbox',        9.0, 59.99, 'Psychological horror sequel blending reality and fiction.'),
('Robocop: Rogue City',             'Teyon',                'Nacon',               2023, 'PC/PS5/Xbox',        8.2, 49.99, 'Faithful action game set in the RoboCop universe.'),
('Remnant 2',                       'Gunfire Games',        'Gearbox Publishing',  2023, 'PC/PS5/Xbox',        8.7, 49.99, 'Co-op third-person shooter in procedural worlds.'),
('Street Fighter 6',                'Capcom',               'Capcom',              2023, 'PC/PS5/Xbox',        9.2, 59.99, 'Revitalized fighting game with deep mechanics and World Tour.'),
('Mortal Kombat 1',                 'NetherRealm Studios',  'WB Games',            2023, 'PC/PS5/Xbox/Switch', 8.5, 69.99, 'Timeline-resetting relaunch of the MK franchise.'),
('Tekken 8',                        'Bandai Namco',         'Bandai Namco',        2024, 'PC/PS5/Xbox',        9.0, 69.99, 'Polished next entry in the legendary 3D fighting series.'),
('Palworld',                        'Pocketpair',           'Pocketpair',          2024, 'PC/Xbox',            8.0, 29.99, 'Open-world survival crafting game with creature-collecting.'),
('Helldivers 2',                    'Arrowhead Studios',    'Sony',                2024, 'PC/PS5',             9.2, 39.99, 'Co-op third-person shooter fighting for Super Earth.'),
('Prince of Persia: The Lost Crown','Ubisoft Montpellier',  'Ubisoft',             2024, 'PC/PS/Xbox/Switch',  9.0, 49.99, 'Superb 2D Metroidvania rebooting the Prince of Persia series.'),
('Like a Dragon: Infinite Wealth',  'Ryu Ga Gotoku Studio', 'Sega',                2024, 'PC/PS5/Xbox',        9.3, 69.99, 'Ichiban Kasuga travels to Hawaii in this huge JRPG sequel.'),
('Metaphor: ReFantazio',            'Atlus',                'Sega',                2024, 'PC/PS5/Xbox',        9.5, 59.99, 'New fantasy RPG from the director of Persona 5.'),
('Final Fantasy VII Rebirth',       'Square Enix',          'Square Enix',         2024, 'PS5/PC',             9.4, 69.99, 'Second part of the FFVII remake trilogy.'),
('Astro Bot',                       'Team Asobi',           'Sony',                2024, 'PS5',                9.5, 59.99, 'Game of the Year 2024 — joyful 3D platformer.'),
('Silent Hill 2 (Remake)',          'Bloober Team',         'Konami',              2024, 'PC/PS5',             9.0, 59.99, 'Faithful and expanded remake of the survival horror classic.'),
('Warhammer 40,000: Space Marine 2','Saber Interactive',    'Focus Entertainment',2024, 'PC/PS5/Xbox',        9.0, 49.99, 'Epic 40K action with co-op Exterminatus missions.'),
('UFO 50',                          'Mossmouth',            'Mossmouth',           2024, 'PC',                 9.0, 24.99, 'Collection of 50 complete retro games from a fictional studio.');

-- ============================================================
--  GAME ↔ GENRES  (many-to-many)
-- ============================================================
CREATE TABLE game_genres (
    game_id     INT REFERENCES games(id) ON DELETE CASCADE,
    genre_id    INT REFERENCES genres(id) ON DELETE CASCADE,
    PRIMARY KEY (game_id, genre_id)
);

INSERT INTO game_genres (game_id, genre_id)
SELECT g.id, gn.id FROM games g, genres gn WHERE
    (g.title = 'The Witcher 3: Wild Hunt'           AND gn.name IN ('RPG','Action','Adventure')) OR
    (g.title = 'Red Dead Redemption 2'               AND gn.name IN ('Action','Adventure')) OR
    (g.title = 'The Legend of Zelda: BotW'           AND gn.name IN ('Action','Adventure')) OR
    (g.title = 'Dark Souls III'                      AND gn.name IN ('Action','RPG')) OR
    (g.title = 'God of War (2018)'                   AND gn.name IN ('Action','Adventure')) OR
    (g.title = 'Elden Ring'                          AND gn.name IN ('Action','RPG')) OR
    (g.title = 'Hollow Knight'                       AND gn.name IN ('Action','Adventure','Metroidvania')) OR
    (g.title = 'Persona 5 Royal'                     AND gn.name IN ('RPG')) OR
    (g.title = 'Hades'                               AND gn.name IN ('Action','Roguelike')) OR
    (g.title = 'Cyberpunk 2077'                      AND gn.name IN ('Action','RPG')) OR
    (g.title = 'Grand Theft Auto V'                  AND gn.name IN ('Action','Adventure')) OR
    (g.title = 'Minecraft'                           AND gn.name IN ('Sandbox','Survival','Adventure')) OR
    (g.title = 'Portal 2'                            AND gn.name IN ('Puzzle','Action')) OR
    (g.title = 'Disco Elysium'                       AND gn.name IN ('RPG','Adventure')) OR
    (g.title = 'Divinity: Original Sin 2'            AND gn.name IN ('RPG','Strategy')) OR
    (g.title = 'Monster Hunter: World'               AND gn.name IN ('Action','RPG')) OR
    (g.title = 'Doom Eternal'                        AND gn.name IN ('Action','Shooter')) OR
    (g.title = 'Mass Effect Legendary Edition'       AND gn.name IN ('RPG','Action','Shooter')) OR
    (g.title = 'Stardew Valley'                      AND gn.name IN ('Simulation','RPG')) OR
    (g.title = 'Undertale'                           AND gn.name IN ('RPG','Adventure')) OR
    (g.title = 'Celeste'                             AND gn.name IN ('Platformer','Action')) OR
    (g.title = 'Outer Wilds'                         AND gn.name IN ('Adventure','Exploration')) OR
    (g.title = 'Slay the Spire'                      AND gn.name IN ('Roguelike','Strategy')) OR
    (g.title = 'Bloodborne'                          AND gn.name IN ('Action','RPG','Horror')) OR
    (g.title = 'Ghost of Tsushima'                   AND gn.name IN ('Action','Adventure','Stealth')) OR
    (g.title = 'Fallout: New Vegas'                  AND gn.name IN ('RPG','Action')) OR
    (g.title = 'Baldur''s Gate 3'                   AND gn.name IN ('RPG','Strategy','Adventure')) OR
    (g.title = 'Resident Evil Village'               AND gn.name IN ('Horror','Action','Survival')) OR
    (g.title = 'Hitman 3'                            AND gn.name IN ('Action','Stealth')) OR
    (g.title = 'It Takes Two'                        AND gn.name IN ('Platformer','Adventure')) OR
    (g.title = 'Cuphead'                             AND gn.name IN ('Action','Platformer')) OR
    (g.title = 'Ori and the Will of the Wisps'       AND gn.name IN ('Platformer','Metroidvania','Action')) OR
    (g.title = 'Subnautica'                          AND gn.name IN ('Survival','Adventure','Sandbox')) OR
    (g.title = 'No Man''s Sky'                      AND gn.name IN ('Survival','Adventure','Sandbox')) OR
    (g.title = 'Deep Rock Galactic'                  AND gn.name IN ('Action','Shooter')) OR
    (g.title = 'Risk of Rain 2'                      AND gn.name IN ('Action','Roguelike','Shooter')) OR
    (g.title = 'Terraria'                            AND gn.name IN ('Sandbox','Adventure','Action')) OR
    (g.title = 'Dead Cells'                          AND gn.name IN ('Action','Roguelike','Metroidvania')) OR
    (g.title = 'Valheim'                             AND gn.name IN ('Survival','Sandbox','Action')) OR
    (g.title = 'Factorio'                            AND gn.name IN ('Strategy','Simulation','Sandbox')) OR
    (g.title = 'RimWorld'                            AND gn.name IN ('Strategy','Simulation','Survival')) OR
    (g.title = 'Satisfactory'                        AND gn.name IN ('Simulation','Sandbox')) OR
    (g.title = 'Cities: Skylines'                    AND gn.name IN ('Strategy','Simulation')) OR
    (g.title = 'Total War: Warhammer III'             AND gn.name IN ('Strategy','Action')) OR
    (g.title = 'Civilization VI'                     AND gn.name IN ('Strategy')) OR
    (g.title = 'StarCraft II'                        AND gn.name IN ('Strategy')) OR
    (g.title = 'XCOM 2'                              AND gn.name IN ('Strategy','Action')) OR
    (g.title = 'Halo: The Master Chief Coll.'        AND gn.name IN ('Shooter','Action')) OR
    (g.title = 'Titanfall 2'                         AND gn.name IN ('Shooter','Action')) OR
    (g.title = 'Apex Legends'                        AND gn.name IN ('Shooter','Battle Royale')) OR
    (g.title = 'Overwatch 2'                         AND gn.name IN ('Shooter','Action')) OR
    (g.title = 'Valorant'                            AND gn.name IN ('Shooter','Action')) OR
    (g.title = 'Counter-Strike 2'                    AND gn.name IN ('Shooter','Action')) OR
    (g.title = 'Dota 2'                              AND gn.name IN ('Strategy')) OR
    (g.title = 'Among Us'                            AND gn.name IN ('Adventure')) OR
    (g.title = 'Phasmophobia'                        AND gn.name IN ('Horror','Adventure')) OR
    (g.title = 'Left 4 Dead 2'                       AND gn.name IN ('Shooter','Horror','Action')) OR
    (g.title = 'Dying Light 2'                       AND gn.name IN ('Action','Horror','Survival')) OR
    (g.title = 'The Last of Us Part I'               AND gn.name IN ('Action','Adventure','Horror','Survival')) OR
    (g.title = 'The Last of Us Part II'              AND gn.name IN ('Action','Adventure','Horror','Survival')) OR
    (g.title = 'Nier: Automata'                      AND gn.name IN ('Action','RPG')) OR
    (g.title = 'Hi-Fi Rush'                          AND gn.name IN ('Action')) OR
    (g.title = 'Sea of Stars'                        AND gn.name IN ('RPG','Adventure')) OR
    (g.title = 'Lies of P'                           AND gn.name IN ('Action','RPG')) OR
    (g.title = 'Star Wars Jedi: Survivor'            AND gn.name IN ('Action','Adventure')) OR
    (g.title = 'Armored Core VI'                     AND gn.name IN ('Action','Shooter')) OR
    (g.title = 'Alan Wake 2'                         AND gn.name IN ('Action','Horror','Adventure')) OR
    (g.title = 'Street Fighter 6'                    AND gn.name IN ('Fighting')) OR
    (g.title = 'Mortal Kombat 1'                     AND gn.name IN ('Fighting')) OR
    (g.title = 'Tekken 8'                            AND gn.name IN ('Fighting')) OR
    (g.title = 'Palworld'                            AND gn.name IN ('Survival','Sandbox','Action')) OR
    (g.title = 'Helldivers 2'                        AND gn.name IN ('Shooter','Action')) OR
    (g.title = 'Like a Dragon: Infinite Wealth'      AND gn.name IN ('RPG','Action')) OR
    (g.title = 'Metaphor: ReFantazio'                AND gn.name IN ('RPG','Adventure')) OR
    (g.title = 'Final Fantasy VII Rebirth'           AND gn.name IN ('RPG','Action')) OR
    (g.title = 'Astro Bot'                           AND gn.name IN ('Platformer','Action')) OR
    (g.title = 'Silent Hill 2 (Remake)'              AND gn.name IN ('Horror','Survival','Adventure')) OR
    (g.title = 'Final Fantasy XIV'                   AND gn.name IN ('MMORPG','RPG')) OR
    (g.title = 'Pizza Tower'                         AND gn.name IN ('Platformer','Action')) OR
    (g.title = 'Hades'                               AND gn.name IN ('Action')) OR
    (g.title = 'Katana ZERO'                         AND gn.name IN ('Action','Platformer')) OR
    (g.title = 'Hotline Miami'                       AND gn.name IN ('Action')) OR
    (g.title = 'Ghostrunner'                         AND gn.name IN ('Action','Platformer')) OR
    (g.title = 'Sifu'                                AND gn.name IN ('Action','Fighting')) OR
    (g.title = 'Prince of Persia: The Lost Crown'    AND gn.name IN ('Action','Metroidvania','Platformer')) OR
    (g.title = 'Neon White'                          AND gn.name IN ('Action','Platformer')) OR
    (g.title = 'Dredge'                              AND gn.name IN ('Adventure','Simulation')) OR
    (g.title = 'Dave the Diver'                      AND gn.name IN ('Adventure','Simulation','RPG')) OR
    (g.title = 'Pentiment'                           AND gn.name IN ('Adventure','RPG')) OR
    (g.title = 'Astro''s Playroom'                  AND gn.name IN ('Platformer','Action')) OR
    (g.title = 'Bomb Rush Cyberfunk'                 AND gn.name IN ('Action','Adventure')) OR
    (g.title = 'UFO 50'                              AND gn.name IN ('Action','Platformer','Adventure'));

-- ============================================================
--  GAME ↔ TAGS  (many-to-many)
-- ============================================================
CREATE TABLE game_tags (
    game_id     INT REFERENCES games(id) ON DELETE CASCADE,
    tag_id      INT REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (game_id, tag_id)
);

INSERT INTO game_tags (game_id, tag_id)
SELECT g.id, t.id FROM games g, tags t WHERE
    (g.title = 'The Witcher 3: Wild Hunt'           AND t.name IN ('Open World','Story Rich','Fantasy','Single Player')) OR
    (g.title = 'Red Dead Redemption 2'               AND t.name IN ('Open World','Story Rich','Single Player','Historical')) OR
    (g.title = 'The Legend of Zelda: BotW'           AND t.name IN ('Open World','Exploration','Fantasy','Single Player')) OR
    (g.title = 'Dark Souls III'                      AND t.name IN ('Difficult','Dark Themes','Fantasy','Single Player','Loot')) OR
    (g.title = 'God of War (2018)'                   AND t.name IN ('Story Rich','Mythological','Single Player','3D')) OR
    (g.title = 'Elden Ring'                          AND t.name IN ('Open World','Difficult','Fantasy','Dark Themes','Exploration')) OR
    (g.title = 'Hollow Knight'                       AND t.name IN ('Difficult','Atmospheric','2D','Exploration')) OR
    (g.title = 'Persona 5 Royal'                     AND t.name IN ('Story Rich','Turn-Based','Anime','Single Player')) OR
    (g.title = 'Hades'                               AND t.name IN ('Procedural Generation','Difficult','Story Rich','Single Player','Loot')) OR
    (g.title = 'Cyberpunk 2077'                      AND t.name IN ('Open World','Cyberpunk','Story Rich','Single Player')) OR
    (g.title = 'Grand Theft Auto V'                  AND t.name IN ('Open World','Multiplayer','Single Player','3D')) OR
    (g.title = 'Minecraft'                           AND t.name IN ('Sandbox','Crafting','Multiplayer','Procedural Generation')) OR
    (g.title = 'Portal 2'                            AND t.name IN ('Story Rich','Co-op','Single Player','Humor','3D')) OR
    (g.title = 'Disco Elysium'                       AND t.name IN ('Story Rich','Single Player','Dark Themes','Atmospheric')) OR
    (g.title = 'Divinity: Original Sin 2'            AND t.name IN ('Turn-Based','Co-op','Story Rich','Fantasy')) OR
    (g.title = 'Monster Hunter: World'               AND t.name IN ('Co-op','Multiplayer','Loot','Exploration')) OR
    (g.title = 'Doom Eternal'                        AND t.name IN ('Single Player','Difficult','3D')) OR
    (g.title = 'Mass Effect Legendary Edition'       AND t.name IN ('Story Rich','Sci-Fi','Single Player','3D')) OR
    (g.title = 'Stardew Valley'                      AND t.name IN ('Relaxing','Single Player','Pixel Art','Crafting')) OR
    (g.title = 'Undertale'                           AND t.name IN ('Story Rich','Pixel Art','Single Player','Humor')) OR
    (g.title = 'Celeste'                             AND t.name IN ('Difficult','Story Rich','Single Player','2D','Pixel Art')) OR
    (g.title = 'Outer Wilds'                         AND t.name IN ('Exploration','Atmospheric','Single Player','Sci-Fi')) OR
    (g.title = 'Slay the Spire'                      AND t.name IN ('Procedural Generation','Single Player','Turn-Based','Difficult')) OR
    (g.title = 'Bloodborne'                          AND t.name IN ('Difficult','Dark Themes','Atmospheric','Single Player')) OR
    (g.title = 'Ghost of Tsushima'                   AND t.name IN ('Open World','Stealth','Story Rich','Single Player','Atmospheric')) OR
    (g.title = 'Fallout: New Vegas'                  AND t.name IN ('Open World','Post-Apocalyptic','Story Rich','Single Player')) OR
    (g.title = 'Baldur''s Gate 3'                   AND t.name IN ('Story Rich','Fantasy','Co-op','Turn-Based')) OR
    (g.title = 'Resident Evil Village'               AND t.name IN ('Horror','Single Player','Dark Themes','3D')) OR
    (g.title = 'Hitman 3'                            AND t.name IN ('Stealth','Single Player','Sandbox','Humor')) OR
    (g.title = 'It Takes Two'                        AND t.name IN ('Co-op','Story Rich','Local Multiplayer')) OR
    (g.title = 'Cuphead'                             AND t.name IN ('Difficult','Co-op','2D','Retro')) OR
    (g.title = 'Ori and the Will of the Wisps'       AND t.name IN ('Atmospheric','2D','Single Player','Story Rich')) OR
    (g.title = 'Subnautica'                          AND t.name IN ('Exploration','Crafting','Single Player','Atmospheric')) OR
    (g.title = 'No Man''s Sky'                      AND t.name IN ('Exploration','Crafting','Multiplayer','Procedural Generation','Space')) OR
    (g.title = 'Deep Rock Galactic'                  AND t.name IN ('Co-op','Multiplayer','Procedural Generation','Humor')) OR
    (g.title = 'Risk of Rain 2'                      AND t.name IN ('Procedural Generation','Co-op','Loot','Difficult')) OR
    (g.title = 'Terraria'                            AND t.name IN ('2D','Crafting','Exploration','Sandbox','Single Player')) OR
    (g.title = 'Dead Cells'                          AND t.name IN ('Procedural Generation','2D','Difficult','Single Player','Loot')) OR
    (g.title = 'Valheim'                             AND t.name IN ('Crafting','Multiplayer','Exploration','Co-op')) OR
    (g.title = 'Factorio'                            AND t.name IN ('Multiplayer','Single Player','Difficult','Relaxing')) OR
    (g.title = 'RimWorld'                            AND t.name IN ('Procedural Generation','Sci-Fi','Single Player','Dark Themes','Story Rich')) OR
    (g.title = 'Cities: Skylines'                    AND t.name IN ('Relaxing','Single Player','Sandbox','3D')) OR
    (g.title = 'Total War: Warhammer III'             AND t.name IN ('Fantasy','Turn-Based','Real-Time','Multiplayer','3D')) OR
    (g.title = 'Civilization VI'                     AND t.name IN ('Turn-Based','Multiplayer','Historical','Single Player')) OR
    (g.title = 'StarCraft II'                        AND t.name IN ('Real-Time','Competitive','Online','Multiplayer')) OR
    (g.title = 'XCOM 2'                              AND t.name IN ('Turn-Based','Difficult','Sci-Fi','Single Player')) OR
    (g.title = 'Halo: The Master Chief Coll.'        AND t.name IN ('Co-op','Multiplayer','Sci-Fi','3D','Story Rich')) OR
    (g.title = 'Titanfall 2'                         AND t.name IN ('Multiplayer','3D','Sci-Fi','Story Rich')) OR
    (g.title = 'Apex Legends'                        AND t.name IN ('Battle Royale','Competitive','Online','Multiplayer')) OR
    (g.title = 'Overwatch 2'                         AND t.name IN ('Competitive','Online','Multiplayer','3D')) OR
    (g.title = 'Valorant'                            AND t.name IN ('Competitive','Online','Multiplayer')) OR
    (g.title = 'Counter-Strike 2'                    AND t.name IN ('Competitive','Online','Multiplayer','Difficult')) OR
    (g.title = 'Dota 2'                              AND t.name IN ('Competitive','Multiplayer','Online','Difficult')) OR
    (g.title = 'Among Us'                            AND t.name IN ('Multiplayer','Online','Local Multiplayer','Casual')) OR
    (g.title = 'Phasmophobia'                        AND t.name IN ('Horror','Co-op','Multiplayer','Atmospheric')) OR
    (g.title = 'Left 4 Dead 2'                       AND t.name IN ('Co-op','Zombies','Multiplayer','3D')) OR
    (g.title = 'Dying Light 2'                       AND t.name IN ('Open World','Zombies','Co-op','Post-Apocalyptic')) OR
    (g.title = 'The Last of Us Part I'               AND t.name IN ('Story Rich','Post-Apocalyptic','Single Player','Atmospheric')) OR
    (g.title = 'The Last of Us Part II'              AND t.name IN ('Story Rich','Post-Apocalyptic','Single Player','Dark Themes')) OR
    (g.title = 'Nier: Automata'                      AND t.name IN ('Story Rich','Robots','Single Player','Atmospheric')) OR
    (g.title = 'Hi-Fi Rush'                          AND t.name IN ('Single Player','Humor','3D','Robots')) OR
    (g.title = 'Sea of Stars'                        AND t.name IN ('Turn-Based','Story Rich','Fantasy','Single Player','Pixel Art','Retro')) OR
    (g.title = 'Lies of P'                           AND t.name IN ('Difficult','Dark Themes','Atmospheric','Single Player','Robots')) OR
    (g.title = 'Star Wars Jedi: Survivor'            AND t.name IN ('Story Rich','Exploration','Single Player','3D')) OR
    (g.title = 'Armored Core VI'                     AND t.name IN ('Difficult','Robots','Single Player','3D')) OR
    (g.title = 'Alan Wake 2'                         AND t.name IN ('Story Rich','Dark Themes','Atmospheric','Single Player')) OR
    (g.title = 'Street Fighter 6'                    AND t.name IN ('Competitive','Multiplayer','Online','3D')) OR
    (g.title = 'Mortal Kombat 1'                     AND t.name IN ('Competitive','Multiplayer','Online','Dark Themes')) OR
    (g.title = 'Tekken 8'                            AND t.name IN ('Competitive','Multiplayer','Online','3D')) OR
    (g.title = 'Palworld'                            AND t.name IN ('Open World','Multiplayer','Crafting','Co-op')) OR
    (g.title = 'Helldivers 2'                        AND t.name IN ('Co-op','Multiplayer','Sci-Fi','Difficult')) OR
    (g.title = 'Like a Dragon: Infinite Wealth'      AND t.name IN ('Story Rich','Humor','Turn-Based','Single Player')) OR
    (g.title = 'Metaphor: ReFantazio'                AND t.name IN ('Story Rich','Fantasy','Turn-Based','Single Player','Atmospheric')) OR
    (g.title = 'Final Fantasy VII Rebirth'           AND t.name IN ('Story Rich','Fantasy','Single Player','3D')) OR
    (g.title = 'Astro Bot'                           AND t.name IN ('Single Player','3D','Casual','Controller Support')) OR
    (g.title = 'Silent Hill 2 (Remake)'              AND t.name IN ('Horror','Atmospheric','Dark Themes','Single Player')) OR
    (g.title = 'Final Fantasy XIV'                   AND t.name IN ('Online','Multiplayer','Fantasy','Story Rich')) OR
    (g.title = 'Pizza Tower'                         AND t.name IN ('2D','Single Player','Difficult','Humor','Retro')) OR
    (g.title = 'Katana ZERO'                         AND t.name IN ('Cyberpunk','Story Rich','2D','Difficult')) OR
    (g.title = 'Hotline Miami'                       AND t.name IN ('Difficult','2D','Dark Themes','Retro')) OR
    (g.title = 'Ghostrunner'                         AND t.name IN ('Cyberpunk','Difficult','Single Player','3D')) OR
    (g.title = 'Sifu'                                AND t.name IN ('Difficult','Single Player','3D')) OR
    (g.title = 'Prince of Persia: The Lost Crown'    AND t.name IN ('2D','Exploration','Single Player','Fantasy')) OR
    (g.title = 'Neon White'                          AND t.name IN ('Difficult','Single Player','Anime','3D')) OR
    (g.title = 'Dredge'                              AND t.name IN ('Atmospheric','Story Rich','Single Player','Dark Themes')) OR
    (g.title = 'Dave the Diver'                      AND t.name IN ('Relaxing','Humor','Single Player','Exploration')) OR
    (g.title = 'Pentiment'                           AND t.name IN ('Story Rich','Historical','Atmospheric','Single Player')) OR
    (g.title = 'Bomb Rush Cyberfunk'                 AND t.name IN ('Single Player','Casual','Humor','3D')) OR
    (g.title = 'UFO 50'                              AND t.name IN ('Retro','Multiplayer','Single Player','Pixel Art','Difficult'));

-- ============================================================
--  USEFUL VIEWS
-- ============================================================

-- Full game listing with genres and tags
DROP VIEW IF EXISTS v_games_full;
CREATE OR REPLACE VIEW v_games_full AS
SELECT
    g.id,
    g.title,
    g.developer,
    g.publisher,
    g.release_year,
    g.platform,
    g.rating,
    g.price_usd,
    g.description,
    STRING_AGG(DISTINCT gn.name, ', ' ORDER BY gn.name) AS genres,
    STRING_AGG(DISTINCT t.name,  ', ' ORDER BY t.name)  AS tags
FROM games g
LEFT JOIN game_genres gg ON g.id = gg.game_id
LEFT JOIN genres gn      ON gg.genre_id = gn.id
LEFT JOIN game_tags  gt  ON g.id = gt.game_id
LEFT JOIN tags t         ON gt.tag_id = t.id
GROUP BY g.id
ORDER BY g.rating DESC, g.title;

-- Top-rated games per genre
CREATE OR REPLACE VIEW v_top_per_genre AS
SELECT DISTINCT ON (gn.name)
    gn.name  AS genre,
    g.title,
    g.rating,
    g.release_year
FROM genres gn
JOIN game_genres gg ON gn.id = gg.genre_id
JOIN games g        ON gg.game_id = g.id
ORDER BY gn.name, g.rating DESC;

-- ============================================================
--  SAMPLE QUERIES (run these to explore the data)
-- ============================================================

-- 1. All games with a specific tag:
--    SELECT title, rating FROM v_games_full WHERE tags LIKE '%Difficult%' ORDER BY rating DESC;

-- 2. All action RPGs:
--    SELECT title, rating FROM v_games_full WHERE genres LIKE '%Action%' AND genres LIKE '%RPG%';

-- 3. Free-to-play games:
--    SELECT title, developer, rating FROM games WHERE price_usd = 0 ORDER BY rating DESC;

-- 4. Best co-op games:
--    SELECT title, rating, genres FROM v_games_full WHERE tags LIKE '%Co-op%' ORDER BY rating DESC;

-- 5. Count of games per genre:
--    SELECT gn.name, COUNT(*) AS game_count
--    FROM genres gn JOIN game_genres gg ON gn.id = gg.game_id
--    GROUP BY gn.name ORDER BY game_count DESC;

-- 6. Games released between two years:
--    SELECT title, release_year, rating FROM games WHERE release_year BETWEEN 2020 AND 2024 ORDER BY rating DESC;

-- ============================================================
--  LOGGING
-- ============================================================
CREATE TABLE IF NOT EXISTS search_log (
    id SERIAL PRIMARY KEY,
    query TEXT NOT NULL,
    result_titles TEXT[],
    searched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
