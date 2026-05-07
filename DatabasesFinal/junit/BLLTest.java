package junit;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

import java.sql.Date;
import java.time.LocalDate;
import java.util.*;

import DatabasesFinal.BLL.*;

// Note: these tests are not exhaustive, but they cover a representative sample of the logic in each controller.
class BLLTest {

    // Test the basic getters of our data classes to ensure they return the expected
    // values.
    @Test
    void testSongCandidateGetters() {
        SongCandidate song = new SongCandidate(1, "Test Song", "ARTIST", "Artist A", 10, 2, 5);
        assertEquals(1, song.getSongId());
        assertEquals("Test Song", song.getSongName());
        assertEquals("ARTIST", song.getSource());
        assertEquals("Artist A", song.getArtist());
        assertEquals(10, song.getPlays());
        assertEquals(2, song.getSkips());
        assertEquals(5, song.getLastPlayed());
    }

    @Test
    void testScoredSongGetters() {
        SongCandidate song = new SongCandidate(2, "Song", "GENRE", "Artist", 5, 0, 3);
        ScoredSong scored = new ScoredSong(song, 75);
        assertEquals(75, scored.getScore());
        assertSame(song, scored.getSong());
    }

    @Test
    void testPlaylistStatGetters() {
        Date today = Date.valueOf(LocalDate.now());
        PlaylistStat stat = new PlaylistStat("My Song", 5, 1, today);
        assertEquals("My Song", stat.getSongName());
        assertEquals(5, stat.getPlays());
        assertEquals(1, stat.getSkips());
        assertEquals(today, stat.getLastPlayed());
    }

    // TestableAutoPlaylist allows us to inject controlled candidates and blacklist
    // for testing the scoring logic without needing a real database.
    static class TestableAutoPlaylist extends AutoPlaylistController {
        private final List<SongCandidate> candidates;
        private final Set<Integer> blacklist;

        TestableAutoPlaylist(List<SongCandidate> candidates, Set<Integer> blacklist) {
            this.candidates = candidates;
            this.blacklist = blacklist;
        }

        @Override
        protected List<SongCandidate> fetchCandidates(int userId, String a1, String a2, String a3) {
            return candidates;
        }

        @Override
        protected Set<Integer> fetchBlacklist(int userId) {
            return blacklist;
        }
    }

    private List<ScoredSong> score(List<SongCandidate> candidates, Set<Integer> blacklist) throws Exception {
        return new TestableAutoPlaylist(candidates, blacklist).buildAutoPlaylist(1, "x", "y", "z");
    }

    private SongCandidate song(int id, String source, int plays, int skips, int days) {
        return new SongCandidate(id, "Song" + id, source, "Artist", plays, skips, days);
    }

    @Test
    void testBlacklistedSongIsExcluded() throws Exception {
        SongCandidate s = song(99, "ARTIST", 50, 0, 7);
        List<ScoredSong> result = score(List.of(s), Set.of(99));
        assertTrue(result.isEmpty(), "Blacklisted song must be excluded");
    }

    @Test
    void testEmptyCandidatesReturnsEmptyList() throws Exception {
        assertTrue(score(List.of(), Set.of()).isEmpty());
    }

    @Test
    void testResultIsOrderedByScoreDescending() throws Exception {
        // plays=100 gives highest score, plays=0 gives lowest among same-source songs
        SongCandidate low = song(1, "GENRE", 0, 0, 7);
        SongCandidate high = song(2, "GENRE", 100, 0, 7);
        List<ScoredSong> result = score(List.of(low, high), Set.of());
        assertEquals(2, result.get(0).getSong().getSongId(), "High-play song should rank first");
    }

    @Test
    void testArtistSourceScoresHigherThanGenre() throws Exception {
        SongCandidate artist = song(1, "ARTIST", 0, 0, 7);
        SongCandidate genre = song(2, "GENRE", 0, 0, 7);
        List<ScoredSong> result = score(List.of(artist, genre), Set.of());
        assertTrue(result.get(0).getSong().getSource().equals("ARTIST"),
                "ARTIST source should outscore GENRE source with equal other stats");
    }

    @Test
    void testPlays100GivesMaxPlayBoost() throws Exception {
        SongCandidate s100 = song(1, "GENRE", 100, 0, 7);
        SongCandidate s50 = song(2, "GENRE", 50, 0, 7);
        List<ScoredSong> result = score(List.of(s100, s50), Set.of());
        assertTrue(result.get(0).getSong().getSongId() == 1, "100 plays should beat 50 plays");
    }

