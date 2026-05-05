package DatabasesFinal.BLL;

public class SongCandidate {
    private int songId;
    private String songName;
    private String source; // "ARTIST" or "GENRE"
    private String artist;
    private int plays;
    private int skips;
    private int lastPlayed;

    public SongCandidate(int songId, String songName, String source, String artist, int plays, int skips, int lastPlayed) {
        this.songId = songId;
        this.songName = songName;
        this.source = source;
        this.artist = artist;
        this.plays = plays;
        this.skips = skips;
        this.lastPlayed = lastPlayed;
    }

    public int getSongId() { return songId; }
    public String getSongName() { return songName; }
    public String getSource() { return source; }
    public String getArtist() { return artist; }
    public int getPlays() { return plays; }
    public int getSkips() { return skips; }
    public int getLastPlayed() { return lastPlayed; }
}