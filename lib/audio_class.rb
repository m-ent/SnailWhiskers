#!/usr/local/bin/ruby
#  Class Audio: 聴検データ取扱い用クラス
#  Copyright 2007-2009 S Mamiya
#  0.20091107
#  0.20120519 : chunky_PNGのgemを使用、ruby1.9対応
#  0.20120805 : rails支配下の時とそうでないときのライブラリの場所を分けた
#  0.20121102 : class Bitmapを別ファイルに分離

require 'cairo'

if defined? Rails
  require 'AA79S.rb'
  Image_parts_location = "lib/assets/parts/" # Rails.rootから辿る形
else
  require_relative './AA79S.rb'
  Image_parts_location = "./assets/parts/"   # Rails.rootに影響されない場合
end

# railsの場合，directoryの相対表示の起点は rails/audiserv であるようだ
Overdraw_times = 2  # 重ね書きの回数．まずは2回，つまり1回前の検査までとする
Graph_size = 600 # size at start-development is 400px

def draw_rate(x)
  if x.class == Integer
    return (x * Graph_size / 400.0).to_i
  elsif x.class == Float
    return (x * Graph_size / 400.0).to_f
  else
    return x
  end
end

def stroke_line(context, x1, y1, x2, y2, color)
  context.set_source_rgb(color)
  context.set_line_width 1
  context.move_to(x1, y1)
  context.line_to(x2, y2)
  context.stroke
end

def put_font(context, x, y, str)
  context.set_font_size draw_rate(12)
  context.select_font_face "IPAexGothic"
  context.move_to x, y + draw_rate(10)
  context.show_text str
end

def color_table
  {red:        [1, 0, 0],          #"0xff0000ff"
   blue:       [0, 0, 1],          #"0x0000ffff"
   red_pre0:   [1, 0.12, 0.12],    #"0xff1e1eff"
   red_pre1:   [1, 0.35, 0.35],    #"0xff5a5aff"
   blue_pre0:  [0.12, 0.12, 1],    #"0x1e1effff"
   blue_pre1:  [0.35, 0.35, 1],    #"0x5a5affff"
   black:      [0, 0, 0],          #"0x000000ff"
   black_pre0: [0.12, 0.12, 0.12], #"0x1e1e1eff"
   black_pre1: [0.35, 0.35, 0.35], #"0x5a5a5aff"
   white:      [1, 1, 1],          #"0xffffffff"
   gray:       [0.67, 0.67, 0.67]} #"0xaaaaaaff"
end

def put_symbol(context, sym, x, y, rgb) # symbol is Symbol, like :circle
  symbols = {circle: ["○", 0, 0], cross: ["×", 1, 2], r_bracket: ["［", -5, 0], l_bracket: ["］", 12, 2],
             ra_scaleout: ["↓", -2, -14], la_scaleout: ["↓", 2, -12], rb_scaleout: ["↓", -7, -14], lb_scaleout: ["↓", 7, -12]}
  xr = x.round
  yr = y.round
  context.select_font_face "IPAexGothic"
  context.set_font_size draw_rate(16)
  context.set_source_rgb(color_table[rgb])
  context.move_to x - draw_rate(8 - symbols[sym][1]), y + draw_rate(6 - symbols[sym][2])
  context.show_text symbols[sym][0]
end

def line(context, x1, y1, x2, y2, rgb, dotted)
  # Bresenhamアルゴリズムを用いた自力描画から変更
  if x1 > x2  # x2がx1以上であることを保証
    x1, x2 = swap(x1,x2)
    y1, y2 = swap(y1,y2)
  end
  sign_modifier = (y1 < y2)? 1 : -1 # yが減少していく時(右上がり)の符号補正
  context.set_line_width 1
  context.set_dash [1, 0]
  if dotted == "dot"
    context.set_dash [6, 3]
  end
  stroke_line(context, x1, y1, x2, y2, color_table[rgb])
end

