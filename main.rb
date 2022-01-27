require 'rubygems'

require 'chunky_png'
require "oily_png"

Layers = []
$queue = Queue.new 
Dir.glob(File.join(__dir__, '/layers/*.png')).each do |filename|
  name = File.basename(filename, '.png')
  layer, idx = name.split('_')
  layer = layer.to_i
  idx = idx.to_i
  Layers[layer] ||= []
  Layers[layer] << idx
end

def combine_all
  Thread.new do
    combine($queue, 0, [])
    $queue << []
  end
end

def combine(yielder, layer, combination)
  if layer < Layers.size
    Layers[layer].sort.each do |i|
      combine(yielder, layer + 1, combination + [i])
    end
  else
    yielder << combination
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
    i=0
    loop do
    comb = $queue.pop

    puts comb.join(',')
    break if comb.size == 0
    draw i, comb
    i+=1
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
b = start_drawer
a.join
b.join
