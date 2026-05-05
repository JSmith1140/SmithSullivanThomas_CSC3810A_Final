DROP DATABASE IF EXISTS MusicPlayer;

CREATE DATABASE MusicPlayer;

USE MusicPlayer;

SET SQL_SAFE_UPDATES = 0;

CREATE TABLE IF NOT EXISTS Song (
	SongId INT NOT NULL AUTO_INCREMENT,
    SongName VARCHAR(100) NOT NULL,
    DurationSeconds INT,
    PRIMARY KEY (SongId)
);

CREATE TABLE IF NOT EXISTS Genre (
	GenreId INT NOT NULL AUTO_INCREMENT,
    GenreName VARCHAR(50) NOT NULL,
    PRIMARY KEY (GenreId),
    CONSTRAINT unique_genre UNIQUE (GenreName)
);

CREATE TABLE IF NOT EXISTS SongGenre (
	SongId INT NOT NULL,
    GenreId INT NOT NULL,
    PRIMARY KEY (SongId, GenreId),
    FOREIGN KEY (GenreId) REFERENCES Genre(GenreId) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (SongId) REFERENCES Song(SongId) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Artist (
	ArtistId INT NOT NULL AUTO_INCREMENT,
    ArtistName VARCHAR(100) NOT NULL,
    PRIMARY KEY (ArtistId)
);

CREATE TABLE IF NOT EXISTS ArtistSong (
	ArtistId INT NOT NULL,
	SongId INT NOT NULL,
    PRIMARY KEY (ArtistId, SongId),
    FOREIGN KEY (ArtistId) REFERENCES Artist(ArtistId) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (SongId) REFERENCES Song(SongId) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Users (
	UserId INT NOT NULL AUTO_INCREMENT,
    UserName VARCHAR(100) NOT NULL,
    PRIMARY KEY (UserId),
    CONSTRAINT unique_user UNIQUE (UserName)
);

CREATE TABLE IF NOT EXISTS UserSong (
	UserId INT NOT NULL,
	SongId INT NOT NULL,
    Plays INT DEFAULT 0,
    SecondsListened INT DEFAULT 0,
    LastPlayed Date,
    TimesSkipped INT DEFAULT 0,
    PRIMARY KEY (UserId, SongId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (SongId) REFERENCES Song(SongId) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Playlist (
    PlaylistId INT NOT NULL AUTO_INCREMENT,
    PlaylistName VARCHAR(100) NOT NULL,
    UserId INT NOT NULL,
    PRIMARY KEY (PlaylistId),
    CONSTRAINT fk_playlist_user 
        FOREIGN KEY (UserId) REFERENCES Users(UserId)
        ON DELETE CASCADE,
    CONSTRAINT unique_user_playlist 
        UNIQUE (UserId, PlaylistName)
);

CREATE TABLE IF NOT EXISTS PlaylistSong (
	PlaylistId INT NOT NULL,
    SongId INT NOT NULL,
    PRIMARY KEY (PlaylistId, SongId),
    FOREIGN KEY (PlaylistId) REFERENCES Playlist(PlaylistId) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (SongId) REFERENCES Song(SongId) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS UserPlaylist (
	PlaylistId INT NOT NULL,
    UserId INT NOT NULL,
    PRIMARY KEY (PlaylistId, UserId),
    FOREIGN KEY (PlaylistId) REFERENCES Playlist(PlaylistId) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS SongBlacklist (
	UserId INT NOT NULL,
	SongId INT NOT NULL,
    PRIMARY KEY (UserId, SongId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (SongId) REFERENCES Song(SongId) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Stored Procedures

DROP PROCEDURE IF EXISTS CreatePlaylist; -- add playlist
DROP PROCEDURE IF EXISTS AddSongToPlaylist; -- add song to playlist
DROP PROCEDURE IF EXISTS RemoveSongFromPlaylist; -- remove a song from playlist
DROP PROCEDURE IF EXISTS GetPlaylistSongs; -- get all songs in a playlist
DROP PROCEDURE IF EXISTS GetPlaylistsByUser; -- get all playlists belonging to a user
DROP PROCEDURE IF EXISTS SongPlay; -- takes parameter of how long song was played (if -1, then whole song), then adds that to user stats and increases by a play
DROP PROCEDURE IF EXISTS SongSkip; -- increase skip count for song per user
DROP PROCEDURE IF EXISTS BlacklistSong; -- add song to blacklist for user
DROP PROCEDURE IF EXISTS GetBlacklist; -- get blacklisted songs per user
DROP PROCEDURE IF EXISTS GetUserSongStats; -- stats on specific song per user
DROP PROCEDURE IF EXISTS GetUserGenreStats; -- stats for genre per user by scanning songs
DROP PROCEDURE IF EXISTS GetUserArtistStats; -- stats for artist per user by scanning songs
DROP PROCEDURE IF EXISTS GetArtistOfSong; -- gets artitst of a song
DROP PROCEDURE IF EXISTS GetGenreOfSong; -- gets genre of a song
DROP PROCEDURE IF EXISTS CreateJoinedPlaylist; -- create playlist, and assign to two users
DROP PROCEDURE IF EXISTS GetSongs; -- gets a list of all songs

DELIMITER $$

-- Creates playlist by taking in user & playlist
-- returns the playlist ID for further use
CREATE PROCEDURE CreatePlaylist(IN in_UserId INT, IN in_PlaylistName VARCHAR(100), OUT out_PlaylistId INT)
BEGIN
    INSERT INTO Playlist (PlaylistName, UserId) VALUES (in_PlaylistName, in_UserId);
    SET out_PlaylistId = LAST_INSERT_ID();
END$$

-- adds a song to a playlist
CREATE PROCEDURE AddSongToPlaylist(IN in_PlaylistId INT, IN in_SongId INT)
BEGIN
    INSERT IGNORE INTO PlaylistSong (PlaylistId, SongId) VALUES (in_PlaylistId, in_SongId);
END$$

-- remove song from a playlist
CREATE PROCEDURE RemoveSongFromPlaylist(IN in_PlaylistId INT, IN in_SongId INT)
BEGIN
    DELETE FROM PlaylistSong WHERE PlaylistId = in_PlaylistId AND SongId = in_SongId;
END$$

-- get songs from playlist
CREATE PROCEDURE GetPlaylistSongs(IN in_PlaylistId INT)
BEGIN
	SELECT Song.SongId, SongName FROM PlaylistSong INNER JOIN Song ON PlaylistSong.SongId = Song.SongId WHERE PlaylistSong.PlaylistId = in_PlaylistId;
END $$

-- get playlists that a user has
CREATE PROCEDURE GetPlaylistsByUser(IN p_userId INT)
BEGIN
    SELECT PlaylistId, PlaylistName
    FROM Playlist
    WHERE UserId = p_userId;
END $$

-- adds a play count for a song (-1 for SecondsPlayed if full duration of song)
CREATE PROCEDURE SongPlay(IN in_UserId INT, IN in_SongId INT, IN in_SecondsPlayed INT)
BEGIN
    DECLARE v_Duration INT DEFAULT 0;
 
    IF in_SecondsPlayed = -1 THEN
        SELECT DurationSeconds INTO v_Duration FROM Song WHERE SongId = in_SongId;
    ELSE
        SET v_Duration = in_SecondsPlayed;
    END IF;
 
    INSERT INTO UserSong (UserId, SongId, Plays, SecondsListened, LastPlayed) VALUES 
    (in_UserId, in_SongId, 1, v_Duration, CURDATE()) ON DUPLICATE KEY UPDATE Plays = Plays + 1, SecondsListened = SecondsListened + v_Duration, LastPlayed = CURDATE();
END$$

-- increases skip count for a song by user
CREATE PROCEDURE SongSkip(IN in_UserId INT, IN in_SongId INT)
BEGIN
    INSERT INTO UserSong (UserId, SongId, TimesSkipped)
    VALUES (in_UserId, in_SongId, 1) ON DUPLICATE KEY UPDATE TimesSkipped = TimesSkipped + 1;
END$$

-- adds a song to a user's blacklist
CREATE PROCEDURE BlacklistSong(IN in_UserId INT, IN in_SongId INT)
BEGIN
    INSERT IGNORE INTO SongBlacklist (UserId, SongId) VALUES (in_UserId, in_SongId);
    DELETE ps FROM PlaylistSong ps
    JOIN   UserPlaylist up ON up.PlaylistId = ps.PlaylistId
    WHERE  up.UserId = in_UserId AND  ps.SongId = in_SongId;
END$$

-- returns a user's blacklist
CREATE PROCEDURE GetBlacklist(IN in_UserId INT)
BEGIN
    SELECT sb.SongId, s.SongName
    FROM SongBlacklist sb JOIN Song s ON s.SongId = sb.SongId
    WHERE sb.UserId = in_UserId ORDER BY s.SongName;
END$$

-- get stats for songs for user
CREATE PROCEDURE GetUserSongStats(IN in_UserId INT)
BEGIN
    SELECT us.SongId, s.SongName, s.DurationSeconds, us.Plays, us.SecondsListened, us.TimesSkipped, us.LastPlayed
    FROM UserSong us JOIN Song s ON s.SongId = us.SongId WHERE us.UserId = in_UserId;
END$$

-- get stats for genres for user
CREATE PROCEDURE GetUserGenreStats(IN in_UserId INT)
BEGIN
    SELECT g.GenreId, g.GenreName, COUNT(DISTINCT us.SongId) AS UniqueSongs, SUM(us.Plays) AS TotalPlays, SUM(us.SecondsListened) AS TotalSecondsListened, SUM(us.TimesSkipped) AS TotalSkips
    FROM UserSong us JOIN Song s ON s.SongId = us.SongId JOIN SongGenre sg ON sg.SongId = s.SongId JOIN Genre g ON g.GenreId = sg.GenreId WHERE us.UserId = in_UserId GROUP BY g.GenreId, g.GenreName;
END$$

-- get stats for artists for user
CREATE PROCEDURE GetUserArtistStats(IN in_UserId INT)
BEGIN
    SELECT a.ArtistId, a.ArtistName, COUNT(DISTINCT us.SongId) AS UniqueSongs, SUM(us.Plays) AS TotalPlays, SUM(us.SecondsListened) AS TotalSecondsListened, SUM(us.TimesSkipped) AS TotalSkips
    FROM UserSong us JOIN Song s ON s.SongId = us.SongId JOIN ArtistSong  asl ON asl.SongId = s.SongId JOIN Artist a ON a.ArtistId = asl.ArtistId WHERE us.UserId = in_UserId GROUP BY a.ArtistId, a.ArtistName;
END$$

-- gets the artist of a song
CREATE PROCEDURE GetArtistOfSong(IN in_SongId INT)
BEGIN
    SELECT a.ArtistId, a.ArtistName FROM ArtistSong asl JOIN Artist a ON a.ArtistId = asl.ArtistId WHERE asl.SongId = in_SongId;
END$$

-- get the genre of a song
CREATE PROCEDURE GetGenreOfSong(IN in_SongId INT)
BEGIN
    SELECT g.GenreId, g.GenreName FROM SongGenre sg JOIN Genre g ON g.GenreId = sg.GenreId WHERE sg.SongId = in_SongId;
END$$

-- create a collaboration playlist between two users, returns the playlist id
CREATE PROCEDURE CreateJoinedPlaylist(IN in_UserId1 INT, IN in_UserId2 INT, IN in_PlaylistName VARCHAR(100), OUT out_PlaylistId INT)
BEGIN
    INSERT INTO Playlist (PlaylistName) VALUES (in_PlaylistName);
    SET out_PlaylistId = LAST_INSERT_ID();
    
    INSERT INTO UserPlaylist (PlaylistId, UserId) VALUES (out_PlaylistId, in_UserId1);
    INSERT INTO UserPlaylist (PlaylistId, UserId) VALUES (out_PlaylistId, in_UserId2);
END$$

-- returns a list of all songs and their ids
CREATE PROCEDURE GetSongs()
BEGIN
	SELECT SongId, SongName FROM Song;
END $$

DELIMITER $$

CREATE PROCEDURE GetGenresByArtistName (IN inputArtistName VARCHAR(100))
BEGIN
    SELECT DISTINCT g.GenreId, g.GenreName
    FROM Artist a
    INNER JOIN ArtistSong asg ON a.ArtistId = asg.ArtistId
    INNER JOIN Song s ON asg.SongId = s.SongId
    INNER JOIN SongGenre sg ON s.SongId = sg.SongId
    INNER JOIN Genre g ON sg.GenreId = g.GenreId
    WHERE a.ArtistName = inputArtistName;
END$$

CREATE PROCEDURE GetCandidateSongs(
    IN p_userId INT,
    IN p_a1 VARCHAR(100),
    IN p_a2 VARCHAR(100),
    IN p_a3 VARCHAR(100)
)
BEGIN

    SELECT
        s.SongId,
        s.SongName,

        MAX(a.ArtistId) AS ArtistId,
        MAX(a.ArtistName) AS ArtistName,

        MAX(sg.GenreId) AS GenreId,

        CASE 
            WHEN MAX(CASE 
                WHEN a.ArtistName IN (p_a1, p_a2, p_a3) THEN 1 
                ELSE 0 
            END) = 1
            THEN 'ARTIST'
            ELSE 'GENRE'
        END AS Source,

        COALESCE(MAX(us.PlayCount), 0) AS UserPlays,
        COALESCE(MAX(us.SkipCount), 0) AS SkipCount,

        CASE 
            WHEN MAX(us.LastPlayed) IS NULL THEN -1
            ELSE DATEDIFF(CURDATE(), MAX(us.LastPlayed))
        END AS DaysSinceLastPlayed

    FROM Song s

    LEFT JOIN ArtistSong asg ON s.SongId = asg.SongId
    LEFT JOIN Artist a ON a.ArtistId = asg.ArtistId

    LEFT JOIN SongGenre sg ON s.SongId = sg.SongId

    LEFT JOIN (
        SELECT 
            SongId,
            SUM(Plays) AS PlayCount,
            SUM(TimesSkipped) AS SkipCount,
            MAX(LastPlayed) AS LastPlayed
        FROM UserSong
        WHERE UserId = p_userId
        GROUP BY SongId
    ) us ON us.SongId = s.SongId

    WHERE s.SongId IN (

        SELECT DISTINCT s2.SongId
        FROM Song s2
        JOIN ArtistSong asg2 ON s2.SongId = asg2.SongId
        JOIN Artist a2 ON a2.ArtistId = asg2.ArtistId
        WHERE a2.ArtistName IN (p_a1, p_a2, p_a3)

        UNION

        SELECT DISTINCT s3.SongId
        FROM Song s3
        JOIN SongGenre sg3 ON s3.SongId = sg3.SongId
        WHERE sg3.GenreId IN (
            SELECT DISTINCT sg2.GenreId
            FROM Artist ar
            JOIN ArtistSong as2 ON ar.ArtistId = as2.ArtistId
            JOIN SongGenre sg2 ON sg2.SongId = as2.SongId
            WHERE ar.ArtistName IN (p_a1, p_a2, p_a3)
        )
    )

    GROUP BY s.SongId, s.SongName;

END $$

CREATE PROCEDURE GetBlacklistIds(IN in_UserId INT)
BEGIN
    SELECT SongId FROM SongBlacklist
    WHERE UserId = in_UserId;
END $$

CREATE PROCEDURE GetUserArtistScores(IN in_UserId INT)
BEGIN
    SELECT 
        a.ArtistId,
        SUM(us.Plays) - SUM(us.TimesSkipped) AS Score
    FROM UserSong us
    INNER JOIN ArtistSong asl ON us.SongId = asl.SongId
    INNER JOIN Artist a ON a.ArtistId = asl.ArtistId
    WHERE us.UserId = in_UserId
    GROUP BY a.ArtistId;
END $$

CREATE PROCEDURE GetUserGenreScores(IN in_UserId INT)
BEGIN
    SELECT 
        g.GenreId,
        SUM(us.Plays) - SUM(us.TimesSkipped) AS Score
    FROM UserSong us
    INNER JOIN SongGenre sg ON us.SongId = sg.SongId
    INNER JOIN Genre g ON g.GenreId = sg.GenreId
    WHERE us.UserId = in_UserId
    GROUP BY g.GenreId;
END $$

DROP PROCEDURE IF EXISTS GetArtistIdBySong;

DELIMITER $$

CREATE PROCEDURE GetArtistIdBySong(IN in_SongId INT)
BEGIN
    SELECT ArtistId 
    FROM ArtistSong
    WHERE SongId = in_SongId
    LIMIT 1;
END $$

DROP PROCEDURE IF EXISTS GetGenreIdBySong;

DELIMITER $$

CREATE PROCEDURE GetGenreIdBySong(IN in_SongId INT)
BEGIN
    SELECT GenreId 
    FROM SongGenre
    WHERE SongId = in_SongId
    LIMIT 1;
END $$


DELIMITER ;


-- ================================================
-- AI auto-generated songs for database
-- 300 songs from TopSongs.csv
-- ================================================

USE MusicPlayer;

-- ----------------
-- Songs
-- ----------------
INSERT INTO Song (SongName, DurationSeconds) VALUES ('White Christmas', 283);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Rock Around the Clock', 148);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('My Heart Will Go On', 126);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Nothing Compares 2 U', 309);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Hey Jude', 190);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('(Everything I Do) I Do it For You', 182);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Will Always Love You', 177);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Another Brick in the Wall (part 2)', 155);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Flashdance... What a Feeling', 308);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Candle in the Wind ''97', 146);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('(I Can''t Get No) Satisfaction', 293);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Gangsta''s Paradise', 309);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Lose Yourself', 348);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Believe', 259);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Yeah!', 142);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Let it Be', 271);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('A Whiter Shade of Pale', 228);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Stayin'' Alive', 128);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Bleeding Love', 127);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Every Breath You Take', 143);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Bette Davis Eyes', 175);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Umbrella', 179);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('My Sweet Lord', 249);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Dancing Queen', 274);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I''ll Be Missing You', 126);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Baby One More Time', 263);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Want to Hold Your Hand', 170);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Billie Jean', 303);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Mack the Knife', 286);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('You''re the One That I Want', 299);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('We Are the World', 259);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Mmmbop', 227);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Vogue', 176);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Wannabe', 234);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Oh, Pretty Woman', 270);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Without Me', 191);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('YMCA', 327);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Just Called to Say I Love You', 342);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Careless Whisper', 121);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Imagine', 314);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Eye of the Tiger', 326);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Macarena', 160);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Are You Lonesome Tonight?', 298);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Can''t Help Falling in Love', 228);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Hey Ya!', 207);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Bohemian Rhapsody', 191);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('A Woman in Love', 159);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Kissed A Girl', 175);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Over the Rainbow', 315);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('It''s Now Or Never', 206);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Don''t Speak', 146);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Hips don''t lie', 143);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('In Da Club', 217);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Can''t Get You Out of My Head', 144);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Where is the Love?', 211);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Angie', 336);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('In the Summertime', 208);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('(Ghost) Riders in the Sky', 274);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Poker Face', 187);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('The Sign', 326);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Kung Fu Fighting', 131);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Sexyback', 306);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Hung Up', 237);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Jailhouse Rock', 257);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Help!', 151);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Love Rock ''n'' Roll', 356);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Livin'' La Vida Loca', 216);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I''m a Believer', 140);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Whenever, Wherever', 261);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('We Found Love', 195);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Strangers in the Night', 332);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Streets of Philadelphia', 280);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Unchained Melody', 278);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Swear', 346);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('In the Mood', 340);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Mambo No 5 (A Little Bit of ...)', 212);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Que sera sera (Whatever will be will be)', 267);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Low', 169);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Mona Lisa', 300);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Seasons in the Sun', 137);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Karma Chameleon', 131);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Don''t Want to Miss a Thing', 289);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Heart of Glass', 178);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('End of the Road', 317);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Killing Me Softly With His Song', 194);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Tie a Yellow Ribbon ''round the Old Oak Tree', 140);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Big Girls Don''t Cry', 338);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Venus', 179);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Hotel California', 341);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Swinging On a Star', 145);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('All You Need is Love', 217);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('The Twist', 191);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Dilemma', 236);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('She Loves You', 282);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Crazy in Love', 333);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Gotta Feeling', 213);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('(Just Like) Starting Over', 161);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Do You Really Want to Hurt Me?', 214);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('The Boy is Mine', 210);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Like a Prayer', 173);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Beautiful Girls', 291);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('When Doves Cry', 188);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Yesterday', 299);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Don''t Cha', 359);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Night Fever', 294);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Upside Down', 285);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Music', 138);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('How You Remind Me', 275);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Sugar Sugar', 282);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Lady Marmalade (Voulez-Vous Coucher Aver Moi Ce Soir?)', 163);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Take On Me', 256);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('The Ketchup Song (Asereje)', 306);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Get Back', 182);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Smooth', 161);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Informer', 238);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Apologize', 217);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('All the Things She Said', 189);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Back For Good', 356);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Hello, Goodbye', 283);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('If You Leave Me Now', 296);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Barbie Girl', 262);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Crazy', 176);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Call Me', 295);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Wanna Dance With Somebody (Who Loves Me)', 203);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Don''t Go Breaking My Heart', 335);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('All That She Wants', 316);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Rivers of Babylon', 318);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Black Or White', 134);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Bridge Over Troubled Water', 178);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Le Freak', 330);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('No Scrubs', 128);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('These Boots Are Made For Walking', 326);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Can''t Stop Loving You', 200);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I''d Do Anything For Love (But I Won''t Do That)', 222);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Let''s Twist Again', 188);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Theme From ''A Summer Place''', 136);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Party Rock Anthem', 174);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('You''re Beautiful', 353);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('American Pie', 265);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Stand By Me', 344);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('All For Love', 303);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('So What', 200);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Another Day in Paradise', 174);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Ebony & Ivory', 287);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Just Dance', 247);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Blue (Da Ba Dee)', 221);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Downtown', 346);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Beat It', 354);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Don''t You Want Me', 284);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Never Gonna Give You Up', 237);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I''ve Been Thinking About You', 156);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Tom Dooley', 187);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Don''t Fence Me In', 155);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Take My Breath Away', 183);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Irreplaceable', 310);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Smells Like Teen Spirit', 263);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Beautiful Day', 257);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Buttons & Bows', 187);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Girlfriend', 311);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Rock Your Baby', 269);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Will Survive', 229);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Without You', 349);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Waterloo', 269);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Vaya Con Dios (may God Be With You)', 222);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Ice Ice Baby', 212);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Third Man Theme', 176);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Fernando', 155);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Believe I Can Fly', 250);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Complicated', 246);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Penny Lane', 143);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Love The Way You Lie', 313);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Rolling In The Deep', 132);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Secret Love', 340);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('(Let''s Get) Physical', 148);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I''ll Make Love to You', 159);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Four Minutes', 280);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Have You Ever Really Loved a Woman?', 160);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('U Can''t Touch This', 322);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Somebody That I Used to Know', 294);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Stars On 45', 228);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Funkytown', 272);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Too Young', 136);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Want it That Way', 218);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Because You Loved Me', 217);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Rock Me Amadeus', 272);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Grenade', 239);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Good Vibrations', 255);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('(The Lights Went Out In) Massachusetts', 184);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('That''s What Friends Are For', 261);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('House of the Rising Sun', 340);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Toxic', 122);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Girls Just Wanna Have Fun', 294);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Get the Party Started', 304);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Sixteen Tons', 149);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Those Were the Days', 294);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Feel Fine', 346);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('You Belong to Me', 257);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Paperback Writer', 312);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Beg Your Pardon (I Never Promised You a Rose Garden)', 188);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('What''s Love Got to Do With It?', 316);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Do They Know It''s Christmas?', 284);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Honky Tonk Woman', 207);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('One Sweet Day', 148);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Killing Me Softly With His Song', 195);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Hot ''n'' cold', 231);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Waterfalls', 160);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('It Must Have Been Love', 236);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Tragedy', 120);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('A Hard Day''s Night', 304);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('La Bamba', 344);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Mister Sandman', 304);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Maggie May', 187);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('A Groovy Kind of Love', 248);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('In the Year 2525 (Exordium & Terminus)', 315);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Fantasy', 165);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Faith', 249);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('I Want to Know What Love Is', 353);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Heartbreak Hotel', 147);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Beautiful Liar', 342);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Suspicious Minds', 280);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Crocodile Rock', 196);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Papa Don''t Preach', 335);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Un-Break My Heart', 283);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Shut Up', 249);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Tears in Heaven', 275);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('You''re So Vain', 170);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Men in Black', 159);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Bring Me to Life', 215);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Endless Love', 315);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Let''s Dance', 161);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Abracadabra', 258);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Love is All Around', 319);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Lonely', 356);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('You Are Not Alone', 255);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Genie in a Bottle', 355);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Missing', 120);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Truly Madly Deeply', 273);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Paper Doll', 202);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Don''t Worry Be Happy', 245);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('How Deep is Your Love?', 124);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Fallin''', 148);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('F**k it (I Don''t Want You Back)', 357);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Boombastic', 212);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Tennessee Waltz', 344);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Relax', 332);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Bad Romance', 326);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Hound Dog', 198);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Frozen', 181);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Beautiful', 134);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Tubthumping', 181);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Blueberry Hill', 344);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('A Little Less Conversation', 265);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Volare', 140);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('No One', 141);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Hot Stuff', 307);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('West End Girls', 244);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Walk Like an Egyptian', 328);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('We Belong Together', 137);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Bad Day', 314);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('What''s Up?', 256);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('That''s the Way Love Goes', 316);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Another One Bites the Dust', 152);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Call Me Maybe', 152);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Centrefold', 288);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Promiscuous', 241);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Born to Be Alive', 260);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Mr Vain', 162);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('With Or Without You', 187);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Don''t Stop the Music', 255);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Kiss From a Rose', 343);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Always', 275);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Please Forgive Me', 228);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Speedy Gonzales', 174);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Shout', 357);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Total Eclipse of the Heart', 258);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Wake Me Up Before You Go Go', 313);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Sh-Boom (Life Could Be a Dream)', 306);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Boulevard of Broken Dreams', 296);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Yellow Submarine', 171);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('(I''ve Had) the Time of My Life', 302);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Blaze of Glory', 199);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Stan', 222);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Smoke Gets in Your Eyes', 291);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Say You, Say Me', 286);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('To Be With You', 215);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('The Sounds of Silence', 232);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Without You', 350);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Down Under', 252);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('All I Wanna Do', 235);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Cotton Eye Joe', 150);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Jumpin'' Jack Flash', 183);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Red Red Wine', 177);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Tainted Love', 136);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Can''t Fight the Moonlight', 206);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('It Wasn''t Me', 125);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('(Put Another Nickel In) Music! Music! Music!', 270);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Come On Eileen', 261);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Just the Way You Are', 178);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('Marina', 270);
INSERT INTO Song (SongName, DurationSeconds) VALUES ('If You Had My Love', 176);

