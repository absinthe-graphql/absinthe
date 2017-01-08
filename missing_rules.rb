require 'yaml'

def cram(str)
  str.tr('_', ' ').
  gsub(/\s+/, ' ').
  gsub(/\b\w/){ $`[-1,1] == "'" ? $& : $&.upcase }.
  gsub(/\s+/, '')
end

def filesize(f)
  YAML.load(`cloc '#{f}' --quiet --yaml`)['SUM']['code']
end

js = {}
ex = {}

implemented = Dir['lib/absinthe/phase/**/*.ex'].select { |f|
  f.include?('validation')
}.map { |f|
  result = cram(File.basename(f, '.ex'))
  ex[result] = filesize(f)
  result
}.select { |f|
  f != 'Validation'
}

needed = Dir['../../src/graphql-js/src/validation/rules/**/*.js'].map { |f|
  result = File.basename(f, '.js')
  js[result] = filesize(f)
  result
}

puts "Implemented #{implemented.size}/#{needed.size} rules"
puts "Done:"
puts implemented.sort.map { |f| "- #{f} (.js LOC: #{js[f]}, .ex LOC: #{ex[f]})" }
puts "Missing:"
puts (needed - implemented).sort.map { |f| "- #{f} (.js LOC: #{js[f]})"}
