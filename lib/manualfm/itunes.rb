# -*- coding: utf-8 -*-
require 'sqlite3'

module ManualFm
  def self.readitunes(since = nil)
    ipodpath = Dir.glob("#{ENV['HOME']}/.gvfs/*iPod").first
    itpath = "#{ipodpath}/iTunes_Control/iTunes/iTunes Library.itlp"
    itpath_dynamic = "#{itpath}/Dynamic.itdb"
    itpath_library = "#{itpath}/Library.itdb"
    itdb_dynamic = SQLite3::Database.new(itpath_dynamic)
    itdb_library = SQLite3::Database.new(itpath_library)

    since = Time.now - 30 * 24 * 60 * 60 if since.nil?

    i2001 = Time.local(2001, 1, 1).to_i # quite strange
    sinceit = since.to_i - i2001

    played = {}
    sql = "select item_pid,date_played from item_stats where date_played > ?"
    itdb_dynamic.execute(sql, sinceit) do |row|
      date_played = Time.at(row[1].to_i + i2001)
      played[row[0].to_i] = { :date_played => date_played }
    end

    pids = played.map{|k,v|k}.join(', ')
    sql = "select pid,title,artist,total_time_ms,is_song from item where pid"
    itdb_library.execute("#{sql} in (#{pids})") do |row|
      played[row[0].to_i].merge!({
        :title => row[1],
        :artist => row[2],
        :total_time_ms => row[3].to_i,
        :is_song => row[4].to_i,
      })
    end

    itdb_dynamic.close
    itdb_library.close

    played
  end
end