-- ----------------
-- Genres
-- ----------------
INSERT IGNORE INTO Genre (GenreName) VALUES ('Disco');
INSERT IGNORE INTO Genre (GenreName) VALUES ('Hip-Hop/Rap');
INSERT IGNORE INTO Genre (GenreName) VALUES ('Jazz/Classical');
INSERT IGNORE INTO Genre (GenreName) VALUES ('Pop');
INSERT IGNORE INTO Genre (GenreName) VALUES ('R&B/Soul');
INSERT IGNORE INTO Genre (GenreName) VALUES ('Reggae');
INSERT IGNORE INTO Genre (GenreName) VALUES ('Rock');
INSERT IGNORE INTO Genre (GenreName) VALUES ('Rock and Roll');

-- ----------------
-- Artists
-- ----------------
INSERT IGNORE INTO Artist (ArtistName) VALUES ('50 Cent');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('A-Ha');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Abba');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Ace of Base');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Adele');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Aerosmith');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Akon');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Alicia Keys');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('All-4-One');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Anton Karas');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Aqua');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Archies');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Avril Lavigne');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Band Aid');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Barbra Streisand');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bee Gees');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Ben E King');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Berlin');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Beyonce');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Beyonce & Shakira');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bill Haley & his Comets');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bill Medley & Jennifer Warnes');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bing Crosby');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bing Crosby & The Andrews Sisters');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Blondie');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bobby Darin');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bobby McFerrin');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bon Jovi');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Boney M');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bonnie Tyler');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Boyz II Men');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Brandy & Monica');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Britney Spears');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bruce Springsteen');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bruno Mars');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bryan Adams');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Bryan Adams, Rod Stewart & Sting');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Carl Douglas');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Carly Rae Jepsen');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Carly Simon');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Celine Dion');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Cher');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Chic');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Chicago');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Christina Aguilera');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Christina Aguilera, Lil'' Kim, Mya & Pink');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Chubby Checker');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Chumbawamba');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Coolio');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Culture Beat');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Culture Club');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Cyndi Lauper');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Daniel Powter');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('David Bowie');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Dexys Midnight Runners');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Diana Ross');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Diana Ross & Lionel Richie');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Dinah Shore');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Dionne Warwick & Friends');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Domenico Modugno');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Don McLean');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Donna Summer');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Doris Day');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Eagles');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Eamon');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Eiffel 65');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Elton John');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Elton John & Kiki Dee');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Elvis Presley');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Elvis Presley & JXL');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Eminem');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Eminem & Rihanna');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Eric Clapton');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Evanescence');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Everything But The Girl');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Falco');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Fats Domino');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Fergie');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Flo-Rida & T-Pain');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Foreigner');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Four Non Blondes');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Frank Sinatra');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Frankie Goes To Hollywood');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('George Harrison');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('George McCrae');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('George Michael');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Glenn Miller');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Gloria Gaynor');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Gnarls Barkley');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Gotye & Kimbra');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Green Day');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Hanson');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Harry Nilsson');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Irene Cara');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('J Geils Band');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('James Blunt');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Janet Jackson');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Jennifer Lopez');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Jo Stafford');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Joan Jett & The Blackhearts');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('John Lennon');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('John Travolta & Olivia Newton-John');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Judy Garland');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Justin Timberlake');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Katy Perry');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Kim Carnes');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Kylie Minogue');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('LMFAO');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Lady GaGa');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Lady GaGa & Colby O''Donis');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Las Ketchup');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('LeAnn Rimes');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Leona Lewis');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Les Paul & Mary Ford');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Lionel Richie');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Lipps Inc');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Londonbeat');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Los Del Rio');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Los Lobos');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Lou Bega');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Lynn Anderson');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('MC Hammer');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Madonna');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Madonna & Justin Timberlake');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Mariah Carey');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Mariah Carey & Boyz II Men');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Mary Hopkin');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Meat Loaf');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Men At Work');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Michael Jackson');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Mr Big');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Mungo Jerry');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Nancy Sinatra');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Nat King Cole');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Nelly & Kelly Rowland');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Nelly Furtado & Timbaland');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Nickelback');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Nirvana');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('No Doubt');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Olivia Newton-John');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('OutKast');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('P Diddy & Faith Evans');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Pat Boone');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Patrick Hernandez');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Patti Page');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Paul McCartney & Stevie Wonder');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Percy Faith');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Petula Clark');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Phil Collins');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Pink');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Pink Floyd');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Prince');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Procol Harum');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Queen');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('R Kelly');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Ray Charles');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Rednex');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Rick Astley');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Ricky Martin');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Rihanna');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Rihanna & Calvin Harris');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Rihanna & Jay-Z');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Rob Thomas & Santana');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Roberta Flack');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Rocco Granata');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Rod Stewart');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Roxette');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Roy Orbison');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Savage Garden');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Seal');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Sean Kingston');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Shaggy');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Shaggy & Ricardo ''RikRok'' Ducent');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Shakira');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Shakira & Wyclef Jean');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Sheryl Crow');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Shocking Blue');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Simon & Garfunkel');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Sinead O''Connor');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Snow');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Soft Cell');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Spice Girls');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Starsound');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Steve Miller Band');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Stevie Wonder');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Survivor');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('TLC');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Take That');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Tears For Fears');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Tennessee Ernie Ford');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Teresa Brewer');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Terry Jacks');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Animals');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Backstreet Boys');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Bangles');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Beach Boys');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Beatles');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Black Eyed Peas');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Chordettes');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Crew-Cuts');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Fugees');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Human League');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Kingston Trio');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Mills Brothers');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Monkees');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Pet Shop Boys');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Platters');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Police');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Pussycat Dolls');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Righteous Brothers');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Rolling Stones');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('The Village People');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Timbaland & OneRepublic');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Tina Turner');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Toni Braxton');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Tony Orlando & Dawn');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('U2');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('UB40');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('USA For Africa');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Usher');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Vanilla Ice');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Vaughn Monroe');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Wet Wet Wet');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Wham!');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Whitney Houston');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Will Smith');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('Zager & Evans');
INSERT IGNORE INTO Artist (ArtistName) VALUES ('t.A.T.u.');

