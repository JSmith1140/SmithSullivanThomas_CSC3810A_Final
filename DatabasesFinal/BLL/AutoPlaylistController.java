package DatabasesFinal.BLL;

import java.util.*;
import DatabasesFinal.DAL.PlaylistDataProvider;

public class AutoPlaylistController {

    private PlaylistDataProvider dp = new PlaylistDataProvider();

    public List<ScoredSong> buildAutoPlaylist(int userId, String a1, String a2, String a3) throws Exception {

        // Get candidate songs
        List<SongCandidate> candidates = dp.getCandidateSongs(userId, a1, a2, a3);

        // Get blacklist
        Set<Integer> blacklist = dp.getBlacklist(userId);
        Map<Integer, ScoredSong> map = new HashMap<>();

        for (SongCandidate song : candidates) {

            // if blacklist song ignore it
            if (blacklist.contains(song.getSongId())) continue;

            int score = 0;

            if (song.getSource().equals("ARTIST")) {
                score += 30; // extra boost for artists song
            } else {
                score += 20; // song in same genre
            }

            int plays = song.getPlays();

            // give extra boost to score based on number of plays
            if (plays >= 100) {
                score += 60;
            } else if (plays >= 50) {
                score += 40;
            } else if (plays >= 25) {
                score += 25;
            } else if (plays >= 10) {
                score += 15;
            } else if (plays >= 1) {
                score += 5;
            } else {
                score += 8; // give boost to 0 played songs so you can get recommended new songs
            }

            int skips = song.getSkips();

            // take away from score based on number of skips
            if (skips >= 50) {
                score -= 30;
            }
            else if (skips >= 25) {
                score -= 15;
            }
            else if (skips >= 10) {
                score -= 10;
            } 
            else if (skips >= 1){
                score -= 5;
            } else {
                score += 10; // give a boost if you've never skipped before
            }

            int days = song.getLastPlayed();

            // give or take away from last time played song based on how long its been
            if (days == -1) {
                score += 20; // give boost to never played songs
            }
            else if (days >= 365) {
                score -= 40;
            }
            else if (days >= 30) {
                score -= 15;
            }
            else if (days >= 14) {
                score += 5;
            }
            else if (days >= 7) {
                score += 10;
            }
            else if (days >= 0) {
                score += 15;
            }

            map.put(song.getSongId(), new ScoredSong(song, score));
        }

        List<ScoredSong> result = new ArrayList<>(map.values());

        result.sort((a, b) -> Integer.compare(b.getScore(), a.getScore()));

        // to show every song and score (for presentation)
        for (ScoredSong s : result) { 
            System.out.println( "Song: " + s.getSong().getSongName() + " | Score: " + s.getScore() ); 
        }

        return result;
    }
}