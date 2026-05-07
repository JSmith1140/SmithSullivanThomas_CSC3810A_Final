package DatabasesFinal.BLL;

import java.util.*;
import DatabasesFinal.DAL.PurgeDataProvider;

public class JoinPlaylistController {

    private PurgeDataProvider purgeDP = new PurgeDataProvider();

    private static final int maxSkips = 25; // maxskips
    private static final double maxSkipRatio = 0.5; //maxskipratio

    /***
     * Method to build a joint playlist
     * @param user1
     * @param user2
     * @param p1
     * @param p2
     * @return
     * @throws Exception
     */
    public List<SongCandidate> buildJointPlaylist(int user1, int user2, int p1, int p2) throws Exception {

        // get playlist for both users
        Map<Integer, String> playlist1 = purgeDP.getPlaylistSongs(p1);
        Map<Integer, String> playlist2 = purgeDP.getPlaylistSongs(p2);

        // get song stats for both users
        Map<Integer, Object[]> songStats1 = purgeDP.getSongStats(user1);
        Map<Integer, Object[]> songStats2 = purgeDP.getSongStats(user2);

        // place all songs into a hash set
        Set<Integer> allSongs = new HashSet<>();
        allSongs.addAll(playlist1.keySet());
        allSongs.addAll(playlist2.keySet());

        List<SongCandidate> finalSongs = new ArrayList<>();

        for (int songId : allSongs) {

            Object[] stats1 = songStats1.get(songId);
            Object[] stats2 = songStats2.get(songId);

            String songName = playlist1.getOrDefault(songId,
                                playlist2.getOrDefault(songId, "Unknown Song"));

            String artist = (stats1 != null)
                    ? (String) stats1[0]
                    : (stats2 != null ? (String) stats2[0] : "Unknown Artist");

            int plays1 = (stats1 != null) ? (int) stats1[2] : 0;
            int plays2 = (stats2 != null) ? (int) stats2[2] : 0;

            int skips1 = (stats1 != null) ? (int) stats1[4] : 0;
            int skips2 = (stats2 != null) ? (int) stats2[4] : 0;

            int lastPlayed1;

            if (stats1 != null && stats1[5] != null) {
                Date d1 = (Date) stats1[5];

                long diffMillis = System.currentTimeMillis() - d1.getTime();
                lastPlayed1 = (int) (diffMillis / (1000 * 60 * 60 * 24));
            } else {
                lastPlayed1 = -1;
            }

            int lastPlayed2;

            if (stats2 != null && stats2[5] != null) {
                Date d2 = (Date) stats2[5];

                long diffMillis = System.currentTimeMillis() - d2.getTime();
                lastPlayed2 = (int) (diffMillis / (1000 * 60 * 60 * 24));
            } else {
                lastPlayed2 = -1;
            }

            System.out.println("\nChecking: " + songName);

            // If either user hasn't played the song in a while don't include
            int maxDays = 100;
            if (lastPlayed1 > maxDays || lastPlayed2 > maxDays) {
                System.out.println("Removed (too old)");
                continue;
            }

            // if either user has skipped a lot remove it
            if (skips1 >= maxSkips || skips2 >= maxSkips) {
                System.out.println("Removed (too many skips)");
                continue;
            }

            // if either users skip ratio is over 50% remove it
            if (plays1 > 0 && skips1 / (double) plays1 > maxSkipRatio || plays2 > 0 && skips2 / (double) plays2 > maxSkipRatio) {
                System.out.println("Removed (skip ratio)");
                continue;
            }

            // if either user has less than 20 plays remove it
            if (plays1 < 20 || plays2 < 20) {
                System.out.println(lastPlayed2);
                System.out.println("Removed (insufficient plays)");
                continue;
            }

            SongCandidate candidate = new SongCandidate(
                    songId,
                    songName,
                    "JOIN",
                    artist,
                    Math.max(plays1, plays2),
                    Math.max(skips1, skips2),
                    Math.max(lastPlayed1, lastPlayed2)
            );

            System.out.println("Added: " + songName);

            finalSongs.add(candidate);
        }
        return finalSongs;
    }
}
