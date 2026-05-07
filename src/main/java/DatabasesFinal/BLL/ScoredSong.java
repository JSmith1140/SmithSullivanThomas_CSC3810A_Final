package DatabasesFinal.BLL;

public class ScoredSong {
    private SongCandidate song;
    private int score;

    /***
     * scored song constructor
     */
    public ScoredSong(SongCandidate song, int score) {
        this.song = song;
        this.score = score;
    }

    public SongCandidate getSong() { return song; } // get song
    public int getScore() { return score; } // get score
}