-- ----------------
-- ArtistSong
-- ----------------
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bing Crosby' AND s.SongName = 'White Christmas';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bill Haley & his Comets' AND s.SongName = 'Rock Around the Clock';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Celine Dion' AND s.SongName = 'My Heart Will Go On';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Sinead O''Connor' AND s.SongName = 'Nothing Compares 2 U';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'Hey Jude';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bryan Adams' AND s.SongName = '(Everything I Do) I Do it For You';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Whitney Houston' AND s.SongName = 'I Will Always Love You';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Pink Floyd' AND s.SongName = 'Another Brick in the Wall (part 2)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Irene Cara' AND s.SongName = 'Flashdance... What a Feeling';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Elton John' AND s.SongName = 'Candle in the Wind ''97';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Rolling Stones' AND s.SongName = '(I Can''t Get No) Satisfaction';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Coolio' AND s.SongName = 'Gangsta''s Paradise';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Eminem' AND s.SongName = 'Lose Yourself';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Cher' AND s.SongName = 'Believe';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Usher' AND s.SongName = 'Yeah!';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'Let it Be';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Procol Harum' AND s.SongName = 'A Whiter Shade of Pale';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bee Gees' AND s.SongName = 'Stayin'' Alive';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Leona Lewis' AND s.SongName = 'Bleeding Love';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Police' AND s.SongName = 'Every Breath You Take';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Kim Carnes' AND s.SongName = 'Bette Davis Eyes';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Rihanna & Jay-Z' AND s.SongName = 'Umbrella';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'George Harrison' AND s.SongName = 'My Sweet Lord';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Abba' AND s.SongName = 'Dancing Queen';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'P Diddy & Faith Evans' AND s.SongName = 'I''ll Be Missing You';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Britney Spears' AND s.SongName = 'Baby One More Time';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'I Want to Hold Your Hand';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Michael Jackson' AND s.SongName = 'Billie Jean';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bobby Darin' AND s.SongName = 'Mack the Knife';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'John Travolta & Olivia Newton-John' AND s.SongName = 'You''re the One That I Want';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'USA For Africa' AND s.SongName = 'We Are the World';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Hanson' AND s.SongName = 'Mmmbop';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Madonna' AND s.SongName = 'Vogue';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Spice Girls' AND s.SongName = 'Wannabe';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Roy Orbison' AND s.SongName = 'Oh, Pretty Woman';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Eminem' AND s.SongName = 'Without Me';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Village People' AND s.SongName = 'YMCA';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Stevie Wonder' AND s.SongName = 'I Just Called to Say I Love You';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'George Michael' AND s.SongName = 'Careless Whisper';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'John Lennon' AND s.SongName = 'Imagine';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Survivor' AND s.SongName = 'Eye of the Tiger';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Los Del Rio' AND s.SongName = 'Macarena';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Elvis Presley' AND s.SongName = 'Are You Lonesome Tonight?';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'UB40' AND s.SongName = 'Can''t Help Falling in Love';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'OutKast' AND s.SongName = 'Hey Ya!';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Queen' AND s.SongName = 'Bohemian Rhapsody';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Barbra Streisand' AND s.SongName = 'A Woman in Love';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Katy Perry' AND s.SongName = 'I Kissed A Girl';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Judy Garland' AND s.SongName = 'Over the Rainbow';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Elvis Presley' AND s.SongName = 'It''s Now Or Never';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'No Doubt' AND s.SongName = 'Don''t Speak';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Shakira & Wyclef Jean' AND s.SongName = 'Hips don''t lie';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = '50 Cent' AND s.SongName = 'In Da Club';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Kylie Minogue' AND s.SongName = 'Can''t Get You Out of My Head';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Black Eyed Peas' AND s.SongName = 'Where is the Love?';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Rolling Stones' AND s.SongName = 'Angie';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Mungo Jerry' AND s.SongName = 'In the Summertime';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Vaughn Monroe' AND s.SongName = '(Ghost) Riders in the Sky';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Lady GaGa' AND s.SongName = 'Poker Face';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Ace of Base' AND s.SongName = 'The Sign';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Carl Douglas' AND s.SongName = 'Kung Fu Fighting';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Justin Timberlake' AND s.SongName = 'Sexyback';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Madonna' AND s.SongName = 'Hung Up';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Elvis Presley' AND s.SongName = 'Jailhouse Rock';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'Help!';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Joan Jett & The Blackhearts' AND s.SongName = 'I Love Rock ''n'' Roll';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Ricky Martin' AND s.SongName = 'Livin'' La Vida Loca';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Monkees' AND s.SongName = 'I''m a Believer';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Shakira' AND s.SongName = 'Whenever, Wherever';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Rihanna & Calvin Harris' AND s.SongName = 'We Found Love';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Frank Sinatra' AND s.SongName = 'Strangers in the Night';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bruce Springsteen' AND s.SongName = 'Streets of Philadelphia';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Righteous Brothers' AND s.SongName = 'Unchained Melody';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'All-4-One' AND s.SongName = 'I Swear';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Glenn Miller' AND s.SongName = 'In the Mood';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Lou Bega' AND s.SongName = 'Mambo No 5 (A Little Bit of ...)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Doris Day' AND s.SongName = 'Que sera sera (Whatever will be will be)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Flo-Rida & T-Pain' AND s.SongName = 'Low';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Nat King Cole' AND s.SongName = 'Mona Lisa';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Terry Jacks' AND s.SongName = 'Seasons in the Sun';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Culture Club' AND s.SongName = 'Karma Chameleon';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Aerosmith' AND s.SongName = 'I Don''t Want to Miss a Thing';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Blondie' AND s.SongName = 'Heart of Glass';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Boyz II Men' AND s.SongName = 'End of the Road';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Fugees' AND s.SongName = 'Killing Me Softly With His Song';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Tony Orlando & Dawn' AND s.SongName = 'Tie a Yellow Ribbon ''round the Old Oak Tree';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Fergie' AND s.SongName = 'Big Girls Don''t Cry';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Shocking Blue' AND s.SongName = 'Venus';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Eagles' AND s.SongName = 'Hotel California';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bing Crosby' AND s.SongName = 'Swinging On a Star';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'All You Need is Love';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Chubby Checker' AND s.SongName = 'The Twist';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Nelly & Kelly Rowland' AND s.SongName = 'Dilemma';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'She Loves You';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Beyonce' AND s.SongName = 'Crazy in Love';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Black Eyed Peas' AND s.SongName = 'I Gotta Feeling';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'John Lennon' AND s.SongName = '(Just Like) Starting Over';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Culture Club' AND s.SongName = 'Do You Really Want to Hurt Me?';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Brandy & Monica' AND s.SongName = 'The Boy is Mine';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Madonna' AND s.SongName = 'Like a Prayer';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Sean Kingston' AND s.SongName = 'Beautiful Girls';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Prince' AND s.SongName = 'When Doves Cry';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'Yesterday';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Pussycat Dolls' AND s.SongName = 'Don''t Cha';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bee Gees' AND s.SongName = 'Night Fever';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Diana Ross' AND s.SongName = 'Upside Down';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Madonna' AND s.SongName = 'Music';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Nickelback' AND s.SongName = 'How You Remind Me';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Archies' AND s.SongName = 'Sugar Sugar';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Christina Aguilera, Lil'' Kim, Mya & Pink' AND s.SongName = 'Lady Marmalade (Voulez-Vous Coucher Aver Moi Ce Soir?)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'A-Ha' AND s.SongName = 'Take On Me';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Las Ketchup' AND s.SongName = 'The Ketchup Song (Asereje)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'Get Back';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Rob Thomas & Santana' AND s.SongName = 'Smooth';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Snow' AND s.SongName = 'Informer';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Timbaland & OneRepublic' AND s.SongName = 'Apologize';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 't.A.T.u.' AND s.SongName = 'All the Things She Said';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Take That' AND s.SongName = 'Back For Good';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'Hello, Goodbye';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Chicago' AND s.SongName = 'If You Leave Me Now';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Aqua' AND s.SongName = 'Barbie Girl';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Gnarls Barkley' AND s.SongName = 'Crazy';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Blondie' AND s.SongName = 'Call Me';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Whitney Houston' AND s.SongName = 'I Wanna Dance With Somebody (Who Loves Me)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Elton John & Kiki Dee' AND s.SongName = 'Don''t Go Breaking My Heart';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Ace of Base' AND s.SongName = 'All That She Wants';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Boney M' AND s.SongName = 'Rivers of Babylon';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Michael Jackson' AND s.SongName = 'Black Or White';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Simon & Garfunkel' AND s.SongName = 'Bridge Over Troubled Water';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Chic' AND s.SongName = 'Le Freak';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'TLC' AND s.SongName = 'No Scrubs';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Nancy Sinatra' AND s.SongName = 'These Boots Are Made For Walking';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Ray Charles' AND s.SongName = 'I Can''t Stop Loving You';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Meat Loaf' AND s.SongName = 'I''d Do Anything For Love (But I Won''t Do That)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Chubby Checker' AND s.SongName = 'Let''s Twist Again';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Percy Faith' AND s.SongName = 'Theme From ''A Summer Place''';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'LMFAO' AND s.SongName = 'Party Rock Anthem';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'James Blunt' AND s.SongName = 'You''re Beautiful';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Don McLean' AND s.SongName = 'American Pie';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Ben E King' AND s.SongName = 'Stand By Me';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bryan Adams, Rod Stewart & Sting' AND s.SongName = 'All For Love';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Pink' AND s.SongName = 'So What';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Phil Collins' AND s.SongName = 'Another Day in Paradise';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Paul McCartney & Stevie Wonder' AND s.SongName = 'Ebony & Ivory';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Lady GaGa & Colby O''Donis' AND s.SongName = 'Just Dance';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Eiffel 65' AND s.SongName = 'Blue (Da Ba Dee)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Petula Clark' AND s.SongName = 'Downtown';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Michael Jackson' AND s.SongName = 'Beat It';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Human League' AND s.SongName = 'Don''t You Want Me';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Rick Astley' AND s.SongName = 'Never Gonna Give You Up';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Londonbeat' AND s.SongName = 'I''ve Been Thinking About You';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Kingston Trio' AND s.SongName = 'Tom Dooley';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bing Crosby & The Andrews Sisters' AND s.SongName = 'Don''t Fence Me In';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Berlin' AND s.SongName = 'Take My Breath Away';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Beyonce' AND s.SongName = 'Irreplaceable';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Nirvana' AND s.SongName = 'Smells Like Teen Spirit';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'U2' AND s.SongName = 'Beautiful Day';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Dinah Shore' AND s.SongName = 'Buttons & Bows';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Avril Lavigne' AND s.SongName = 'Girlfriend';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'George McCrae' AND s.SongName = 'Rock Your Baby';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Gloria Gaynor' AND s.SongName = 'I Will Survive';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Mariah Carey' AND s.SongName = 'Without You';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Abba' AND s.SongName = 'Waterloo';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Les Paul & Mary Ford' AND s.SongName = 'Vaya Con Dios (may God Be With You)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Vanilla Ice' AND s.SongName = 'Ice Ice Baby';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Anton Karas' AND s.SongName = 'Third Man Theme';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Abba' AND s.SongName = 'Fernando';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'R Kelly' AND s.SongName = 'I Believe I Can Fly';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Avril Lavigne' AND s.SongName = 'Complicated';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'Penny Lane';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Eminem & Rihanna' AND s.SongName = 'Love The Way You Lie';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Adele' AND s.SongName = 'Rolling In The Deep';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Doris Day' AND s.SongName = 'Secret Love';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Olivia Newton-John' AND s.SongName = '(Let''s Get) Physical';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Boyz II Men' AND s.SongName = 'I''ll Make Love to You';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Madonna & Justin Timberlake' AND s.SongName = 'Four Minutes';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bryan Adams' AND s.SongName = 'Have You Ever Really Loved a Woman?';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'MC Hammer' AND s.SongName = 'U Can''t Touch This';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Gotye & Kimbra' AND s.SongName = 'Somebody That I Used to Know';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Starsound' AND s.SongName = 'Stars On 45';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Lipps Inc' AND s.SongName = 'Funkytown';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Nat King Cole' AND s.SongName = 'Too Young';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Backstreet Boys' AND s.SongName = 'I Want it That Way';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Celine Dion' AND s.SongName = 'Because You Loved Me';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Falco' AND s.SongName = 'Rock Me Amadeus';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bruno Mars' AND s.SongName = 'Grenade';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beach Boys' AND s.SongName = 'Good Vibrations';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bee Gees' AND s.SongName = '(The Lights Went Out In) Massachusetts';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Dionne Warwick & Friends' AND s.SongName = 'That''s What Friends Are For';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Animals' AND s.SongName = 'House of the Rising Sun';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Britney Spears' AND s.SongName = 'Toxic';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Cyndi Lauper' AND s.SongName = 'Girls Just Wanna Have Fun';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Pink' AND s.SongName = 'Get the Party Started';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Tennessee Ernie Ford' AND s.SongName = 'Sixteen Tons';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Mary Hopkin' AND s.SongName = 'Those Were the Days';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'I Feel Fine';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Jo Stafford' AND s.SongName = 'You Belong to Me';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'Paperback Writer';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Lynn Anderson' AND s.SongName = 'I Beg Your Pardon (I Never Promised You a Rose Garden)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Tina Turner' AND s.SongName = 'What''s Love Got to Do With It?';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Band Aid' AND s.SongName = 'Do They Know It''s Christmas?';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Rolling Stones' AND s.SongName = 'Honky Tonk Woman';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Mariah Carey & Boyz II Men' AND s.SongName = 'One Sweet Day';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Roberta Flack' AND s.SongName = 'Killing Me Softly With His Song';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Katy Perry' AND s.SongName = 'Hot ''n'' cold';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'TLC' AND s.SongName = 'Waterfalls';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Roxette' AND s.SongName = 'It Must Have Been Love';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bee Gees' AND s.SongName = 'Tragedy';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'A Hard Day''s Night';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Los Lobos' AND s.SongName = 'La Bamba';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Chordettes' AND s.SongName = 'Mister Sandman';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Rod Stewart' AND s.SongName = 'Maggie May';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Phil Collins' AND s.SongName = 'A Groovy Kind of Love';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Zager & Evans' AND s.SongName = 'In the Year 2525 (Exordium & Terminus)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Mariah Carey' AND s.SongName = 'Fantasy';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'George Michael' AND s.SongName = 'Faith';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Foreigner' AND s.SongName = 'I Want to Know What Love Is';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Elvis Presley' AND s.SongName = 'Heartbreak Hotel';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Beyonce & Shakira' AND s.SongName = 'Beautiful Liar';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Elvis Presley' AND s.SongName = 'Suspicious Minds';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Elton John' AND s.SongName = 'Crocodile Rock';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Madonna' AND s.SongName = 'Papa Don''t Preach';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Toni Braxton' AND s.SongName = 'Un-Break My Heart';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Black Eyed Peas' AND s.SongName = 'Shut Up';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Eric Clapton' AND s.SongName = 'Tears in Heaven';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Carly Simon' AND s.SongName = 'You''re So Vain';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Will Smith' AND s.SongName = 'Men in Black';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Evanescence' AND s.SongName = 'Bring Me to Life';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Diana Ross & Lionel Richie' AND s.SongName = 'Endless Love';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'David Bowie' AND s.SongName = 'Let''s Dance';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Steve Miller Band' AND s.SongName = 'Abracadabra';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Wet Wet Wet' AND s.SongName = 'Love is All Around';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Akon' AND s.SongName = 'Lonely';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Michael Jackson' AND s.SongName = 'You Are Not Alone';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Christina Aguilera' AND s.SongName = 'Genie in a Bottle';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Everything But The Girl' AND s.SongName = 'Missing';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Savage Garden' AND s.SongName = 'Truly Madly Deeply';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Mills Brothers' AND s.SongName = 'Paper Doll';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bobby McFerrin' AND s.SongName = 'Don''t Worry Be Happy';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bee Gees' AND s.SongName = 'How Deep is Your Love?';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Alicia Keys' AND s.SongName = 'Fallin''';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Eamon' AND s.SongName = 'F**k it (I Don''t Want You Back)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Shaggy' AND s.SongName = 'Boombastic';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Patti Page' AND s.SongName = 'Tennessee Waltz';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Frankie Goes To Hollywood' AND s.SongName = 'Relax';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Lady GaGa' AND s.SongName = 'Bad Romance';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Elvis Presley' AND s.SongName = 'Hound Dog';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Madonna' AND s.SongName = 'Frozen';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Christina Aguilera' AND s.SongName = 'Beautiful';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Chumbawamba' AND s.SongName = 'Tubthumping';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Fats Domino' AND s.SongName = 'Blueberry Hill';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Elvis Presley & JXL' AND s.SongName = 'A Little Less Conversation';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Domenico Modugno' AND s.SongName = 'Volare';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Alicia Keys' AND s.SongName = 'No One';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Donna Summer' AND s.SongName = 'Hot Stuff';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Pet Shop Boys' AND s.SongName = 'West End Girls';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Bangles' AND s.SongName = 'Walk Like an Egyptian';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Mariah Carey' AND s.SongName = 'We Belong Together';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Daniel Powter' AND s.SongName = 'Bad Day';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Four Non Blondes' AND s.SongName = 'What''s Up?';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Janet Jackson' AND s.SongName = 'That''s the Way Love Goes';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Queen' AND s.SongName = 'Another One Bites the Dust';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Carly Rae Jepsen' AND s.SongName = 'Call Me Maybe';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'J Geils Band' AND s.SongName = 'Centrefold';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Nelly Furtado & Timbaland' AND s.SongName = 'Promiscuous';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Patrick Hernandez' AND s.SongName = 'Born to Be Alive';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Culture Beat' AND s.SongName = 'Mr Vain';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'U2' AND s.SongName = 'With Or Without You';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Rihanna' AND s.SongName = 'Don''t Stop the Music';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Seal' AND s.SongName = 'Kiss From a Rose';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bon Jovi' AND s.SongName = 'Always';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bryan Adams' AND s.SongName = 'Please Forgive Me';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Pat Boone' AND s.SongName = 'Speedy Gonzales';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Tears For Fears' AND s.SongName = 'Shout';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bonnie Tyler' AND s.SongName = 'Total Eclipse of the Heart';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Wham!' AND s.SongName = 'Wake Me Up Before You Go Go';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Crew-Cuts' AND s.SongName = 'Sh-Boom (Life Could Be a Dream)';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Green Day' AND s.SongName = 'Boulevard of Broken Dreams';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Beatles' AND s.SongName = 'Yellow Submarine';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bill Medley & Jennifer Warnes' AND s.SongName = '(I''ve Had) the Time of My Life';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bon Jovi' AND s.SongName = 'Blaze of Glory';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Eminem' AND s.SongName = 'Stan';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Platters' AND s.SongName = 'Smoke Gets in Your Eyes';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Lionel Richie' AND s.SongName = 'Say You, Say Me';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Mr Big' AND s.SongName = 'To Be With You';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Simon & Garfunkel' AND s.SongName = 'The Sounds of Silence';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Harry Nilsson' AND s.SongName = 'Without You';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Men At Work' AND s.SongName = 'Down Under';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Sheryl Crow' AND s.SongName = 'All I Wanna Do';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Rednex' AND s.SongName = 'Cotton Eye Joe';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'The Rolling Stones' AND s.SongName = 'Jumpin'' Jack Flash';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'UB40' AND s.SongName = 'Red Red Wine';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Soft Cell' AND s.SongName = 'Tainted Love';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'LeAnn Rimes' AND s.SongName = 'Can''t Fight the Moonlight';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Shaggy & Ricardo ''RikRok'' Ducent' AND s.SongName = 'It Wasn''t Me';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Teresa Brewer' AND s.SongName = '(Put Another Nickel In) Music! Music! Music!';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Dexys Midnight Runners' AND s.SongName = 'Come On Eileen';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Bruno Mars' AND s.SongName = 'Just the Way You Are';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Rocco Granata' AND s.SongName = 'Marina';
INSERT IGNORE INTO ArtistSong (ArtistId, SongId) SELECT a.ArtistId, s.SongId FROM Artist a, Song s WHERE a.ArtistName = 'Jennifer Lopez' AND s.SongName = 'If You Had My Love';

