package DatabasesFinal.BLL;

import java.sql.Date;

public class PlaylistStat {
    private String songName;
    private int plays;
    private int skips;
    private Date lastPlayed;

    public PlaylistStat(String songName, int plays, int skips, Date lastPlayed) {
        this.songName = songName;
        this.plays = plays;
        this.skips = skips;
        this.lastPlayed = lastPlayed;
    }

    public String getSongName() { return songName; }
    public int getPlays() { return plays; }
    public int getSkips() { return skips; }
    public Date getLastPlayed() { return lastPlayed; }
}