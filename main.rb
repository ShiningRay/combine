require 'rubygems'

require 'chunky_png'
require "oily_png"

Layers = []
$queue = Queue.new 
Combinations = Array.new(4){[]}
Dir.glob(File.join(__dir__, '/layers/*.png')).each do |filename|
  name = File.basename(filename, '.png')
  layer, idx = name.split('_')
  layer = layer.to_i
  idx = idx.to_i
  Layers[layer] ||= []
  Layers[layer] << idx
end

def combine_all
  combine(0, [])
  Combinations.each do |c|
    c.shuffle!
  end
  Thread.new do
    0.upto(2022) do |i|
      comb = case i % 10
      when 1,3,5
        Combinations[0].pop
      when 2,4,6
        Combinations[1].pop
      when 7,9,0
        Combinations[2].pop
      when 8
        Combinations[3].pop
      end
      $queue << [i, comb]
    end
    0.upto(4) do 
      $queue << []
    end
  end

end

def combine(layer, combination)
  if layer < Layers.size
    Layers[layer].sort.each do |i|
      combine(layer + 1, combination + [i])
    end
  else
    Combinations[combination[0]] << combination
    # yielder << combination
  end
end

def draw(i, combination)
  output = "output/#{i}.png"
  return if File.exist?(output)

  bg = combination.pop
  m = ChunkyPNG::Image.from_file "layers/#{combination.size}_#{bg}.png"

  (combination.size - 1).downto(0) do |layer|
    filename = "layers/#{layer}_#{combination[layer]}.png"
    img = ChunkyPNG::Image.from_file filename
    m = m.compose(img) 
  end

  m.save output
end

def start_drawer
  Thread.new do
    loop do
      i, comb = $queue.pop
      puts comb.join(',')
      break unless i
      draw i, comb
    end
  end
end

# i = 0
# combine_all.each do |combination|
#   puts combination.join(',')
#   draw(i, combination)
#   i += 1
# end
a = combine_all
b = Array.new(4){start_drawer}
a.join
b.map{|t| t.join }