    @Test
    void testZeroPlaysGetsNewSongBoost() throws Exception {
        // plays=0 gets +8 (new song boost), plays=1 gets +5 — verify they differ
        SongCandidate zero = song(1, "GENRE", 0, 0, 7);
        SongCandidate one = song(2, "GENRE", 1, 0, 7);
        List<ScoredSong> result = score(List.of(zero, one), Set.of());
        int scoreZero = result.stream().filter(r -> r.getSong().getSongId() == 1).findFirst().get().getScore();
        int scoreOne = result.stream().filter(r -> r.getSong().getSongId() == 2).findFirst().get().getScore();
        assertNotEquals(scoreZero, scoreOne, "plays=0 and plays=1 should have different scores");
    }

    @Test
    void testHighSkipsPenalizesScore() throws Exception {
        SongCandidate clean = song(1, "GENRE", 10, 0, 7);
        SongCandidate skippy = song(2, "GENRE", 10, 50, 7); // 50 skips → -30
        List<ScoredSong> result = score(List.of(clean, skippy), Set.of());
        int scoreClean = result.stream().filter(r -> r.getSong().getSongId() == 1).findFirst().get().getScore();
        int scoreSkippy = result.stream().filter(r -> r.getSong().getSongId() == 2).findFirst().get().getScore();
        assertTrue(scoreClean > scoreSkippy, "Many skips should reduce score");
    }

    @Test
    void testNeverPlayedGetsLastPlayedBoost() throws Exception {
        // days == -1 means never played -> +10 boost
        SongCandidate never = song(1, "GENRE", 0, 0, -1);
        SongCandidate old = song(2, "GENRE", 0, 0, 400); // > 365 days → -40
        List<ScoredSong> result = score(List.of(never, old), Set.of());
        int scoreNever = result.stream().filter(r -> r.getSong().getSongId() == 1).findFirst().get().getScore();
        int scoreOld = result.stream().filter(r -> r.getSong().getSongId() == 2).findFirst().get().getScore();
        assertTrue(scoreNever > scoreOld, "Never-played should beat very old song");
    }

    @Test
    void testOldSongOver365DaysPenalized() throws Exception {
        SongCandidate fresh = song(1, "GENRE", 10, 0, 3); // days=3 → +15
        SongCandidate stale = song(2, "GENRE", 10, 0, 400); // days=400 → -40
        List<ScoredSong> result = score(List.of(fresh, stale), Set.of());
        int scoreFresh = result.stream().filter(r -> r.getSong().getSongId() == 1).findFirst().get().getScore();
        int scoreStale = result.stream().filter(r -> r.getSong().getSongId() == 2).findFirst().get().getScore();
        assertTrue(scoreFresh > scoreStale, "Old song (>365 days) should be heavily penalized");
    }

    // Functional dependency: same inputs always produce the same score
    @Test
    void testSameInputAlwaysProducesSameScore() throws Exception {
        SongCandidate s1 = song(1, "ARTIST", 25, 5, 14);
        SongCandidate s2 = song(2, "ARTIST", 25, 5, 14); // identical stats, different id
        List<ScoredSong> result = score(List.of(s1, s2), Set.of());
        assertEquals(result.get(0).getScore(), result.get(1).getScore(),
                "Songs with identical stats must receive identical scores");
    }

    static class TestablePurge extends PurgeController {
        final Map<Integer, String> userPlaylists;
        final Map<Integer, String> playlistSongs;
        final Map<Integer, Object[]> songStats;
        final Map<Integer, Object[]> genreStats;
        final Map<Integer, Object[]> artistStats;
        final Map<Integer, String> blacklist;
        final Map<Integer, Map<Integer, String>> genreOfSong;
        final Map<Integer, Map<Integer, String>> artistOfSong;
        final List<Integer> removedIds = new ArrayList<>();

        TestablePurge(Map<Integer, String> userPlaylists,
                Map<Integer, String> playlistSongs,
                Map<Integer, Object[]> songStats,
                Map<Integer, Object[]> genreStats,
                Map<Integer, Object[]> artistStats,
                Map<Integer, String> blacklist,
                Map<Integer, Map<Integer, String>> genreOfSong,
                Map<Integer, Map<Integer, String>> artistOfSong) {
            this.userPlaylists = userPlaylists;
            this.playlistSongs = playlistSongs;
            this.songStats = songStats;
            this.genreStats = genreStats;
            this.artistStats = artistStats;
            this.blacklist = blacklist;
            this.genreOfSong = genreOfSong;
            this.artistOfSong = artistOfSong;
        }

