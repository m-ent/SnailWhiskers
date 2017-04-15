#!/usr/local/bin/ruby
#  Class Audio: 聴検データ取扱い用クラス
#  Copyright 2007-2009 S Mamiya
#  0.20091107
#  0.20120519 : chunky_PNGのgemを使用、ruby1.9対応
#  0.20120805 : rails支配下の時とそうでないときのライブラリの場所を分けた
#  0.20121102 : class Bitmapを別ファイルに分離

if defined? Rails
  require 'AA79S.rb'
  require 'bitmap.rb'
else
  require_relative './AA79S.rb'
  require_relative './bitmap.rb'
end

# railsの場合，directoryの相対表示の起点は rails/audiserv であるようだ
Overdraw_times = 2  # 重ね書きの回数．まずは2回，つまり1回前の検査までとする

class Audio < Bitmap
  X_pos = [70,115,160,205,250,295,340]   # 各周波数別の横座標

  def initialize(audiodata)              # 引数はFormatted_data のインスタンス
    if File.exist?(Image_parts_location+"background_audiogram.png")
      @png = ChunkyPNG::Image.from_file(Image_parts_location+"background_audiogram.png")
    else
      @png = ChunkyPNG::Image.new(400,400,WHITE)
      prepare_font
      draw_lines
      add_fonts
      @png.save(Image_parts_location+"background_audiogram.png", :fast_rgba)
    end
    @audiodata = audiodata
    @air_rt  = @audiodata.extract[:ra]
    @air_lt  = @audiodata.extract[:la]
    @bone_rt = @audiodata.extract[:rb]
    @bone_lt = @audiodata.extract[:lb]
  end

  def draw_lines               # audiogramの縦横の線を引いている
    y1=30
    y2=348
    line(@png, 50,y1,50,y2,GRAY,"line")
    for x in 0..6
      x1=70+x*45
      line(@png, x1,y1,x1,y2,GRAY,"line")
    end
    line(@png, 360,y1,360,y2,GRAY,"line")
    x1=50
    x2=360
    line(@png, x1,30,x2,30,GRAY,"line")
    line(@png, x1,45,x2,45,GRAY,"line")
    line(@png, x1,69,x2,69,BLACK,"line")
    for y in 0..10
      y1=93+y*24
      line(@png, x1,y1,x2,y1,GRAY,"line")
    end
    line(@png, x1,348,x2,348,GRAY,"line")
  end

  def add_fonts
    # add vertical scale
    for i in -1..11
      x = 15
      hear_level = (i * 10).to_s
      y = 69 + i *24 -7
      x += (3 - hear_level.length) * 8
      hear_level.each_byte do |c|
        if c == 45                  # if character is "-"
          put_font(@png, x, y, "minus")
        else
          put_font(@png, x, y, "%c" % c)
        end
        x += 8
      end
    end
    put_font(@png, 23, 15, "dB")

    # add holizontal scale
    cycle = ["125","250","500","1k","2k","4k","8k"]
    for i in 0..6
      y = 358
      x = 70 + i * 45 - cycle[i].length * 4 # 8px for each char / 2
      cycle[i].each_byte do |c|
        put_font(@png, x, y, "%c" % c)
        x += 8
      end
    end
    put_font(@png, 360, 358, "Hz")
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

  def draw_sub(audiodata, timing)
    case timing  # timingは重ね書き用の引数で検査の時期がもっとも古いものは
                 # pre0，やや新しいものは pre1とする
    when "pre0"
      rt_color = RED_PRE0
      lt_color = BLUE_PRE0
      bc_color = BLACK_PRE0
    when "pre1"
      rt_color = RED_PRE1
      lt_color = BLUE_PRE1
      bc_color = BLACK_PRE1
    else
      rt_color = RED
      lt_color = BLUE
      bc_color = BLACK    
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
            put_symbol(@png, :circle, X_pos[i], threshold[i] / 10 * 24 + 69, rt_color)
            if scaleout[i]
              put_symbol(@png, :r_scaleout, X_pos[i], threshold[i] / 10 * 24 + 69, rt_color)
            end
          when "Bone"
            put_symbol(@png, :r_bracket, X_pos[i], threshold[i] / 10 * 24 + 69, bc_color)
            if scaleout[i]
              put_symbol(@png, :r_scaleout, X_pos[i], threshold[i] / 10 * 24 + 69, bc_color)
            end
          end
        when "Lt"
          case audiodata[:mode]
          when "Air"
            put_symbol(@png, :cross, X_pos[i], threshold[i] / 10 * 24 + 69, lt_color)
            if scaleout[i]
              put_symbol(@png, :l_scaleout, X_pos[i], threshold[i] / 10 * 24 + 69, lt_color)
            end
          when "Bone"
            put_symbol(@png, :l_bracket, X_pos[i], threshold[i] / 10 * 24 + 69, bc_color)
            if scaleout[i]
              put_symbol(@png, :l_scaleout, X_pos[i], threshold[i] / 10 * 24 + 69, bc_color)
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
        line_from = [X_pos[i],(threshold[i] / 10 * 24 + 69).to_i]
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
            line_to = [X_pos[j],(threshold[j] / 10 * 24 + 69).to_i]
            case audiodata[:side]
            when "Rt"
              line(@png, line_from[0],line_from[1],line_to[0],line_to[1],rt_color,"line")
            when "Lt"
              line(@png, line_from[0],line_from[1]+1,line_to[0],line_to[1]+1,lt_color,"dot")
            end
            i = j
            break
          end
        end
      end
    end
  end

  def draw(filename)
    draw_sub(@air_rt, "latest")
    draw_sub(@air_lt, "latest")
    draw_sub(@bone_rt, "latest")
    draw_sub(@bone_lt, "latest")

    output(@png, filename)
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
=begin
  datafile = "./Data/data_with_mask.dat"
  #datafile = "./Data/data1.dat"
  #datafile = "./Data/data2.dat"
  buf = String.new
  File.open(datafile,"r") do |f|
    buf = f.read
  end
  d = Audiodata.new("raw", buf)
  a = Audio.new(d)
  p a.mean6
  p a.put_rawdata
  
  puts "pre draw"
  
  a.draw
  
  puts "pre output"
  
  a.output("./test.ppm")    
=end
#----------
  ra = ["0","10","20","30","40","50","60"]
  la = ["1","11","21","31","41","51","61"]
  rm = ["b0","b10","b20","b30","b40","b50","b60"]
  lm = ["w1","w11","w21","w31","w41","w51","w61"]

  dd = Audiodata.new("cooked", ra,la,ra,la,rm,lm,lm,rm)
  aa = Audio.new(dd)

  p aa.reg_mean4
  p aa.put_rawdata

#  aa.draw
#  aa.output("./test.png")
aa.draw("./test2.png")

end
