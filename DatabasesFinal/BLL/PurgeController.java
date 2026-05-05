package DatabasesFinal.BLL;


import DatabasesFinal.DAL.PurgeDataProvider;

import java.sql.Date;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class PurgeController {

    // A song is removed if it has been skipped more than this many times in total.
    private static final int maxSkips = 20;

    // A song is removed if (skips / plays) exceeds this ratio.
    private static final double maxSkipRatio = 0.5; // 50 %

    // A song is removed if it has not been played within this many months.
    private static final int monthsWithoutPlay = 3;

    // A genre is liked only if the user has listened to at
    // least this many unique songs in that genre.
    private static final int minUniqueForGenre = 3;

    // An artist is liked only if the user has listened to at
    // least this many unique songs by that artist.
    private static final int minUniqueForArtist = 2;

    // DAL provider instance
    private PurgeDataProvider purgeDP = new PurgeDataProvider();

    // Main method to purge a playlist
    public List<String> purgePlaylist(int playlistId, int userId) throws Exception {

        List<String> removedSongs = new ArrayList<>();
        // Verify the playlist belongs to this user before doing anything
        Map<Integer, String> userPlaylists = purgeDP.getPlaylistsByUser(userId);
        if (!userPlaylists.containsKey(playlistId)) {
            System.out.println(
                    "Error: playlist " + playlistId + " does not belong to user " + userId + ". Purge aborted.");
            return removedSongs;
        }

        // Fetch all necessary data from DAL before processing
        Map<Integer, String> playlistSongs = purgeDP.getPlaylistSongs(playlistId);
        Map<Integer, Object[]> songStats = purgeDP.getSongStats(userId);
        Map<Integer, Object[]> genreStats = purgeDP.getGenreStats(userId);
        Map<Integer, Object[]> artistStats = purgeDP.getArtistStats(userId);
        Map<Integer, String> blacklist = purgeDP.getBlacklist(userId);

        // Work on a copy of the song IDs to avoid concurrent modification issues while
        // filtering
        List<Integer> songsToRemove = new ArrayList<>();

        // Song filtering
        for (int songId : playlistSongs.keySet()) {

            // Get the stats for this song, if any
            Object[] stats = songStats.get(songId);

            // If there are no stats for this song the user has never interacted
            // with it, treat it as unplayed and remove it
            if (stats == null) {
                songsToRemove.add(songId);
                removedSongs.add(playlistSongs.get(songId));
                System.out.println("Removing (no play history): " + playlistSongs.get(songId));
                continue;
            }

            int plays = (int) stats[2];
            int timesSkipped = (int) stats[4];
            Date lastPlayed = (Date) stats[5];

            // raw skip count is too high
            if (timesSkipped > maxSkips) {
                songsToRemove.add(songId);
                removedSongs.add(playlistSongs.get(songId));
                System.out.println("Removing (too many skips): " + playlistSongs.get(songId));
                continue;
            }

            // not played in X months
            if (lastPlayed == null || isOlderThanMonths(lastPlayed, monthsWithoutPlay)) {
                songsToRemove.add(songId);
                removedSongs.add(playlistSongs.get(songId));
                System.out.println("Removing (not played recently): " + playlistSongs.get(songId));
                continue;
            }

            // skip ratio is too high
            if (plays > 0) {
                double skipRatio = (double) timesSkipped / plays;
                if (skipRatio > maxSkipRatio) {
                    songsToRemove.add(songId);
                    removedSongs.add(playlistSongs.get(songId));
                    System.out.println("Removing (high skip ratio " + String.format("%.0f", skipRatio * 100)
                            + "%): " + playlistSongs.get(songId));
                    continue;
                }
            }
        }

        // Genre filter
        for (int songId : playlistSongs.keySet()) {
            if (songsToRemove.contains(songId))
                continue; // already removed

            // Get the genres of this song
            Map<Integer, String> songGenres = purgeDP.getGenreOfSong(songId);

            // A song stays only if at least one of its genres is liked.
            boolean keepByGenre = false;
            for (int genreId : songGenres.keySet()) {
                Object[] gStats = genreStats.get(genreId);
                if (gStats != null) {
                    int uniqueSongs = (int) gStats[1];
                    if (uniqueSongs >= minUniqueForGenre) {
                        keepByGenre = true;
                        break;
                    }
                }
            }

            if (!keepByGenre) {
                songsToRemove.add(songId);
                removedSongs.add(playlistSongs.get(songId));
                System.out.println("Removing (unpopular genre): " + playlistSongs.get(songId));
            }
        }

        // Artist filter
        for (int songId : playlistSongs.keySet()) {
            if (songsToRemove.contains(songId))
                continue; // already removed

            // Get the artists of this song
            Map<Integer, String> songArtists = purgeDP.getArtistOfSong(songId);

            // A song stays only if at least one of its artists is liked.
            boolean keepByArtist = false;
            for (int artistId : songArtists.keySet()) {
                Object[] aStats = artistStats.get(artistId);
                if (aStats != null) {
                    int uniqueSongs = (int) aStats[1];
                    if (uniqueSongs >= minUniqueForArtist) {
                        keepByArtist = true;
                        break;
                    }
                }
            }

            if (!keepByArtist) {
                songsToRemove.add(songId);
                removedSongs.add(playlistSongs.get(songId));
                System.out.println("Removing (unpopular artist): " + playlistSongs.get(songId));
            }
        }

        // Blacklist filter
        for (int songId : playlistSongs.keySet()) {
            if (songsToRemove.contains(songId))
                continue; // already removed

            if (blacklist.containsKey(songId)) {
                songsToRemove.add(songId);
                removedSongs.add(playlistSongs.get(songId));
                System.out.println("Removing (blacklisted): " + playlistSongs.get(songId));
            }
        }

        // Perform the actual removals in the database
        System.out.println("Removing " + songsToRemove.size() + " song(s) from playlist " + playlistId);
        for (int songId : songsToRemove) {
            purgeDP.removeSongFromPlaylist(playlistId, songId);
        }
        System.out.println("Purge complete.");
        return removedSongs;
    }

    // Helper method to check if a date is older than a certain number of months
    // from today
    private boolean isOlderThanMonths(Date date, int months) {
        LocalDate cutoff = LocalDate.now().minusMonths(months);
        return date.toLocalDate().isBefore(cutoff);
    }
}