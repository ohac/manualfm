module ManualFm
  def self.readcddb(filename)
    cd = File.read(filename)
    lines = cd.each_line.map{|line|line.chomp}
    until /offsets:$/ === lines.shift
    end
    last_offset = nil
    lens = []
    loop do
      x, offsets = lines.shift.split("\t")
      break if offsets.nil?
      offset = offsets.to_i
      unless last_offset.nil?
        lens << ((offset - last_offset) / 75.0).round
      end
      last_offset = offset
    end
    totallen = lines.shift.split[3].to_i
    lens << totallen - (last_offset / 75.0).round
    until /^DISCID=/ === lines.shift
    end
    data = {}
    loop do
      line = lines.shift
      break if line.nil?
      pos = line.index('=')
      next if pos.nil?
      key = line[0, pos]
      value = line[pos + 1, line.size]
      data[key] = value
    end
    dtitle = data['DTITLE']
    pos = dtitle.index(' / ')
    artist = dtitle[0, pos]
    title = dtitle[pos + 3, dtitle.size]

    result = {
      :artist => artist,
      :title => title,
      :totallen => totallen,
      :track => [],
    }
    data.size.times do |i|
      ttitle = data['TTITLE%d' % i]
      break if ttitle.nil?
      result[:track] << { :title => ttitle, :length => lens[i] }
    end
    result
  end
end
