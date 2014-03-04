
def split_line (line)
  return line.split ','
end

lines = []
File.open 'admissions_data.csv' do |f|
  f.each_line do |l|
    lines << l
  end
end
key = split_line lines.shift

class_is = 25
discrete_is = [1, 2, 4, 5, 6, 9, 12, 15, 17, 22, 24, 26, 33]
continuous_is = [10, 13, 30, 31, 32]  #TODO: use these

 # counts[param index][param value][class] = count
counts = []

for l in lines
  params = split_line l  # TODO: commas in quotes
  for i in discrete_is
    if counts[i].nil? then counts[i] = {} end
    if counts[i][params[i]].nil? then counts[i][params[i]] = {} end
    if counts[i][params[i]][params[25]].nil? then counts[i][params[i]][params[25]] = 0 end
    counts[i][params[i]][params[25]] += 1
  end
end

for i in discrete_is
  for v in counts[i].keys
    unless counts[i][v].nil?
      for c in counts[i][v].keys
        if counts[i][v][c].nil? then counts[i][v][c] = 0 end
        puts "counts[#{key[i]}][#{v}][#{c}] = #{counts[i][v][c]}"
      end
    end
  end
end
