package src.test.junit;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import java.sql.*;
import java.util.*;

class StoredProceduresTest {

    private static Connection conn;

    @BeforeAll
    static void setUpDatabase() throws SQLException {
        conn = DriverManager.getConnection("jdbc:h2:mem:test;MODE=MySQL;DB_CLOSE_DELAY=-1", "sa", "");
        createTables();
        insertTestData();
        createStoredProcedures();
    }

    @AfterAll
    static void tearDownDatabase() throws SQLException {
        if (conn != null) {
            conn.close();
        }
    }

    private static void createTables() throws SQLException {
        String[] createStatements = {
                "CREATE TABLE Song (SongId INT AUTO_INCREMENT PRIMARY KEY, SongName VARCHAR(100) NOT NULL, DurationSeconds INT)",
                "CREATE TABLE Genre (GenreId INT AUTO_INCREMENT PRIMARY KEY, GenreName VARCHAR(50) NOT NULL UNIQUE)",
                "CREATE TABLE SongGenre (SongId INT NOT NULL, GenreId INT NOT NULL, PRIMARY KEY (SongId, GenreId), FOREIGN KEY (GenreId) REFERENCES Genre(GenreId), FOREIGN KEY (SongId) REFERENCES Song(SongId))",
                "CREATE TABLE Artist (ArtistId INT AUTO_INCREMENT PRIMARY KEY, ArtistName VARCHAR(100) NOT NULL)",
                "CREATE TABLE ArtistSong (ArtistId INT NOT NULL, SongId INT NOT NULL, PRIMARY KEY (ArtistId, SongId), FOREIGN KEY (ArtistId) REFERENCES Artist(ArtistId), FOREIGN KEY (SongId) REFERENCES Song(SongId))",
                "CREATE TABLE Users (UserId INT AUTO_INCREMENT PRIMARY KEY, UserName VARCHAR(100) NOT NULL UNIQUE)",
                "CREATE TABLE UserSong (UserId INT NOT NULL, SongId INT NOT NULL, Plays INT DEFAULT 0, SecondsListened INT DEFAULT 0, LastPlayed DATE, TimesSkipped INT DEFAULT 0, PRIMARY KEY (UserId, SongId), FOREIGN KEY (UserId) REFERENCES Users(UserId), FOREIGN KEY (SongId) REFERENCES Song(SongId))",
                "CREATE TABLE Playlist (PlaylistId INT AUTO_INCREMENT PRIMARY KEY, PlaylistName VARCHAR(100) NOT NULL, UserId INT NOT NULL, FOREIGN KEY (UserId) REFERENCES Users(UserId))",
                "CREATE TABLE PlaylistSong (PlaylistId INT NOT NULL, SongId INT NOT NULL, PRIMARY KEY (PlaylistId, SongId), FOREIGN KEY (PlaylistId) REFERENCES Playlist(PlaylistId), FOREIGN KEY (SongId) REFERENCES Song(SongId))",
                "CREATE TABLE SongBlacklist (UserId INT NOT NULL, SongId INT NOT NULL, PRIMARY KEY (UserId, SongId), FOREIGN KEY (UserId) REFERENCES Users(UserId), FOREIGN KEY (SongId) REFERENCES Song(SongId))"
        };

        for (String sql : createStatements) {
            try (Statement stmt = conn.createStatement()) {
                stmt.execute(sql);
            }
        }
    }

    private static void insertTestData() throws SQLException {
        try (Statement stmt = conn.createStatement()) {
            stmt.execute("INSERT INTO Users (UserName) VALUES ('user1'), ('user2')");
            stmt.execute(
                    "INSERT INTO Song (SongName, DurationSeconds) VALUES ('Song1', 180), ('Song2', 200), ('Song3', 150)");
            stmt.execute("INSERT INTO Artist (ArtistName) VALUES ('Artist1'), ('Artist2')");
            stmt.execute("INSERT INTO Genre (GenreName) VALUES ('Rock'), ('Pop')");
            stmt.execute("INSERT INTO ArtistSong VALUES (1, 1), (1, 2), (2, 3)");
            stmt.execute("INSERT INTO SongGenre VALUES (1, 1), (2, 1), (3, 2)");
            stmt.execute(
                    "INSERT INTO UserSong (UserId, SongId, Plays, SecondsListened, LastPlayed, TimesSkipped) VALUES (1, 1, 5, 900, '2023-01-01', 1), (1, 2, 3, 600, '2023-01-02', 0)");
            stmt.execute("INSERT INTO Playlist (PlaylistName, UserId) VALUES ('Playlist1', 1)");
            stmt.execute("INSERT INTO PlaylistSong VALUES (1, 1), (1, 2)");
        }
    }

