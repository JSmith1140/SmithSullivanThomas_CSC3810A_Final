package DatabasesFinal;

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
        // Connect to H2 in MySQL compatibility mode
        conn = DriverManager.getConnection("jdbc:h2:mem:test;MODE=MySQL;DB_CLOSE_DELAY=-1", "sa", "");

        // Create tables
        createTables();

        // Insert test data
        insertTestData();

        // Create stored procedures
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
        // Insert test data
        try (Statement stmt = conn.createStatement()) {
            stmt.execute("INSERT INTO Users (UserName) VALUES ('user1'), ('user2')");
            stmt.execute("INSERT INTO Song (SongName, DurationSeconds) VALUES ('Song1', 180), ('Song2', 200), ('Song3', 150)");
            stmt.execute("INSERT INTO Artist (ArtistName) VALUES ('Artist1'), ('Artist2')");
            stmt.execute("INSERT INTO Genre (GenreName) VALUES ('Rock'), ('Pop')");
            stmt.execute("INSERT INTO ArtistSong VALUES (1, 1), (1, 2), (2, 3)");
            stmt.execute("INSERT INTO SongGenre VALUES (1, 1), (2, 1), (3, 2)");
            stmt.execute("INSERT INTO UserSong (UserId, SongId, Plays, SecondsListened, LastPlayed, TimesSkipped) VALUES (1, 1, 5, 900, '2023-01-01', 1), (1, 2, 3, 600, '2023-01-02', 0)");
            stmt.execute("INSERT INTO Playlist (PlaylistName, UserId) VALUES ('Playlist1', 1)");
            stmt.execute("INSERT INTO PlaylistSong VALUES (1, 1), (1, 2)");
        }
    }

    private static void createStoredProcedures() throws SQLException {
        // Create stored procedures using MySQL syntax (H2 in MySQL mode)
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

    private static int getDuration(Connection conn, int songId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("SELECT DurationSeconds FROM Song WHERE SongId = ?")) {
            ps.setInt(1, songId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

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

    @Test
    void testAddSongToPlaylist() throws SQLException {
        // First create a playlist
        int playlistId = createTestPlaylist();

        try (CallableStatement cs = conn.prepareCall("{CALL AddSongToPlaylist(?, ?)}")) {
            cs.setInt(1, playlistId);
            cs.setInt(2, 3); // Song3
            cs.execute();
        }

        // Verify
        try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM PlaylistSong WHERE PlaylistId = ? AND SongId = ?")) {
            ps.setInt(1, playlistId);
            ps.setInt(2, 3);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt(1));
            }
        }
    }

    @Test
    void testGetPlaylistSongs() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL GetPlaylistSongs(?)}")) {
            cs.setInt(1, 1); // Existing playlist
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

    @Test
    void testSongPlay() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL SongPlay(?, ?, ?)}")) {
            cs.setInt(1, 1);
            cs.setInt(2, 3); // Song3, not played before
            cs.setInt(3, 100);
            cs.execute();
        }

        // Verify
        try (PreparedStatement ps = conn.prepareStatement("SELECT Plays, SecondsListened FROM UserSong WHERE UserId = ? AND SongId = ?")) {
            ps.setInt(1, 1);
            ps.setInt(2, 3);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt("Plays"));
                assertEquals(100, rs.getInt("SecondsListened"));
            }
        }
    }

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

    @Test
    void testSongSkip() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL SongSkip(?, ?)}")) {
            cs.setInt(1, 1);
            cs.setInt(2, 1);
            cs.execute();
        }

        // Verify skip count increased
        try (PreparedStatement ps = conn.prepareStatement("SELECT TimesSkipped FROM UserSong WHERE UserId = ? AND SongId = ?")) {
            ps.setInt(1, 1);
            ps.setInt(2, 1);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(2, rs.getInt(1)); // Was 1, now 2
            }
        }
    }

    @Test
    void testBlacklistSong() throws SQLException {
        try (CallableStatement cs = conn.prepareCall("{CALL BlacklistSong(?, ?)}")) {
            cs.setInt(1, 1);
            cs.setInt(2, 3);
            cs.execute();
        }

        // Verify song is blacklisted
        try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM SongBlacklist WHERE UserId = ? AND SongId = ?")) {
            ps.setInt(1, 1);
            ps.setInt(2, 3);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(1, rs.getInt(1));
            }
        }
    }

    @Test
    void testGetBlacklist() throws SQLException {
        // Add to blacklist first
        try (PreparedStatement ps = conn.prepareStatement("INSERT INTO SongBlacklist VALUES (1, 1)")) {
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

    @Test
    void testRemoveSongFromPlaylist() throws SQLException {
        // Add song first
        try (PreparedStatement ps = conn.prepareStatement("INSERT INTO PlaylistSong VALUES (1, 3)")) {
            ps.executeUpdate();
        }

        try (CallableStatement cs = conn.prepareCall("{CALL RemoveSongFromPlaylist(?, ?)}")) {
            cs.setInt(1, 1);
            cs.setInt(2, 3);
            cs.execute();
        }

        // Verify removed
        try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM PlaylistSong WHERE PlaylistId = ? AND SongId = ?")) {
            ps.setInt(1, 1);
            ps.setInt(2, 3);
            try (ResultSet rs = ps.executeQuery()) {
                assertTrue(rs.next());
                assertEquals(0, rs.getInt(1));
            }
        }
    }