        @Override
        protected Map<Integer, String> fetchUserPlaylists(int userId) {
            return userPlaylists;
        }

        @Override
        protected Map<Integer, String> fetchPlaylistSongs(int playlistId) {
            return playlistSongs;
        }

        @Override
        protected Map<Integer, Object[]> fetchSongStats(int userId) {
            return songStats;
        }

        @Override
        protected Map<Integer, Object[]> fetchGenreStats(int userId) {
            return genreStats;
        }

        @Override
        protected Map<Integer, Object[]> fetchArtistStats(int userId) {
            return artistStats;
        }

        @Override
        protected Map<Integer, String> fetchBlacklist(int userId) {
            return blacklist;
        }

        @Override
        protected Map<Integer, String> fetchGenreOfSong(int songId) {
            return genreOfSong.getOrDefault(songId, new HashMap<>());
        }

        @Override
        protected Map<Integer, String> fetchArtistOfSong(int songId) {
            return artistOfSong.getOrDefault(songId, new HashMap<>());
        }

        @Override
        protected void doRemoveSong(int playlistId, int songId) {
            removedIds.add(songId);
        }
    }

    // stats array: index 2 = plays, index 4 = skips, index 5 = lastPlayed date
    private Object[] purgeStats(int plays, int skips, Date lastPlayed) {
        return new Object[] { "ArtistName", "x", plays, 0, skips, lastPlayed };
    }

    private TestablePurge simplePurge(int songId, String songName,
            int plays, int skips, Date lastPlayed) {
        Map<Integer, String> playlists = new HashMap<>();
        playlists.put(1, "P1");
        Map<Integer, String> songs = new HashMap<>();
        songs.put(songId, songName);
        Map<Integer, Object[]> stats = new HashMap<>();
        if (lastPlayed != null)
            stats.put(songId, purgeStats(plays, skips, lastPlayed));
        return new TestablePurge(playlists, songs, stats,
                new HashMap<>(), new HashMap<>(), new HashMap<>(),
                new HashMap<>(), new HashMap<>());
    }

    @Test
    void testPurgeWrongUserReturnsEmpty() throws Exception {
        Map<Integer, String> playlists = new HashMap<>();
        playlists.put(10, "P10");
        TestablePurge ctrl = new TestablePurge(playlists, new HashMap<>(), new HashMap<>(),
                new HashMap<>(), new HashMap<>(), new HashMap<>(),
                new HashMap<>(), new HashMap<>());
        List<String> removed = ctrl.purgePlaylist(99, 1); // playlist 99 not owned by user 1
        assertTrue(removed.isEmpty(), "Wrong-user purge should return empty list");
    }

    @Test
    void testPurgeRemovesSongWithNoPlayHistory() throws Exception {
        TestablePurge ctrl = simplePurge(5, "Ghost Song", 0, 0, null);
        // songStats has no entry for songId=5 when lastPlayed==null is our signal
        ctrl.playlistSongs.put(5, "Ghost Song");
        ctrl.songStats.remove(5); // no stats at all
        List<String> removed = ctrl.purgePlaylist(1, 1);
        assertTrue(removed.contains("Ghost Song"), "Song with no play history should be removed");
    }

    @Test
    void testPurgeRemovesSongWithTooManySkips() throws Exception {
        Date recent = Date.valueOf(LocalDate.now().minusDays(10));
        TestablePurge ctrl = simplePurge(5, "Skip Song", 30, 25, recent); // 25 > maxSkips(20)
        List<String> removed = ctrl.purgePlaylist(1, 1);
        assertTrue(removed.contains("Skip Song"), "Song with >20 skips should be removed");
    }

    @Test
    void testPurgeRemovesSongNotPlayedIn3Months() throws Exception {
        Date old = Date.valueOf(LocalDate.now().minusMonths(4));
        TestablePurge ctrl = simplePurge(5, "Old Song", 10, 0, old);
        List<String> removed = ctrl.purgePlaylist(1, 1);
        assertTrue(removed.contains("Old Song"), "Song not played in 3+ months should be removed");
    }

    @Test
    void testPurgeRemovesSongWithHighSkipRatio() throws Exception {
        Date recent = Date.valueOf(LocalDate.now().minusDays(5));
        TestablePurge ctrl = simplePurge(5, "Ratio Song", 4, 3, recent); // 3/4 = 75% > 50%
        List<String> removed = ctrl.purgePlaylist(1, 1);
        assertTrue(removed.contains("Ratio Song"), "Song with skip ratio >50% should be removed");
    }

