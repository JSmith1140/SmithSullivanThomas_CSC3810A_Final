DROP DATABASE IF EXISTS MusicPlayer;

CREATE DATABASE MusicPlayer;

USE MusicPlayer;

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

CREATE TABLE IF NOT EXISTS Playlist (
	PlaylistId INT NOT NULL AUTO_INCREMENT,
    PlaylistName VARCHAR(100) NOT NULL,
    PRIMARY KEY (PlaylistId)
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
    INSERT INTO Playlist (PlaylistName) VALUES (in_PlaylistName);
    SET out_PlaylistId = LAST_INSERT_ID();
    INSERT INTO UserPlaylist (PlaylistId, UserId) VALUES (out_PlaylistId, in_UserId);
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
CREATE PROCEDURE GetPlaylistsByUser(IN in_UserId INT)
BEGIN
    SELECT p.PlaylistId, p.PlaylistName FROM Playlist p JOIN UserPlaylist up ON up.PlaylistId = p.PlaylistId WHERE up.UserId = in_UserId ORDER BY p.PlaylistName;
END$$

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

DELIMITER ;

