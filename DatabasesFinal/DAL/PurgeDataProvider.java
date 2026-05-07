package DatabasesFinal.DAL;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

public class PurgeDataProvider {

    // helper method to call a stored procedure that takes only userId as input and
    // returns a ResultSet
    private ResultSet callWithUserId(String procedureName, int userId) throws SQLException {
        Connection conn = DataMgr.getConnection();
        String sql = "{CALL " + procedureName + "(?)}";
        CallableStatement stmt = conn.prepareCall(sql);
        stmt.setInt(1, userId);
        return stmt.executeQuery();
    }

    // returns Map<SongId, SongName> for all songs in a playlist
    public Map<Integer, String> getPlaylistSongs(int playlistId) throws SQLException {
        Map<Integer, String> songs = new HashMap<>();

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL GetPlaylistSongs(?)}";

        try (CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, playlistId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                int songId = rs.getInt("SongId");
                String name = rs.getString("SongName");
                songs.put(songId, name);
            }
        }

        return songs;
    }

    // Song stats -- Map<SongId, Object[]>, Object[]: [0] SongName (String), [1]
    // DurationSeconds (int),
    // [2] Plays (int), [3] SecondsListened (int), [4] TimesSkipped (int), [5]
    // LastPlayed (java.sql.Date, may be null)
    public Map<Integer, Object[]> getSongStats(int userId) throws SQLException {
        Map<Integer, Object[]> stats = new HashMap<>();

        try (ResultSet rs = callWithUserId("GetUserSongStats", userId)) {
            while (rs.next()) {
                int songId = rs.getInt("SongId");
                Object[] row = {
                        rs.getString("SongName"),
                        rs.getInt("DurationSeconds"),
                        rs.getInt("Plays"),
                        rs.getInt("SecondsListened"),
                        rs.getInt("TimesSkipped"),
                        rs.getDate("LastPlayed")
                };
                stats.put(songId, row);
            }
        }

        return stats;
    }

    // Genre stats -- Map<GenreId, Object[]>, Object[]: [0] GenreName (String), [1]
    // UniqueSongs (int),
    // [2] TotalPlays (int), [3] TotalSecondsListened (int), [4] TotalSkips (int)
    public Map<Integer, Object[]> getGenreStats(int userId) throws SQLException {
        Map<Integer, Object[]> stats = new HashMap<>();

        try (ResultSet rs = callWithUserId("GetUserGenreStats", userId)) {
            while (rs.next()) {
                int genreId = rs.getInt("GenreId");
                Object[] row = {
                        rs.getString("GenreName"),
                        rs.getInt("UniqueSongs"),
                        rs.getInt("TotalPlays"),
                        rs.getInt("TotalSecondsListened"),
                        rs.getInt("TotalSkips")
                };
                stats.put(genreId, row);
            }
        }

        return stats;
    }

    // Artist stats -- Map<ArtistId, Object[]>, Object[]: [0] ArtistName (String),
    // [1] UniqueSongs (int),
    // [2] TotalPlays (int), [3] TotalSecondsListened (int), [4] TotalSkips (int)
    public Map<Integer, Object[]> getArtistStats(int userId) throws SQLException {
        Map<Integer, Object[]> stats = new HashMap<>();

        try (ResultSet rs = callWithUserId("GetUserArtistStats", userId)) {
            while (rs.next()) {
                int artistId = rs.getInt("ArtistId");
                Object[] row = {
                        rs.getString("ArtistName"),
                        rs.getInt("UniqueSongs"),
                        rs.getInt("TotalPlays"),
                        rs.getInt("TotalSecondsListened"),
                        rs.getInt("TotalSkips")
                };
                stats.put(artistId, row);
            }
        }

        return stats;
    }

    // Blacklist -- Map<SongId, SongName>
    public Map<Integer, String> getBlacklist(int userId) throws SQLException {
        Map<Integer, String> blacklist = new HashMap<>();

        try (ResultSet rs = callWithUserId("GetBlacklist", userId)) {
            while (rs.next()) {
                blacklist.put(rs.getInt("SongId"), rs.getString("SongName"));
            }
        }

        return blacklist;
    }

    // Genres of a specific song -- Map<GenreId, GenreName>
    public Map<Integer, String> getGenreOfSong(int songId) throws SQLException {
        Map<Integer, String> genres = new HashMap<>();

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL GetGenreOfSong(?)}";

        try (CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, songId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                genres.put(rs.getInt("GenreId"), rs.getString("GenreName"));
            }
        }

        return genres;
    }

    // Artists of a specific song -- Map<ArtistId, ArtistName>
    public Map<Integer, String> getArtistOfSong(int songId) throws SQLException {
        Map<Integer, String> artists = new HashMap<>();

        Connection conn = DataMgr.getConnection();
        String sql = "{CALL GetArtistOfSong(?)}";

        try (CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, songId);
            ResultSet rs = stmt.executeQuery();
            while (rs.next()) {
                artists.put(rs.getInt("ArtistId"), rs.getString("ArtistName"));
            }
        }

        return artists;
    }

    // Playlists of a user -- Map<PlaylistId, PlaylistName>
    public Map<Integer, String> getPlaylistsByUser(int userId) throws SQLException {
        Map<Integer, String> playlists = new HashMap<>();

        try (ResultSet rs = callWithUserId("GetPlaylistsByUser", userId)) {
            while (rs.next()) {
                playlists.put(rs.getInt("PlaylistId"), rs.getString("PlaylistName"));
            }
        }

        return playlists;
    }

    // Remove a song from a playlist
    public void removeSongFromPlaylist(int playlistId, int songId) throws SQLException {
        Connection conn = DataMgr.getConnection();
        String sql = "{CALL RemoveSongFromPlaylist(?, ?)}";

        try (CallableStatement stmt = conn.prepareCall(sql)) {
            stmt.setInt(1, playlistId);
            stmt.setInt(2, songId);
            stmt.execute();
        }
    }
}