    @Test
    void testPurgeRemovesBlacklistedSong() throws Exception {
        Date recent = Date.valueOf(LocalDate.now().minusDays(5));
        TestablePurge ctrl = simplePurge(5, "BL Song", 10, 1, recent);
        // Good stats, but blacklisted
        Map<Integer, String> genreMap = new HashMap<>();
        genreMap.put(1, "Rock");
        ctrl.genreOfSong.put(5, genreMap);
        ctrl.genreStats.put(1, new Object[] { 0, 5 }); // 5 unique songs >= minUniqueForGenre(3)
        Map<Integer, String> artistMap = new HashMap<>();
        artistMap.put(1, "Artist");
        ctrl.artistOfSong.put(5, artistMap);
        ctrl.artistStats.put(1, new Object[] { 0, 3 }); // 3 unique >= minUniqueForArtist(2)
        ctrl.blacklist.put(5, "BL Song");
        List<String> removed = ctrl.purgePlaylist(1, 1);
        assertTrue(removed.contains("BL Song"), "Blacklisted song should be removed");
    }

    @Test
    void testPurgeKeepsGoodSong() throws Exception {
        Date recent = Date.valueOf(LocalDate.now().minusDays(5));
        TestablePurge ctrl = simplePurge(5, "Good Song", 10, 1, recent);
        // Provide liked genre and artist
        Map<Integer, String> genreMap = new HashMap<>();
        genreMap.put(1, "Rock");
        ctrl.genreOfSong.put(5, genreMap);
        ctrl.genreStats.put(1, new Object[] { 0, 5 });
        Map<Integer, String> artistMap = new HashMap<>();
        artistMap.put(1, "Artist");
        ctrl.artistOfSong.put(5, artistMap);
        ctrl.artistStats.put(1, new Object[] { 0, 3 });
        List<String> removed = ctrl.purgePlaylist(1, 1);
        assertFalse(removed.contains("Good Song"), "Song passing all filters should not be removed");
    }

    // Functional dependency: purge result depends on stats, not song name
    @Test
    void testPurgeResultDependsOnStatsNotName() throws Exception {
        Date recent = Date.valueOf(LocalDate.now().minusDays(5));
        // Two songs with identical bad stats but different names — both should be
        // removed
        Map<Integer, String> playlists = new HashMap<>();
        playlists.put(1, "P");
        Map<Integer, String> songs = new HashMap<>();
        songs.put(1, "Alpha");
        songs.put(2, "Beta");
        Map<Integer, Object[]> stats = new HashMap<>();
        stats.put(1, purgeStats(4, 3, recent)); // high skip ratio
        stats.put(2, purgeStats(4, 3, recent)); // same
        TestablePurge ctrl = new TestablePurge(playlists, songs, stats,
                new HashMap<>(), new HashMap<>(), new HashMap<>(),
                new HashMap<>(), new HashMap<>());
        List<String> removed = ctrl.purgePlaylist(1, 1);
        assertTrue(removed.contains("Alpha") && removed.contains("Beta"),
                "Both songs with same bad stats should be removed regardless of name");
    }

    // TestableJoin allows us to inject controlled playlists and stats for testing
    // the joint playlist logic without needing a real database.
    static class TestableJoin extends JoinPlaylistController {
        private final Map<Integer, String> p1, p2;
        private final Map<Integer, Object[]> s1, s2;

        TestableJoin(Map<Integer, String> p1, Map<Integer, String> p2,
                Map<Integer, Object[]> s1, Map<Integer, Object[]> s2) {
            this.p1 = p1;
            this.p2 = p2;
            this.s1 = s1;
            this.s2 = s2;
        }

        @Override
        protected Map<Integer, String> fetchPlaylistSongs(int playlistId) {
            return (playlistId == 1) ? p1 : p2;
        }

        @Override
        protected Map<Integer, Object[]> fetchSongStats(int userId) {
            return (userId == 1) ? s1 : s2;
        }
    }

    // stats array: index 2 = plays, index 4 = skips, index 5 = lastPlayed date
    private Object[] joinStats(int plays, int skips, Date lastPlayed) {
        return new Object[] { "Artist", "x", plays, 0, skips, lastPlayed };
    }

