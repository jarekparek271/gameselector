-- ─────────────────────────────────────────
--  Game Picker DB schema + seed data
-- ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS genres (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(64) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS games (
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(128) UNIQUE NOT NULL,
    genre_id    INTEGER REFERENCES genres(id),
    platform    VARCHAR(32)  NOT NULL,  -- 'PC', 'Console', 'Both'
    release_year SMALLINT,
    description TEXT
);

CREATE TABLE IF NOT EXISTS tags (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(64) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS game_tags (
    game_id INTEGER REFERENCES games(id) ON DELETE CASCADE,
    tag_id  INTEGER REFERENCES tags(id)  ON DELETE CASCADE,
    PRIMARY KEY (game_id, tag_id)
);

CREATE TABLE IF NOT EXISTS search_log (
    id SERIAL PRIMARY KEY,
    query TEXT NOT NULL,
    result_titles TEXT[],
    searched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── Genres ───────────────────────────────
INSERT INTO genres (name) VALUES
    ('RPG'), ('Action'), ('Strategy'), ('Horror'),
    ('Simulation'), ('Platformer'), ('Shooter'), ('Adventure'),
    ('Sports'), ('Fighting'), ('Puzzle'), ('Sandbox')
ON CONFLICT DO NOTHING;

-- ── Tags ─────────────────────────────────
INSERT INTO tags (name) VALUES
    ('open world'), ('story-rich'), ('dark atmosphere'), ('multiplayer'),
    ('co-op'), ('relaxing'), ('difficult'), ('pixel art'),
    ('sci-fi'), ('fantasy'), ('post-apocalyptic'), ('historical'),
    ('stealth'), ('crafting'), ('survival'), ('roguelike'),
    ('turn-based'), ('real-time'), ('moral choices'), ('emotional'),
    ('funny'), ('gore'), ('mystery'), ('exploration'),
    ('base building'), ('city builder'), ('farming'), ('anime'),
    ('psychological'), ('speedrun friendly'), ('controller friendly'),
    ('cozy'), ('competitive'), ('singleplayer'), ('horror'),
    ('first-person'), ('third-person'), ('top-down'), ('2D'), ('3D')
ON CONFLICT DO NOTHING;

-- ── Games + tags ─────────────────────────
-- helper: inserts a game and links its tags by name
-- We use a DO block so this is idempotent on re-run.
DO $$
DECLARE
    gid INTEGER;
BEGIN

-- The Witcher 3
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('The Witcher 3: Wild Hunt',
        (SELECT id FROM genres WHERE name='RPG'), 'Both', 2015,
        'Massive open-world RPG with deep story, moral choices, and stunning visuals.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('open world','story-rich','dark atmosphere','moral choices','fantasy','third-person','3D','singleplayer');
END IF;

-- Elden Ring
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Elden Ring',
        (SELECT id FROM genres WHERE name='Action'), 'Both', 2022,
        'Challenging open-world action RPG from FromSoftware and George R.R. Martin.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('open world','difficult','dark atmosphere','fantasy','exploration','third-person','3D','singleplayer');
END IF;

-- Stardew Valley
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Stardew Valley',
        (SELECT id FROM genres WHERE name='Simulation'), 'Both', 2016,
        'Cozy farming sim where you build a farm, befriend villagers, and explore caves.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('relaxing','cozy','farming','crafting','pixel art','2D','singleplayer','co-op');
END IF;

-- Hollow Knight
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Hollow Knight',
        (SELECT id FROM genres WHERE name='Platformer'), 'Both', 2017,
        'Beautiful and brutal metroidvania set in a vast underground insect kingdom.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('difficult','exploration','dark atmosphere','pixel art','2D','singleplayer','story-rich');
END IF;

-- Resident Evil 4 Remake
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Resident Evil 4 Remake',
        (SELECT id FROM genres WHERE name='Horror'), 'Both', 2023,
        'Reimagining of the classic survival horror game with modern visuals and gameplay.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('horror','gore','third-person','3D','singleplayer','story-rich','dark atmosphere');
END IF;

-- Civilization VI
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Civilization VI',
        (SELECT id FROM genres WHERE name='Strategy'), 'Both', 2016,
        'Turn-based strategy where you build an empire from ancient times to the space age.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('turn-based','historical','base building','top-down','singleplayer','multiplayer');
END IF;

-- Minecraft
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Minecraft',
        (SELECT id FROM genres WHERE name='Sandbox'), 'Both', 2011,
        'Infinite sandbox where you mine, build, craft and survive in procedurally generated worlds.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('crafting','survival','open world','co-op','multiplayer','3D','exploration');
END IF;

-- Hades
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Hades',
        (SELECT id FROM genres WHERE name='Action'), 'Both', 2020,
        'Roguelike dungeon crawler where you fight out of the Underworld with god-like powers.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('roguelike','story-rich','fantasy','top-down','2D','singleplayer','speedrun friendly');
END IF;

-- Red Dead Redemption 2
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Red Dead Redemption 2',
        (SELECT id FROM genres WHERE name='Action'), 'Both', 2018,
        'Cinematic open-world western with an emotional story and stunning world detail.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('open world','story-rich','emotional','historical','third-person','3D','singleplayer','moral choices');
END IF;

-- Portal 2
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Portal 2',
        (SELECT id FROM genres WHERE name='Puzzle'), 'Both', 2011,
        'Brilliant puzzle game with a hilarious story, played solo or in co-op.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('funny','co-op','singleplayer','first-person','3D','story-rich','sci-fi');
END IF;

-- Doom Eternal
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Doom Eternal',
        (SELECT id FROM genres WHERE name='Shooter'), 'Both', 2020,
        'Ultrafast first-person shooter with relentless demon-slaying action.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('difficult','gore','first-person','3D','singleplayer','sci-fi','speedrun friendly','competitive');
END IF;

-- Disco Elysium
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Disco Elysium',
        (SELECT id FROM genres WHERE name='RPG'), 'PC', 2019,
        'Unique detective RPG focused entirely on dialogue, choices and roleplaying a broken cop.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('story-rich','moral choices','mystery','funny','dark atmosphere','top-down','2D','singleplayer');
END IF;

-- Among Us
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Among Us',
        (SELECT id FROM genres WHERE name='Strategy'), 'Both', 2018,
        'Social deduction party game where crewmates try to find the hidden impostors.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('multiplayer','funny','mystery','top-down','2D');
END IF;

-- Cyberpunk 2077
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Cyberpunk 2077',
        (SELECT id FROM genres WHERE name='RPG'), 'Both', 2020,
        'Open-world sci-fi RPG set in a dystopian mega-city with deep story and character builds.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('open world','story-rich','sci-fi','dark atmosphere','first-person','3D','singleplayer','moral choices');
END IF;

-- Terraria
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Terraria',
        (SELECT id FROM genres WHERE name='Sandbox'), 'Both', 2011,
        '2D sandbox game with deep crafting, building, and boss-fighting in procedural worlds.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('crafting','survival','exploration','pixel art','2D','co-op','singleplayer');
END IF;

-- Alien: Isolation
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Alien: Isolation',
        (SELECT id FROM genres WHERE name='Horror'), 'Both', 2014,
        'Tense sci-fi survival horror where you hide from a near-indestructible Alien aboard a space station.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('horror','stealth','sci-fi','first-person','3D','singleplayer','dark atmosphere','psychological');
END IF;

-- Cities: Skylines
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Cities: Skylines',
        (SELECT id FROM genres WHERE name='Strategy'), 'Both', 2015,
        'Deep city-building sim where you design and manage a growing metropolis.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('city builder','relaxing','top-down','3D','singleplayer','base building');
END IF;

-- Celeste
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Celeste',
        (SELECT id FROM genres WHERE name='Platformer'), 'Both', 2018,
        'Precision platformer about climbing a mountain, with a touching story about mental health.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('difficult','emotional','story-rich','pixel art','2D','singleplayer','speedrun friendly');
END IF;

-- Baldur's Gate 3
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Baldur''s Gate 3',
        (SELECT id FROM genres WHERE name='RPG'), 'Both', 2023,
        'Massive D&D-based RPG with deep story, turn-based combat and incredible player freedom.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('turn-based','story-rich','fantasy','moral choices','co-op','3D','singleplayer','exploration');
END IF;

-- Subnautica
INSERT INTO games (title, genre_id, platform, release_year, description)
VALUES ('Subnautica',
        (SELECT id FROM genres WHERE name='Adventure'), 'Both', 2018,
        'Underwater survival game on an alien ocean planet — beautiful, mysterious and terrifying.')
ON CONFLICT (title) DO NOTHING RETURNING id INTO gid;
IF gid IS NOT NULL THEN
    INSERT INTO game_tags (game_id, tag_id) SELECT gid, id FROM tags
    WHERE name IN ('survival','exploration','crafting','sci-fi','first-person','3D','singleplayer','psychological');
END IF;

END $$;
