DROP DATABASE IF EXISTS MusicPlayer;

CREATE DATABASE MusicPlayer;

USE MusicPlayer;

CREATE TABLE IF NOT EXISTS Song (
	SongId INT NOT NULL AUTO_INCREMENT,
    SongName VARCHAR(100) NOT NULL,
    Genre VARCHAR(50),
    DurationSeconds INT,
    PRIMARY KEY (SongId)
);

CREATE TABLE IF NOT EXISTS Genre (
	GenreId INT NOT NULL AUTO_INCREMENT,
    GenreName VARCHAR(50) NOT NULL,
    PRIMARY KEY (GenreId)
);

CREATE TABLE IF NOT EXISTS SongGenre (
	SongId INT NOT NULL,
    GenreId INT NOT NULL,
    PRIMARY KEY (SongId, GenreId),
    FOREIGN KEY (GenreId) REFERENCES Genre(GenreId),
    FOREIGN KEY (SongId) REFERENCES Song(SongId)
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
    FOREIGN KEY (ArtistId) REFERENCES Artist(ArtistId),
    FOREIGN KEY (SongId) REFERENCES Song(SongId)
);

CREATE TABLE IF NOT EXISTS Users (
	UserId INT NOT NULL AUTO_INCREMENT,
    UserName VARCHAR(100) NOT NULL,
    PRIMARY KEY (UserId)
);

CREATE TABLE IF NOT EXISTS UserSong (
	UserId INT NOT NULL,
	SongId INT NOT NULL,
    Plays INT,
    SecondsListened INT,
    LastPlayed Date,
    TimesSkipped INT,
    PRIMARY KEY (UserId, SongId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (SongId) REFERENCES Song(SongId)
);

CREATE TABLE IF NOT EXISTS Playlist (
	PlaylistId INT NOT NULL AUTO_INCREMENT,
    PlaylistName VARCHAR(100) NOT NULL,
    PRIMARY KEY (PlaylistId)
);

CREATE TABLE IF NOT EXISTS SongPlaylist (
	PlaylistId INT NOT NULL,
    SongId INT NOT NULL,
    PRIMARY KEY (PlaylistId, SongId),
    FOREIGN KEY (PlaylistId) REFERENCES Playlist(PlaylistId),
    FOREIGN KEY (SongId) REFERENCES Song(SongId)
);

CREATE TABLE IF NOT EXISTS UserPlaylist (
	PlaylistId INT NOT NULL,
    UserId INT NOT NULL,
    PRIMARY KEY (PlaylistId, UserId),
    FOREIGN KEY (PlaylistId) REFERENCES Playlist(PlaylistId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

CREATE TABLE IF NOT EXISTS SongBlacklist (
	UserId INT NOT NULL,
	SongId INT NOT NULL,
    PRIMARY KEY (UserId, SongId),
    FOREIGN KEY (UserId) REFERENCES Users(UserId),
    FOREIGN KEY (SongId) REFERENCES Song(SongId)
);