-- ----------------
-- SongGenre
-- ----------------
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'White Christmas' AND g.GenreName = 'Jazz/Classical';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Rock Around the Clock' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'My Heart Will Go On' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Nothing Compares 2 U' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Hey Jude' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = '(Everything I Do) I Do it For You' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Will Always Love You' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Another Brick in the Wall (part 2)' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Flashdance... What a Feeling' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Candle in the Wind ''97' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = '(I Can''t Get No) Satisfaction' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Gangsta''s Paradise' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Lose Yourself' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Believe' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Yeah!' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Let it Be' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'A Whiter Shade of Pale' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Stayin'' Alive' AND g.GenreName = 'Disco';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Bleeding Love' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Every Breath You Take' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Bette Davis Eyes' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Umbrella' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'My Sweet Lord' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Dancing Queen' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I''ll Be Missing You' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Baby One More Time' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Want to Hold Your Hand' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Billie Jean' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Mack the Knife' AND g.GenreName = 'Jazz/Classical';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'You''re the One That I Want' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'We Are the World' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Mmmbop' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Vogue' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Wannabe' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Oh, Pretty Woman' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Without Me' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'YMCA' AND g.GenreName = 'Disco';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Just Called to Say I Love You' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Careless Whisper' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Imagine' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Eye of the Tiger' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Macarena' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Are You Lonesome Tonight?' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Can''t Help Falling in Love' AND g.GenreName = 'Reggae';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Hey Ya!' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Bohemian Rhapsody' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'A Woman in Love' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Kissed A Girl' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Over the Rainbow' AND g.GenreName = 'Jazz/Classical';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'It''s Now Or Never' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Don''t Speak' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Hips don''t lie' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'In Da Club' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Can''t Get You Out of My Head' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Where is the Love?' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Angie' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'In the Summertime' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = '(Ghost) Riders in the Sky' AND g.GenreName = 'Jazz/Classical';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Poker Face' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'The Sign' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Kung Fu Fighting' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Sexyback' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Hung Up' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Jailhouse Rock' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Help!' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Love Rock ''n'' Roll' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Livin'' La Vida Loca' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I''m a Believer' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Whenever, Wherever' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'We Found Love' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Strangers in the Night' AND g.GenreName = 'Jazz/Classical';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Streets of Philadelphia' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Unchained Melody' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Swear' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'In the Mood' AND g.GenreName = 'Jazz/Classical';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Mambo No 5 (A Little Bit of ...)' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Que sera sera (Whatever will be will be)' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Low' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Mona Lisa' AND g.GenreName = 'Jazz/Classical';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Seasons in the Sun' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Karma Chameleon' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Don''t Want to Miss a Thing' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Heart of Glass' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'End of the Road' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Killing Me Softly With His Song' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Tie a Yellow Ribbon ''round the Old Oak Tree' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Big Girls Don''t Cry' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Venus' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Hotel California' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Swinging On a Star' AND g.GenreName = 'Jazz/Classical';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'All You Need is Love' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'The Twist' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Dilemma' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'She Loves You' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Crazy in Love' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Gotta Feeling' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = '(Just Like) Starting Over' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Do You Really Want to Hurt Me?' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'The Boy is Mine' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Like a Prayer' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Beautiful Girls' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'When Doves Cry' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Yesterday' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Don''t Cha' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Night Fever' AND g.GenreName = 'Disco';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Upside Down' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Music' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'How You Remind Me' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Sugar Sugar' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Lady Marmalade (Voulez-Vous Coucher Aver Moi Ce Soir?)' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Take On Me' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'The Ketchup Song (Asereje)' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Get Back' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Smooth' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Informer' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Apologize' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'All the Things She Said' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Back For Good' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Hello, Goodbye' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'If You Leave Me Now' AND g.GenreName = 'Disco';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Barbie Girl' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Crazy' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Call Me' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Wanna Dance With Somebody (Who Loves Me)' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Don''t Go Breaking My Heart' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'All That She Wants' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Rivers of Babylon' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Black Or White' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Bridge Over Troubled Water' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Le Freak' AND g.GenreName = 'Disco';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'No Scrubs' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'These Boots Are Made For Walking' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Can''t Stop Loving You' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I''d Do Anything For Love (But I Won''t Do That)' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Let''s Twist Again' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Theme From ''A Summer Place''' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Party Rock Anthem' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'You''re Beautiful' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'American Pie' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Stand By Me' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'All For Love' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'So What' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Another Day in Paradise' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Ebony & Ivory' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Just Dance' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Blue (Da Ba Dee)' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Downtown' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Beat It' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Don''t You Want Me' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Never Gonna Give You Up' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I''ve Been Thinking About You' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Tom Dooley' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Don''t Fence Me In' AND g.GenreName = 'Jazz/Classical';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Take My Breath Away' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Irreplaceable' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Smells Like Teen Spirit' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Beautiful Day' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Buttons & Bows' AND g.GenreName = 'Jazz/Classical';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Girlfriend' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Rock Your Baby' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Will Survive' AND g.GenreName = 'Disco';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Without You' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Waterloo' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Vaya Con Dios (may God Be With You)' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Ice Ice Baby' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Third Man Theme' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Fernando' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Believe I Can Fly' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Complicated' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Penny Lane' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Love The Way You Lie' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Rolling In The Deep' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Secret Love' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = '(Let''s Get) Physical' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I''ll Make Love to You' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Four Minutes' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Have You Ever Really Loved a Woman?' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'U Can''t Touch This' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Somebody That I Used to Know' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Stars On 45' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Funkytown' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Too Young' AND g.GenreName = 'Jazz/Classical';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Want it That Way' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Because You Loved Me' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Rock Me Amadeus' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Grenade' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Good Vibrations' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = '(The Lights Went Out In) Massachusetts' AND g.GenreName = 'Disco';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'That''s What Friends Are For' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'House of the Rising Sun' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Toxic' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Girls Just Wanna Have Fun' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Get the Party Started' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Sixteen Tons' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Those Were the Days' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Feel Fine' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'You Belong to Me' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Paperback Writer' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Beg Your Pardon (I Never Promised You a Rose Garden)' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'What''s Love Got to Do With It?' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Do They Know It''s Christmas?' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Honky Tonk Woman' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'One Sweet Day' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Killing Me Softly With His Song' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Hot ''n'' cold' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Waterfalls' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'It Must Have Been Love' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Tragedy' AND g.GenreName = 'Disco';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'A Hard Day''s Night' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'La Bamba' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Mister Sandman' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Maggie May' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'A Groovy Kind of Love' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'In the Year 2525 (Exordium & Terminus)' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Fantasy' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Faith' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'I Want to Know What Love Is' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Heartbreak Hotel' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Beautiful Liar' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Suspicious Minds' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Crocodile Rock' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Papa Don''t Preach' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Un-Break My Heart' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Shut Up' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Tears in Heaven' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'You''re So Vain' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Men in Black' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Bring Me to Life' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Endless Love' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Let''s Dance' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Abracadabra' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Love is All Around' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Lonely' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'You Are Not Alone' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Genie in a Bottle' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Missing' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Truly Madly Deeply' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Paper Doll' AND g.GenreName = 'Jazz/Classical';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Don''t Worry Be Happy' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'How Deep is Your Love?' AND g.GenreName = 'Disco';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Fallin''' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'F**k it (I Don''t Want You Back)' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Boombastic' AND g.GenreName = 'Reggae';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Tennessee Waltz' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Relax' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Bad Romance' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Hound Dog' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Frozen' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Beautiful' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Tubthumping' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Blueberry Hill' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'A Little Less Conversation' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Volare' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'No One' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Hot Stuff' AND g.GenreName = 'Disco';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'West End Girls' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Walk Like an Egyptian' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'We Belong Together' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Bad Day' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'What''s Up?' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'That''s the Way Love Goes' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Another One Bites the Dust' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Call Me Maybe' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Centrefold' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Promiscuous' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Born to Be Alive' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Mr Vain' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'With Or Without You' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Don''t Stop the Music' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Kiss From a Rose' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Always' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Please Forgive Me' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Speedy Gonzales' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Shout' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Total Eclipse of the Heart' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Wake Me Up Before You Go Go' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Sh-Boom (Life Could Be a Dream)' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Boulevard of Broken Dreams' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Yellow Submarine' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = '(I''ve Had) the Time of My Life' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Blaze of Glory' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Stan' AND g.GenreName = 'Hip-Hop/Rap';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Smoke Gets in Your Eyes' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Say You, Say Me' AND g.GenreName = 'R&B/Soul';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'To Be With You' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'The Sounds of Silence' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Without You' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Down Under' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'All I Wanna Do' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Cotton Eye Joe' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Jumpin'' Jack Flash' AND g.GenreName = 'Rock';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Red Red Wine' AND g.GenreName = 'Reggae';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Tainted Love' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Can''t Fight the Moonlight' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'It Wasn''t Me' AND g.GenreName = 'Reggae';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = '(Put Another Nickel In) Music! Music! Music!' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Come On Eileen' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Just the Way You Are' AND g.GenreName = 'Pop';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'Marina' AND g.GenreName = 'Rock and Roll';
INSERT IGNORE INTO SongGenre (SongId, GenreId) SELECT s.SongId, g.GenreId FROM Song s, Genre g WHERE s.SongName = 'If You Had My Love' AND g.GenreName = 'Pop';