    @Test
    void testJoinIncludesMutuallyLikedSong() throws Exception {
        Date recent = Date.valueOf(LocalDate.now().minusDays(5));
        Map<Integer, String> p1 = Map.of(1, "SharedSong"), p2 = Map.of(1, "SharedSong");
        Map<Integer, Object[]> s1 = Map.of(1, joinStats(25, 0, recent));
        Map<Integer, Object[]> s2 = Map.of(1, joinStats(25, 0, recent));
        List<SongCandidate> result = new TestableJoin(p1, p2, s1, s2).buildJointPlaylist(1, 2, 1, 2);
        assertEquals(1, result.size());
        assertEquals("SharedSong", result.get(0).getSongName());
    }

    @Test
    void testJoinExcludesSongWithTooFewPlays() throws Exception {
        Date recent = Date.valueOf(LocalDate.now().minusDays(5));
        Map<Integer, String> p1 = Map.of(1, "RareSong"), p2 = Map.of(1, "RareSong");
        Map<Integer, Object[]> s1 = Map.of(1, joinStats(5, 0, recent)); // < 20 plays
        Map<Integer, Object[]> s2 = Map.of(1, joinStats(25, 0, recent));
        List<SongCandidate> result = new TestableJoin(p1, p2, s1, s2).buildJointPlaylist(1, 2, 1, 2);
        assertTrue(result.isEmpty(), "Song with < 20 plays for either user should be excluded");
    }

    @Test
    void testJoinExcludesSongWithTooManySkips() throws Exception {
        Date recent = Date.valueOf(LocalDate.now().minusDays(5));
        Map<Integer, String> p1 = Map.of(1, "SkipSong"), p2 = Map.of(1, "SkipSong");
        Map<Integer, Object[]> s1 = Map.of(1, joinStats(30, 30, recent)); // skips >= 25
        Map<Integer, Object[]> s2 = Map.of(1, joinStats(30, 0, recent));
        List<SongCandidate> result = new TestableJoin(p1, p2, s1, s2).buildJointPlaylist(1, 2, 1, 2);
        assertTrue(result.isEmpty(), "Song with >= 25 skips for either user should be excluded");
    }

    @Test
    void testJoinExcludesSongWithHighSkipRatio() throws Exception {
        Date recent = Date.valueOf(LocalDate.now().minusDays(5));
        Map<Integer, String> p1 = Map.of(1, "RatioSong"), p2 = Map.of(1, "RatioSong");
        Map<Integer, Object[]> s1 = Map.of(1, joinStats(20, 15, recent)); // 75% skip ratio
        Map<Integer, Object[]> s2 = Map.of(1, joinStats(20, 0, recent));
        List<SongCandidate> result = new TestableJoin(p1, p2, s1, s2).buildJointPlaylist(1, 2, 1, 2);
        assertTrue(result.isEmpty(), "Song with >50% skip ratio for either user should be excluded");
    }

    @Test
    void testJoinExcludesSongPlayedTooLongAgo() throws Exception {
        Date old = Date.valueOf(LocalDate.now().minusDays(200)); // > 100 days
        Map<Integer, String> p1 = Map.of(1, "OldSong"), p2 = Map.of(1, "OldSong");
        Map<Integer, Object[]> s1 = Map.of(1, joinStats(25, 0, old));
        Map<Integer, Object[]> s2 = Map.of(1, joinStats(25, 0, old));
        List<SongCandidate> result = new TestableJoin(p1, p2, s1, s2).buildJointPlaylist(1, 2, 1, 2);
        assertTrue(result.isEmpty(), "Song not played in 100 days should be excluded");
    }

    @Test
    void testJoinEmptyPlaylistsReturnsEmpty() throws Exception {
        List<SongCandidate> result = new TestableJoin(
                new HashMap<>(), new HashMap<>(), new HashMap<>(), new HashMap<>())
                .buildJointPlaylist(1, 2, 1, 2);
        assertTrue(result.isEmpty());
    }

    // Functional dependency: result for a song depends on its stats from both users
    @Test
    void testJoinSourceFieldIsJOIN() throws Exception {
        Date recent = Date.valueOf(LocalDate.now().minusDays(5));
        Map<Integer, String> p1 = Map.of(1, "S"), p2 = Map.of(1, "S");
        Map<Integer, Object[]> s1 = Map.of(1, joinStats(25, 0, recent));
        Map<Integer, Object[]> s2 = Map.of(1, joinStats(25, 0, recent));
        List<SongCandidate> result = new TestableJoin(p1, p2, s1, s2).buildJointPlaylist(1, 2, 1, 2);
        assertEquals("JOIN", result.get(0).getSource(),
                "Songs in a joint playlist should have source='JOIN'");
    }
}
