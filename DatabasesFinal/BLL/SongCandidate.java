package DatabasesFinal.BLL;

public class SongCandidate {
    private int songId;
    private String songName;
    private String source; // "ARTIST" or "GENRE"
    private String artist;
    private int plays;
    private int skips;
    private int lastPlayed;

    /***
     * song candidate constructor
     * @param songId
     * @param songName
     * @param source
     * @param artist
     * @param plays
     * @param skips
     * @param lastPlayed
     */
    public SongCandidate(int songId, String songName, String source, String artist, int plays, int skips, int lastPlayed) {
        this.songId = songId;
        this.songName = songName;
        this.source = source;
        this.artist = artist;
        this.plays = plays;
        this.skips = skips;
        this.lastPlayed = lastPlayed;
    }

    public int getSongId() { return songId; } // get song id
    public String getSongName() { return songName; } // get song name
    public String getSource() { return source; } // get source
    public String getArtist() { return artist; } // get artist
    public int getPlays() { return plays; } // get plays
    public int getSkips() { return skips; } // get skips
    public int getLastPlayed() { return lastPlayed; } // get last played
}