    private static void createStoredProcedures() throws SQLException {
        String[] procedures = {
                "CREATE PROCEDURE CreatePlaylist(IN in_UserId INT, IN in_PlaylistName VARCHAR(100), OUT out_PlaylistId INT) BEGIN INSERT INTO Playlist (PlaylistName, UserId) VALUES (in_PlaylistName, in_UserId); SET out_PlaylistId = LAST_INSERT_ID(); END",
                "CREATE PROCEDURE AddSongToPlaylist(IN in_PlaylistId INT, IN in_SongId INT) BEGIN INSERT IGNORE INTO PlaylistSong (PlaylistId, SongId) VALUES (in_PlaylistId, in_SongId); END",
                "CREATE PROCEDURE RemoveSongFromPlaylist(IN in_PlaylistId INT, IN in_SongId INT) BEGIN DELETE FROM PlaylistSong WHERE PlaylistId = in_PlaylistId AND SongId = in_SongId; END",
                "CREATE PROCEDURE GetPlaylistSongs(IN in_PlaylistId INT) BEGIN SELECT Song.SongId, SongName FROM PlaylistSong INNER JOIN Song ON PlaylistSong.SongId = Song.SongId WHERE PlaylistSong.PlaylistId = in_PlaylistId; END",
                "CREATE PROCEDURE GetPlaylistsByUser(IN p_userId INT) BEGIN SELECT PlaylistId, PlaylistName FROM Playlist WHERE UserId = p_userId; END",
                "CREATE PROCEDURE SongPlay(IN in_UserId INT, IN in_SongId INT, IN in_SecondsPlayed INT) BEGIN DECLARE v_Duration INT DEFAULT 0; IF in_SecondsPlayed = -1 THEN SELECT DurationSeconds INTO v_Duration FROM Song WHERE SongId = in_SongId; ELSE SET v_Duration = in_SecondsPlayed; END IF; INSERT INTO UserSong (UserId, SongId, Plays, SecondsListened, LastPlayed) VALUES (in_UserId, in_SongId, 1, v_Duration, CURDATE()) ON DUPLICATE KEY UPDATE Plays = Plays + 1, SecondsListened = SecondsListened + v_Duration, LastPlayed = CURDATE(); END",
                "CREATE PROCEDURE SongSkip(IN in_UserId INT, IN in_SongId INT) BEGIN INSERT INTO UserSong (UserId, SongId, TimesSkipped) VALUES (in_UserId, in_SongId, 1) ON DUPLICATE KEY UPDATE TimesSkipped = TimesSkipped + 1; END",
                "CREATE PROCEDURE BlacklistSong(IN in_UserId INT, IN in_SongId INT) BEGIN INSERT IGNORE INTO SongBlacklist (UserId, SongId) VALUES (in_UserId, in_SongId); END",
                "CREATE PROCEDURE GetBlacklist(IN in_UserId INT) BEGIN SELECT sb.SongId, s.SongName FROM SongBlacklist sb JOIN Song s ON s.SongId = sb.SongId WHERE sb.UserId = in_UserId ORDER BY s.SongName; END",
                "CREATE PROCEDURE GetUserSongStats(IN in_UserId INT) BEGIN SELECT us.SongId, s.SongName, s.DurationSeconds, us.Plays, us.SecondsListened, us.TimesSkipped, us.LastPlayed FROM UserSong us JOIN Song s ON s.SongId = us.SongId WHERE us.UserId = in_UserId; END",
                "CREATE PROCEDURE GetUserGenreStats(IN in_UserId INT) BEGIN SELECT g.GenreId, g.GenreName, COUNT(DISTINCT us.SongId) AS UniqueSongs, SUM(us.Plays) AS TotalPlays, SUM(us.SecondsListened) AS TotalSecondsListened, SUM(us.TimesSkipped) AS TotalSkips FROM UserSong us JOIN Song s ON s.SongId = us.SongId JOIN SongGenre sg ON sg.SongId = s.SongId JOIN Genre g ON g.GenreId = sg.GenreId WHERE us.UserId = in_UserId GROUP BY g.GenreId, g.GenreName; END",
                "CREATE PROCEDURE GetUserArtistStats(IN in_UserId INT) BEGIN SELECT a.ArtistId, a.ArtistName, COUNT(DISTINCT us.SongId) AS UniqueSongs, SUM(us.Plays) AS TotalPlays, SUM(us.SecondsListened) AS TotalSecondsListened, SUM(us.TimesSkipped) AS TotalSkips FROM UserSong us JOIN Song s ON s.SongId = us.SongId JOIN ArtistSong asl ON asl.SongId = s.SongId JOIN Artist a ON a.ArtistId = asl.ArtistId WHERE us.UserId = in_UserId GROUP BY a.ArtistId, a.ArtistName; END",
                "CREATE PROCEDURE GetArtistOfSong(IN in_SongId INT) BEGIN SELECT a.ArtistId, a.ArtistName FROM ArtistSong asl JOIN Artist a ON a.ArtistId = asl.ArtistId WHERE asl.SongId = in_SongId; END",
                "CREATE PROCEDURE GetGenreOfSong(IN in_SongId INT) BEGIN SELECT g.GenreId, g.GenreName FROM SongGenre sg JOIN Genre g ON g.GenreId = sg.GenreId WHERE sg.SongId = in_SongId; END",
                "CREATE PROCEDURE CreateJoinedPlaylist(IN in_UserId1 INT, IN in_UserId2 INT, IN in_PlaylistId1 INT, IN in_PlaylistId2 INT, IN in_NewPlaylistName VARCHAR(100), OUT out_NewPlaylistId INT) BEGIN DECLARE done INT DEFAULT 0; DECLARE v_SongId INT; DECLARE cur CURSOR FOR SELECT ps.SongId FROM PlaylistSong ps WHERE ps.PlaylistId = in_PlaylistId1 AND ps.SongId IN (SELECT SongId FROM PlaylistSong WHERE PlaylistId = in_PlaylistId2); DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1; INSERT INTO Playlist (PlaylistName, UserId) VALUES (in_NewPlaylistName, in_UserId1); SET out_NewPlaylistId = LAST_INSERT_ID(); OPEN cur; read_loop: LOOP FETCH cur INTO v_SongId; IF done THEN LEAVE read_loop; END IF; INSERT IGNORE INTO PlaylistSong (PlaylistId, SongId) VALUES (out_NewPlaylistId, v_SongId); END LOOP; CLOSE cur; END",
                "CREATE PROCEDURE GetSongs() BEGIN SELECT SongId, SongName FROM Song; END",
                "CREATE PROCEDURE GetBlacklistIds(IN in_UserId INT) BEGIN SELECT SongId FROM SongBlacklist WHERE UserId = in_UserId; END",
                "CREATE PROCEDURE GetUserArtistScores(IN in_UserId INT) BEGIN SELECT a.ArtistId, SUM(us.Plays) - SUM(us.TimesSkipped) AS Score FROM UserSong us INNER JOIN ArtistSong asl ON us.SongId = asl.SongId INNER JOIN Artist a ON a.ArtistId = asl.ArtistId WHERE us.UserId = in_UserId GROUP BY a.ArtistId; END",
                "CREATE PROCEDURE GetUserGenreScores(IN in_UserId INT) BEGIN SELECT g.GenreId, SUM(us.Plays) - SUM(us.TimesSkipped) AS Score FROM UserSong us INNER JOIN SongGenre sg ON us.SongId = sg.SongId INNER JOIN Genre g ON g.GenreId = sg.GenreId WHERE us.UserId = in_UserId GROUP BY g.GenreId; END",
                "CREATE PROCEDURE GetArtistIdBySong(IN in_SongId INT) BEGIN SELECT ArtistId FROM ArtistSong WHERE SongId = in_SongId LIMIT 1; END",
                "CREATE PROCEDURE GetGenreIdBySong(IN in_SongId INT) BEGIN SELECT GenreId FROM SongGenre WHERE SongId = in_SongId LIMIT 1; END"
        };

        for (String sql : procedures) {
            try (Statement stmt = conn.createStatement()) {
                stmt.execute(sql);
            } catch (SQLException e) {
                System.out.println("Failed to create procedure: " + sql.substring(0, 50) + "... " + e.getMessage());
            }
        }
    }