class Audio #< Bitmap
  X_pos = [draw_rate( 70),
           draw_rate(115),
           draw_rate(160),
           draw_rate(205),
           draw_rate(250),
           draw_rate(295),
           draw_rate(340)]   # 各周波数別の横座標

  def initialize(audiodata)              # 引数はFormatted_data のインスタンス
    @graph_size = Graph_size # size at start-development is 400px
    @surface = nil
    @context = nil
    if File.exist?("#{Image_parts_location}background_audiogram#{Graph_size}.png")
      @surface = Cairo::ImageSurface.from_png("#{Image_parts_location}background_audiogram#{Graph_size}.png")
      @context = Cairo::Context.new @surface
    else
      @surface = Cairo::ImageSurface.new Cairo::FORMAT_ARGB32, Graph_size, Graph_size
      @context = Cairo::Context.new @surface
      draw_lines(@context)
      @surface.write_to_png "#{Image_parts_location}background_audiogram#{Graph_size}.png"
    end
    @audiodata = audiodata
    @air_rt  = @audiodata.extract[:ra]
    @air_lt  = @audiodata.extract[:la]
    @bone_rt = @audiodata.extract[:rb]
    @bone_lt = @audiodata.extract[:lb]
  end

  def draw_lines(context)
    context.set_source_rgb(1, 1, 1) # 白
    context.rectangle(0, 0, Graph_size, Graph_size)
    context.fill

    y1 = draw_rate(30)
    y2 = draw_rate(348)
    stroke_line(context, draw_rate(50), y1, draw_rate(50), y2, [0.5, 0.5, 0.5])
    for x in 0..6
      x1 = draw_rate(70) + x * draw_rate(45)
      stroke_line(context, x1, y1, x1, y2, [0.5, 0.5, 0.5])
    end
    stroke_line(context, draw_rate(360), y1, draw_rate(360) , y2, [0.5, 0.5, 0.5])
    x1 = draw_rate 50
    x2 = draw_rate 360
    stroke_line(context, x1, draw_rate(30) ,x2, draw_rate(30), [0.5, 0.5, 0.5])
    stroke_line(context, x1, draw_rate(45), x2, draw_rate(45), [0.5, 0.5, 0.5])
    stroke_line(context, x1, draw_rate(68), x2, draw_rate(68), [0.5, 0.5, 0.5])
    stroke_line(context, x1, draw_rate(69), x2, draw_rate(69), [0, 0, 0])
    for y in 0..10
      y1 = draw_rate(93 + y * 24)
      stroke_line(context, x1, y1, x2, y1, [0.5, 0.5, 0.5])
    end
    stroke_line(context, x1, draw_rate(348), x2, draw_rate(348), [0.5, 0.5, 0.5])
    context.select_font_face "IPAexGothic"
    for i in -1..11
      x = draw_rate(15)
      hear_level = (i * 10).to_s
      y = draw_rate(69 + i * 24 - 7)
      x += draw_rate((3 - hear_level.length) * 8)
      hear_level.each_byte do |c|
        if c == 45                  # if character is "-"
          put_font(context, x, y, "-")
        else
          put_font(context, x, y, "%c" % c)
        end
        x += draw_rate(8)
      end
    end
    put_font(context, draw_rate(23), draw_rate(15), "dB")

    # add holizontal scale
    cycle = ["125","250","500","1k","2k","4k","8k"]
    for i in 0..6
      y = draw_rate(358)
      x = draw_rate(70 + i * 45 - cycle[i].length * 4) # 8px for each char / 2
      cycle[i].each_byte do |c|
        put_font(context, x, y, "%c" % c)
        x += draw_rate(8)
      end
    end
    put_font(context, draw_rate(360), draw_rate(358), "Hz")
  end

  def put_rawdata
    return @audiodata.put_rawdata
  end

  def mean4          # 4分法
    if @air_rt[:data][2] and @air_rt[:data][3] and @air_rt[:data][4]
      mean4_rt = (@air_rt[:data][2] + @air_rt[:data][3] * 2 + @air_rt[:data][4]) /4
    else
      mean4_rt = -100.0
    end
    if @air_lt[:data][2] and @air_lt[:data][3] and @air_lt[:data][4]
      mean4_lt = (@air_lt[:data][2] + @air_lt[:data][3] * 2 + @air_lt[:data][4]) /4
    else
      mean4_lt = -100.0
    end
    mean4_bs = {:rt => mean4_rt, :lt => mean4_lt}
  end

  def reg_mean4          # 正規化4分法: scaleout は 105dB に
    if @air_rt[:data][2] and @air_rt[:data][3] and @air_rt[:data][4]
      r = {:data => @air_rt[:data], :scaleout => @air_rt[:scaleout]}
      for i in 2..4
        if r[:scaleout][i] or r[:data][i] > 100.0
          r[:data][i] = 105.0
        end
      end
      rmean4_rt = (r[:data][2] + r[:data][3] * 2 + r[:data][4]) /4
    else
      rmean4_rt = -100.0
    end
    if @air_lt[:data][2] and @air_lt[:data][3] and @air_lt[:data][4]
      l = {:data => @air_lt[:data], :scaleout => @air_lt[:scaleout]}
      for i in 2..4
        if l[:scaleout][i] or l[:data][i] > 100.0
          l[:data][i] = 105.0
        end
      end
      rmean4_lt = (l[:data][2] + l[:data][3] * 2 + l[:data][4]) /4
    else
      rmean4_lt = -100.0
    end
    rmean4_bs = {:rt => rmean4_rt, :lt => rmean4_lt}
  end

  def mean3          # 3分法
    if @air_rt[:data][2] and @air_rt[:data][3] and @air_rt[:data][4]
      mean3_rt = (@air_rt[:data][2] + @air_rt[:data][3] + @air_rt[:data][4]) /3
    else
      mean3_rt = -100.0
    end
    if @air_lt[:data][2] and @air_lt[:data][3] and @air_lt[:data][4]
      mean3_lt = (@air_lt[:data][2] + @air_lt[:data][3] + @air_lt[:data][4]) /3
    else
      mean3_lt = -100.0
    end
    mean3_bs = {:rt => mean3_rt, :lt => mean3_lt}
  end

  def mean6          # 6分法
    if @air_rt[:data][2] and @air_rt[:data][3] and @air_rt[:data][4] and @air_rt[:data][5]
      mean6_rt = (@air_rt[:data][2] + @air_rt[:data][3] * 2 + @air_rt[:data][4] * 2 + \
                  @air_rt[:data][5] ) /6
    else
      mean6_rt = -100.0
    end
    if @air_lt[:data][2] and @air_lt[:data][3] and @air_lt[:data][4] and @air_lt[:data][5]
      mean6_lt = (@air_lt[:data][2] + @air_lt[:data][3] * 2 + @air_lt[:data][4] * 2 + \
                  @air_lt[:data][5] ) /6
    else
      mean6_lt = -100.0
    end
    mean6_bs = {:rt => mean6_rt, :lt => mean6_lt}
  end

  def draw_sub(context, audiodata, timing)
    case timing  # timingは重ね書き用の引数で検査の時期がもっとも古いものは
                 # pre0，やや新しいものは pre1とする
    when "pre0"
      rt_color = :red_pre0   #RED_PRE0
      lt_color = :blue_pre0  #BLUE_PRE0
      bc_color = :black_pre0 #BLACK_PRE0
    when "pre1"
      rt_color = :red_pre1   #RED_PRE1
      lt_color = :blue_pre1  #BLUE_PRE1
      bc_color = :black_pre1 #BLACK_PRE1
    else
      rt_color = :red   #RED
      lt_color = :blue  #BLUE
      bc_color = :black #BLACK    
    end
    scaleout = audiodata[:scaleout]
    threshold = audiodata[:data]
    for i in 0..6
      if threshold[i]   # threshold[i] が nilの時は plot処理を skipする
        threshold[i] = threshold[i] + 0.0
        case audiodata[:side]
        when "Rt"
          case audiodata[:mode]
          when "Air"
            put_symbol(@context, :circle, X_pos[i], draw_rate(threshold[i] / 10 * 24 + 69), :red)
            if scaleout[i]
              put_symbol(@context, :ra_scaleout, X_pos[i], draw_rate(threshold[i] / 10 * 24 + 69), :red)
            end
          when "Bone"
            put_symbol(@context, :r_bracket, X_pos[i], draw_rate(threshold[i] / 10 * 24 + 69), :black)
            if scaleout[i]
              put_symbol(@context, :rb_scaleout, X_pos[i], draw_rate(threshold[i] / 10 * 24 + 69), :black)
            end
          end
        when "Lt"
          case audiodata[:mode]
          when "Air"
            put_symbol(@context, :cross, X_pos[i], draw_rate(threshold[i] / 10 * 24 + 69), :blue)
            if scaleout[i]
              put_symbol(@context, :la_scaleout, X_pos[i], draw_rate(threshold[i] / 10 * 24 + 69), :blue)
            end
          when "Bone"
            put_symbol(@context, :l_bracket, X_pos[i], draw_rate(threshold[i] / 10 * 24 + 69), :black)
            if scaleout[i]
              put_symbol(@context, :lb_scaleout, X_pos[i], draw_rate(threshold[i] / 10 * 24 + 69), :black)
            end
          end
        end
      end
    end
   
    if audiodata[:mode] == "Air"  # 気導の場合は周波数間の線を描く
      i = 0
      while i < 6
        if scaleout[i] or (not threshold[i])
          i += 1
          next
        end
        line_from = [X_pos[i], draw_rate(threshold[i] / 10 * 24 + 69).to_i]
        j = i + 1
        while j < 7
          if not threshold[j]
            if j == 6
              i += 1
            end
            j += 1
            next
          end
          if scaleout[j]
            i += 1
            break
          else
            line_to = [X_pos[j], draw_rate(threshold[j] / 10 * 24 + 69).to_i]
            case audiodata[:side]
            when "Rt"
              line(@context, line_from[0] ,line_from[1], line_to[0], line_to[1], :red, "line")
            when "Lt"
              line(@context, line_from[0] ,line_from[1]+1, line_to[0], line_to[1]+1, :blue, "dot")
            end
            i = j
            break
          end
        end
      end
    end
  end

  def draw(filename)
    draw_sub(@context, @air_rt, "latest")
    draw_sub(@context, @air_lt, "latest")
    draw_sub(@context, @bone_rt, "latest")
    draw_sub(@context, @bone_lt, "latest")
    @surface.write_to_png (filename);
  end

  def predraw(preexams) # preexams は以前のデータの配列，要素はAudiodata
                        # preexams[0]が最も新しいデータ
    revert_exams = Array.new
    predata_n = Overdraw_times - 1
    element_n = (preexams.length < predata_n)? preexams.length: predata_n
               # 要素数か(重ね書き数-1)の小さい方の数を有効要素数とする
    element_n.times do |i|
      revert_exams[i] = preexams[element_n-i-1]
    end        # 古い順に並べ直す

    # 有効な要素の中で古いものから描いていく
    element_n.times do |i|
      exam = revert_exams[i]
      timing = "pre#{i}"
      draw_sub(exam.extract[:ra], timing)
      draw_sub(exam.extract[:la], timing)
      draw_sub(exam.extract[:rb], timing)
      draw_sub(exam.extract[:lb], timing)
    end
  end

end

#----------------------------------------#
if ($0 == __FILE__)
  ra = ["0","10","20","30","40","50","60"]
  la = ["1","11","21","31","41","51","61"]
  rm = ["b0","b10","b20","b30","b40","b50","b60"]
  lm = ["w1","w11","w21","w31","w41","w51","w61"]

  dd = Audiodata.new("cooked", ra,la,ra,la,rm,lm,lm,rm)
  aa = Audio.new(dd)

  p aa.reg_mean4
  p aa.put_rawdata

  aa.draw("./test2.png")
end