    // Helper to create a fresh playlist and return its ID
    private int createTestPlaylist() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL CreatePlaylist(?, ?, ?)}")) {
            cs.setInt(1, 1);
            cs.setString(2, "Temp Playlist");
            cs.registerOutParameter(3, Types.INTEGER);
            cs.execute();
            return cs.getInt(3);
        }
    }

    // Happy path: creating a playlist should return a valid new playlist ID
    @Test
    void testCreatePlaylist() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL CreatePlaylist(?, ?, ?)}")) {
            cs.setInt(1, 1);
            cs.setString(2, "Test Playlist");
            cs.registerOutParameter(3, Types.INTEGER);
            cs.execute();
            int playlistId = cs.getInt(3);
            assertTrue(playlistId > 0);
        }
    }

    // Adding a song to a playlist should create the correct entry in PlaylistSong
    @Test
    void testAddSongToPlaylist() throws SQLException {
        int playlistId = createTestPlaylist();

        try (CallableStatement cs = conn.prepareCall("{CALL AddSongToPlaylist(?, ?)}")) {
            cs.setInt(1, playlistId);
            cs.setInt(2, 3);
            cs.execute();
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM PlaylistSong WHERE PlaylistId = ? AND SongId = ?")) {
            ps.setInt(1, playlistId);
            ps.setInt(2, 3);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt(1));
            }
        }
    }

    // Adding the same song twice should not create a duplicate (INSERT IGNORE)
    @Test
    void testAddSongToPlaylistDuplicate() throws SQLException {
        int playlistId = createTestPlaylist();

        try (CallableStatement cs = conn.prepareCall("{CALL AddSongToPlaylist(?, ?)}")) {
            cs.setInt(1, playlistId);
            cs.setInt(2, 1);
            cs.execute();
        }
        try (CallableStatement cs = conn.prepareCall("{CALL AddSongToPlaylist(?, ?)}")) {
            cs.setInt(1, playlistId);
            cs.setInt(2, 1);
            cs.execute();
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM PlaylistSong WHERE PlaylistId = ? AND SongId = ?")) {
            ps.setInt(1, playlistId);
            ps.setInt(2, 1);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt(1), "Duplicate add should not create two rows");
            }
        }
    }

    // Removing a song from a playlist should delete the correct entry from
    // PlaylistSong
    @Test
    void testRemoveSongFromPlaylist() throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("INSERT IGNORE INTO PlaylistSong VALUES (1, 3)")) {
            ps.executeUpdate();
        }

        try (CallableStatement cs = conn.prepareCall("{CALL RemoveSongFromPlaylist(?, ?)}")) {
            cs.setInt(1, 1);
            cs.setInt(2, 3);
            cs.execute();
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM PlaylistSong WHERE PlaylistId = ? AND SongId = ?")) {
            ps.setInt(1, 1);
            ps.setInt(2, 3);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(0, rs.getInt(1));
            }
        }
    }

    // Getting songs from a playlist should return the correct list of songs
    @Test
    void testGetPlaylistSongs() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL GetPlaylistSongs(?)}")) {
            cs.setInt(1, 1);
            try (ResultSet rs = cs.executeQuery()) {
                List<String> songs = new ArrayList<>();
                while (rs.next()) {
                    songs.add(rs.getString("SongName"));
                }
                assertEquals(2, songs.size());
                assertTrue(songs.contains("Song1"));
                assertTrue(songs.contains("Song2"));
            }
        }
    }

    // Getting playlists by user should return all playlists belonging to that user
    @Test
    void testGetPlaylistsByUser() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL GetPlaylistsByUser(?)}")) {
            cs.setInt(1, 1);
            try (ResultSet rs = cs.executeQuery()) {
                assertTrue(rs.next(), "User1 should have at least one playlist");
                assertEquals("Playlist1", rs.getString("PlaylistName"));
            }
        }
    }

    // A user with no playlists should return an empty result set
    @Test
    void testGetPlaylistsByUserNoPlaylists() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL GetPlaylistsByUser(?)}")) {
            cs.setInt(1, 2); // user2 has no playlists
            try (ResultSet rs = cs.executeQuery()) {
                assertFalse(rs.next(), "User with no playlists should return empty result");
            }
        }
    }

    // SongPlay should correctly update UserSong with the number of plays and
    // seconds listened
    // Branch 1: explicit seconds provided
    @Test
    void testSongPlayWithExplicitSeconds() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL SongPlay(?, ?, ?)}")) {
            cs.setInt(1, 1);
            cs.setInt(2, 3); // Song3, not played before
            cs.setInt(3, 100);
            cs.execute();
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT Plays, SecondsListened FROM UserSong WHERE UserId = ? AND SongId = ?")) {
            ps.setInt(1, 1);
            ps.setInt(2, 3);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt("Plays"));
                assertEquals(100, rs.getInt("SecondsListened"));
            }
        }
    }

    // Branch 2: seconds = -1 means use the song's DurationSeconds from the Song
    // table
    @Test
    void testSongPlayUsessongDurationWhenMinusOne() throws SQLException {
        // Song2 has DurationSeconds = 200; user2 has never played it
        try (CallableStatement cs = conn.prepareCall("{CALL SongPlay(?, ?, ?)}")) {
            cs.setInt(1, 2);
            cs.setInt(2, 2);
            cs.setInt(3, -1); // trigger the duration lookup branch
            cs.execute();
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT Plays, SecondsListened FROM UserSong WHERE UserId = ? AND SongId = ?")) {
            ps.setInt(1, 2);
            ps.setInt(2, 2);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt("Plays"));
                assertEquals(200, rs.getInt("SecondsListened"),
                        "Should use song's DurationSeconds (200) when -1 passed");
            }
        }
    }

    // Playing a song a second time should increment Plays and accumulate
    // SecondsListened
    @Test
    void testSongPlayIncrementsOnDuplicate() throws SQLException {
        // user1/song1 already has Plays=5, SecondsListened=900 from test data
        try (CallableStatement cs = conn.prepareCall("{CALL SongPlay(?, ?, ?)}")) {
            cs.setInt(1, 1);
            cs.setInt(2, 1);
            cs.setInt(3, 50);
            cs.execute();
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT Plays, SecondsListened FROM UserSong WHERE UserId = ? AND SongId = ?")) {
            ps.setInt(1, 1);
            ps.setInt(2, 1);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(6, rs.getInt("Plays"));
                assertEquals(950, rs.getInt("SecondsListened"));
            }
        }
    }

    // SongSkip should update UserSong's TimesSkipped, creating a new row if
    // necessary
    // Branch 1: user has never interacted with the song — inserts a new row
    @Test
    void testSongSkipFirstSkipCreatesRow() throws SQLException {
        // user2 has no UserSong row for Song1
        try (CallableStatement cs = conn.prepareCall("{CALL SongSkip(?, ?)}")) {
            cs.setInt(1, 2);
            cs.setInt(2, 1);
            cs.execute();
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT TimesSkipped FROM UserSong WHERE UserId = ? AND SongId = ?")) {
            ps.setInt(1, 2);
            ps.setInt(2, 1);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next(), "Row should be created on first skip");
                assertEquals(1, rs.getInt(1));
            }
        }
    }

    // Branch 2: existing row — skip count is incremented
    @Test
    void testSongSkipIncrementsExistingRow() throws SQLException {
        // user1/song1 already has TimesSkipped=1 from test data
        try (CallableStatement cs = conn.prepareCall("{CALL SongSkip(?, ?)}")) {
            cs.setInt(1, 1);
            cs.setInt(2, 1);
            cs.execute();
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT TimesSkipped FROM UserSong WHERE UserId = ? AND SongId = ?")) {
            ps.setInt(1, 1);
            ps.setInt(2, 1);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(2, rs.getInt(1));
            }
        }
    }

    // Blacklisting a song should create the correct entry in SongBlacklist
    @Test
    void testBlacklistSong() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL BlacklistSong(?, ?)}")) {
            cs.setInt(1, 1);
            cs.setInt(2, 3);
            cs.execute();
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM SongBlacklist WHERE UserId = ? AND SongId = ?")) {
            ps.setInt(1, 1);
            ps.setInt(2, 3);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt(1));
            }
        }
    }

    // Blacklisting the same song twice should not create a duplicate (INSERT
    // IGNORE)
    @Test
    void testBlacklistSongDuplicate() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL BlacklistSong(?, ?)}")) {
            cs.setInt(1, 2);
            cs.setInt(2, 2);
            cs.execute();
        }
        try (CallableStatement cs = conn.prepareCall("{CALL BlacklistSong(?, ?)}")) {
            cs.setInt(1, 2);
            cs.setInt(2, 2);
            cs.execute();
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM SongBlacklist WHERE UserId = ? AND SongId = ?")) {
            ps.setInt(1, 2);
            ps.setInt(2, 2);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt(1), "Duplicate blacklist should not create two rows");
            }
        }
    }

    // Getting a user's blacklist should return the correct list of songs
    @Test
    void testGetBlacklist() throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("INSERT IGNORE INTO SongBlacklist VALUES (1, 1)")) {
            ps.executeUpdate();
        }

        try (CallableStatement cs = conn.prepareCall("{CALL GetBlacklist(?)}")) {
            cs.setInt(1, 1);
            try (ResultSet rs = cs.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt("SongId"));
                assertEquals("Song1", rs.getString("SongName"));
            }
        }
    }

    // Getting user song stats should return the correct aggregated data for each
    // song the user has interacted with
    @Test
    void testGetUserSongStats() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL GetUserSongStats(?)}")) {
            cs.setInt(1, 1);
            try (ResultSet rs = cs.executeQuery()) {
                int count = 0;
                while (rs.next()) {
                    count++;
                    if (rs.getInt("SongId") == 1) {
                        assertEquals("Song1", rs.getString("SongName"));
                        assertEquals(5, rs.getInt("Plays"));
                        assertEquals(1, rs.getInt("TimesSkipped"));
                    }
                }
                assertEquals(2, count);
            }
        }
    }

    // Getting user genre stats should return the correct aggregated data for each
    // genre the user has interacted with
    @Test
    void testGetUserGenreStats() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL GetUserGenreStats(?)}")) {
            cs.setInt(1, 1);
            try (ResultSet rs = cs.executeQuery()) {
                assertTrue(rs.next());
                assertEquals("Rock", rs.getString("GenreName"));
                assertEquals(2, rs.getInt("UniqueSongs"));
                assertEquals(8, rs.getInt("TotalPlays"));
            }
        }
    }

    // Getting user artist stats should return the correct aggregated data for each
    // artist the user has interacted with
    @Test
    void testGetUserArtistStats() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL GetUserArtistStats(?)}")) {
            cs.setInt(1, 1);
            try (ResultSet rs = cs.executeQuery()) {
                assertTrue(rs.next(), "Should return at least one artist row");
                assertEquals("Artist1", rs.getString("ArtistName"));
                assertEquals(2, rs.getInt("UniqueSongs"));
                assertEquals(8, rs.getInt("TotalPlays"));
            }
        }
    }

    // Getting the artist of a song should return the correct artist name
    @Test
    void testGetArtistOfSong() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL GetArtistOfSong(?)}")) {
            cs.setInt(1, 1); // Song1 belongs to Artist1
            try (ResultSet rs = cs.executeQuery()) {
                assertTrue(rs.next());
                assertEquals("Artist1", rs.getString("ArtistName"));
            }
        }
    }

    // Getting the genre of a song should return the correct genre name
    @Test
    void testGetGenreOfSong() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL GetGenreOfSong(?)}")) {
            cs.setInt(1, 1); // Song1 is Rock
            try (ResultSet rs = cs.executeQuery()) {
                assertTrue(rs.next());
                assertEquals("Rock", rs.getString("GenreName"));
            }
        }
    }

    // Getting all songs should return the complete list of songs in the database
    @Test
    void testGetSongs() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL GetSongs()}")) {
            try (ResultSet rs = cs.executeQuery()) {
                List<String> names = new ArrayList<>();
                while (rs.next()) {
                    names.add(rs.getString("SongName"));
                }
                assertEquals(3, names.size());
                assertTrue(names.contains("Song1"));
                assertTrue(names.contains("Song2"));
                assertTrue(names.contains("Song3"));
            }
        }
    }

    // Getting blacklist IDs should return the correct list of song IDs that the
    // user has blacklisted
    @Test
    void testGetBlacklistIds() throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("INSERT IGNORE INTO SongBlacklist VALUES (1, 2)")) {
            ps.executeUpdate();
        }

        try (CallableStatement cs = conn.prepareCall("{CALL GetBlacklistIds(?)}")) {
            cs.setInt(1, 1);
            try (ResultSet rs = cs.executeQuery()) {
                List<Integer> ids = new ArrayList<>();
                while (rs.next()) {
                    ids.add(rs.getInt("SongId"));
                }
                assertTrue(ids.contains(2), "Blacklisted song ID should be returned");
            }
        }
    }

    // User's artist score should be calculated as total plays minus total skips
    // across all songs by that artist
    @Test
    void testGetUserArtistScores() throws SQLException {
        // user1: Song1 plays=5 skips=1, Song2 plays=3 skips=0 — both by Artist1
        // Score for Artist1 = (5+3) - (1+0) = 7
        try (CallableStatement cs = conn.prepareCall("{CALL GetUserArtistScores(?)}")) {
            cs.setInt(1, 1);
            try (ResultSet rs = cs.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(7, rs.getInt("Score"));
            }
        }
    }

    // User's genre score should be calculated as total plays minus total skips
    // across all songs in that genre
    @Test
    void testGetUserGenreScores() throws SQLException {
        // user1 has listened to Rock songs (Song1 + Song2): plays=8, skips=1 → score=7
        try (CallableStatement cs = conn.prepareCall("{CALL GetUserGenreScores(?)}")) {
            cs.setInt(1, 1);
            try (ResultSet rs = cs.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(7, rs.getInt("Score"));
            }
        }
    }

    // Getting the artist ID by song should return the correct artist ID for that
    // song
    @Test
    void testGetArtistIdBySong() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL GetArtistIdBySong(?)}")) {
            cs.setInt(1, 1); // Song1 → Artist1 (ArtistId=1)
            try (ResultSet rs = cs.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt("ArtistId"));
            }
        }
    }

    // Getting the genre ID by song should return the correct genre ID for that song
    @Test
    void testGetGenreIdBySong() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL GetGenreIdBySong(?)}")) {
            cs.setInt(1, 1); // Song1 → Rock (GenreId=1)
            try (ResultSet rs = cs.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt("GenreId"));
            }
        }
    }

    // Creating a joined playlist should create a new playlist containing only the
    // songs that are in both source playlists
    @Test
    void testCreateJoinedPlaylist() throws SQLException {
        // Give user2 a playlist containing Song1 and Song2
        int p2Id;
        try (CallableStatement cs = conn.prepareCall("{CALL CreatePlaylist(?, ?, ?)}")) {
            cs.setInt(1, 2);
            cs.setString(2, "User2Playlist");
            cs.registerOutParameter(3, Types.INTEGER);
            cs.execute();
            p2Id = cs.getInt(3);
        }
        try (PreparedStatement ps = conn.prepareStatement("INSERT INTO PlaylistSong VALUES (?, 1), (?, 2)")) {
            ps.setInt(1, p2Id);
            ps.setInt(2, p2Id);
            ps.executeUpdate();
        }

        // Playlist1 (id=1) contains Song1 and Song2; p2 also contains Song1 and Song2
        // The joined playlist should contain their intersection: Song1 and Song2
        int joinedId;
        try (CallableStatement cs = conn.prepareCall("{CALL CreateJoinedPlaylist(?, ?, ?, ?, ?, ?)}")) {
            cs.setInt(1, 1);
            cs.setInt(2, 2);
            cs.setInt(3, 1);
            cs.setInt(4, p2Id);
            cs.setString(5, "JoinedPlaylist");
            cs.registerOutParameter(6, Types.INTEGER);
            cs.execute();
            joinedId = cs.getInt(6);
        }

        assertTrue(joinedId > 0, "Joined playlist ID should be valid");

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM PlaylistSong WHERE PlaylistId = ?")) {
            ps.setInt(1, joinedId);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(2, rs.getInt(1), "Joined playlist should contain the 2 songs common to both playlists");
            }
        }
    }

    // FD: UserId + SongId → Plays, SecondsListened (each play increments Plays by 1
    // and adds to SecondsListened)
    @Test
    void testFD_SongPlayUpdatesAreDeterministic() throws SQLException {
        // Play Song3 for user2 with 75 seconds, then play again with 25 seconds
        try (CallableStatement cs = conn.prepareCall("{CALL SongPlay(?, ?, ?)}")) {
            cs.setInt(1, 2);
            cs.setInt(2, 3);
            cs.setInt(3, 75);
            cs.execute();
        }
        try (CallableStatement cs = conn.prepareCall("{CALL SongPlay(?, ?, ?)}")) {
            cs.setInt(1, 2);
            cs.setInt(2, 3);
            cs.setInt(3, 25);
            cs.execute();
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT Plays, SecondsListened FROM UserSong WHERE UserId = ? AND SongId = ?")) {
            ps.setInt(1, 2);
            ps.setInt(2, 3);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(2, rs.getInt("Plays"), "Two plays should give Plays=2");
                assertEquals(100, rs.getInt("SecondsListened"), "75+25 seconds should accumulate to 100");
            }
        }
    }

    // FD: UserId + SongId → TimesSkipped (each skip increments by exactly 1)
    @Test
    void testFD_EachSkipIncrementsCountByOne() throws SQLException {
        // user2/song2 starts with no record
        for (int i = 1; i <= 3; i++) {
            try (CallableStatement cs = conn.prepareCall("{CALL SongSkip(?, ?)}")) {
                cs.setInt(1, 2);
                cs.setInt(2, 2);
                cs.execute();
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT TimesSkipped FROM UserSong WHERE UserId = ? AND SongId = ?")) {
                ps.setInt(1, 2);
                ps.setInt(2, 2);
                try (ResultSet rs = ps.executeQuery()) {
                    assertTrue(rs.next());
                    assertEquals(i, rs.getInt(1), "After " + i + " skips, count should be " + i);
                }
            }
        }
    }

    // FD: (UserId, SongId) is unique in SongBlacklist — blacklisting is idempotent
    @Test
    void testFD_BlacklistIsIdempotent() throws SQLException {
        // Blacklist Song3 for user1 three times
        for (int i = 0; i < 3; i++) {
            try (CallableStatement cs = conn.prepareCall("{CALL BlacklistSong(?, ?)}")) {
                cs.setInt(1, 1);
                cs.setInt(2, 3);
                cs.execute();
            }
        }

        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM SongBlacklist WHERE UserId = ? AND SongId = ?")) {
            ps.setInt(1, 1);
            ps.setInt(2, 3);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt(1), "Repeated blacklisting must produce exactly one row");
            }
        }
    }

    // FD: ArtistScore = SUM(Plays) - SUM(Skips) for that user+artist combination
    @Test
    void testFD_ArtistScoreMatchesPlaysMinusSkips() throws SQLException {
        // user1: Artist1 covers Song1 (plays=5, skips=1) and Song2 (plays=3, skips=0)
        // Expected score = (5+3) - (1+0) = 7
        try (CallableStatement cs = conn.prepareCall("{CALL GetUserArtistScores(?)}")) {
            cs.setInt(1, 1);
            try (ResultSet rs = cs.executeQuery()) {
                assertTrue(rs.next());
                int score = rs.getInt("Score");
                assertEquals(7, score, "Artist score must equal total plays minus total skips");
            }
        }
    }

    // FD: GenreScore = SUM(Plays) - SUM(Skips) for that user+genre combination
    @Test
    void testFD_GenreScoreMatchesPlaysMinusSkips() throws SQLException {
        // user1: Rock covers Song1 (plays=5, skips=1) and Song2 (plays=3, skips=0)
        // Expected score = (5+3) - (1+0) = 7
        try (CallableStatement cs = conn.prepareCall("{CALL GetUserGenreScores(?)}")) {
            cs.setInt(1, 1);
            try (ResultSet rs = cs.executeQuery()) {
                assertTrue(rs.next());
                int score = rs.getInt("Score");
                assertEquals(7, score, "Genre score must equal total plays minus total skips");
            }
        }
    }
}