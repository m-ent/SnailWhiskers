#!/usr/local/bin/ruby
#  Class Bitmap: 検査結果グラフ出力用クラス
#  Copyright 20127-2009 S Mamiya
#  0.20121102 : audio_class.rbから分離

require 'chunky_png'
if defined? Rails
  Image_parts_location = "lib/assets/parts/" # Rails.rootから辿る形
else
  Image_parts_location = "./assets/parts/"   # Rails.rootに影響されない場合
end

# railsの場合，directoryの相対表示の起点は rails/audiserv であるようだ

class Bitmap
  RED =        0xff0000ff #[255,0,0]
  BLUE =       0x0000ffff #[0,0,255]
  RED_PRE0 =   0xff1e1eff #[255,30,30]
  RED_PRE1 =   0xff5a5aff #[255,90,90]
  BLUE_PRE0 =  0x1e1effff #[30,30,255]
  BLUE_PRE1 =  0x5a5affff #[90,90,255]
  BLACK =      0x000000ff #[0,0,0]
  BLACK_PRE0 = 0x1e1e1eff #[30,30,30]
  BLACK_PRE1 = 0x5a5a5aff #[90,90,90]
  WHITE =      0xffffffff #[255,255,255]
  GRAY =       0xaaaaaaff #[170,170,170]

  CIRCLE_PTN = [[-5,-2],[-5,-1],[-5,0],[-5,1],[-5,2],[-4,-3],[-4,3],\
    [-3,-4],[-3,4],[-2,-5],[-2,5],[-1,-5],[-1,5],[0,-5],[0,5],[1,-5],[1,5],\
    [2,-5],[2,5],[3,-4],[3,4],[4,-3],[4,3],[5,-2],[5,-1],[5,0],[5,1],[5,2]]
  CROSS_PTN = [[-5,-5],[-5,5],[-4,-4],[-4,4],[-3,-3],[-3,3],[-2,-2],[-2,2],\
    [-1,-1],[-1,1],[0,0],[1,-1],[1,1],[2,-2],[2,2],[3,-3],[3,3],[4,-4],[4,4],\
    [5,-5],[5,5]]
  R_BRA_PTN = [[-8,-5],[-8,-4],[-8,-3],[-8,-2],[-8,-1],[-8,0],[-8,1],[-8,2],\
    [-8,3],[-8,4],[-8,5],[-7,-5],[-7,5],[-6,-5],[-6,5]]
  L_BRA_PTN = [[8,-5],[8,-4],[8,-3],[8,-2],[8,-1],[8,0],[8,1],[8,2],[8,3],\
    [8,4],[8,5],[7,-5],[7,5],[6,-5],[6,5]]
  R_SCALEOUT_PTN = [[-3,12],[-4,13],[-5,6],[-5,7],[-5,8],[-5,9],\
    [-5,10],[-5,11],[-5,12],[-5,13],[-5,14],[-6,13],[-7,12]]
  L_SCALEOUT_PTN = [[3,12],[4,13],[5,6],[5,7],[5,8],[5,9],\
    [5,10],[5,11],[5,12],[5,13],[5,14],[6,13],[7,12]]
  SYMBOL_PTN = {:circle => CIRCLE_PTN, :cross => CROSS_PTN, :r_bracket => R_BRA_PTN,\
        :l_bracket => L_BRA_PTN, :r_scaleout => R_SCALEOUT_PTN, :l_scaleout => L_SCALEOUT_PTN}

  def initialize(width, height, color)
    @png = ChunkyPNG::Image.new(width, height, color)
    prepare_font
  end

  def point(png, x, y, rgb)
    png.set_pixel(x,y,rgb)
  end

  def swap(a,b)
    return b,a
  end

  def line(png, x1, y1, x2, y2, rgb, dotted)
    # Bresenhamアルゴリズムを用いた自力描画から変更
    if x1 > x2  # x2がx1以上であることを保証
      x1, x2 = swap(x1,x2)
      y1, y2 = swap(y1,y2)
    end
    sign_modifier = (y1 < y2)? 1 : -1 # yが減少していく時(右上がり)の符号補正
    case dotted
    when "line"
      png.line(x1,y1,x2,y2,rgb)
    when "dot"
      dx = x2 - x1
      dy = y2 - y1
      dot_length = 4
      step = (Math::sqrt ( dx * dx + dy * dy )) / dot_length
      sx = dx / step
      sy = dy / step
      c = rgb
      x_line_end = y_line_end = false
      x_to = x1
      y_to = y1

      until x_line_end && y_line_end do
        x_from = x_to
        y_from = y_to
        if (x_to = x_from+sx) >= x2  # x_from + sx が x_to を越えないように
          x_to = x2
          x_line_end = true
        end
        if (y_to = y_from+sy)*sign_modifier >= y2*sign_modifier 
	                            # y_from + sy が y_to を越えないように(符号補正つき)
          y_to = y2
          y_line_end = true
        end
        png.line(x_from.round, y_from.round, x_to.round, y_to.round, c)
        c = (c == WHITE)? rgb: WHITE
      end  
    end
  end

  def put_symbol(png, symbol, x, y, rgb) # symbol is Symbol, like :circle
    xr = x.round
    yr = y.round
    SYMBOL_PTN[symbol].each do |xy|
      point(png, xr+xy[0], yr+xy[1], rgb)
    end
  end

  def prepare_font
    font_name = ["0","1","2","3","4","5","6","7","8","9","dot",
                 "k","Hz","dB","minus","R","L","daPa","mL","ipsi","cntr"]
    @font = Hash.new
    font_name.each do |f|
      @font[f] = Array.new
      @font[f] << ChunkyPNG::Image.from_file(Image_parts_location+"#{f}.png")
      case f
      when "daPa","ipsi","cntr"
        @font[f] << 4  # 文字幅の情報
      when "Hz","dB","mL"
        @font[f] << 2  # 文字幅の情報
      else
        @font[f] << 1
      end
    end
  end

  def put_font(png, x1, y1, fontname)
    return if not @font[fontname]
    dx = @font[fontname][1] * 10
    dy = 15
    png.compose!(@font[fontname][0],x1,y1)
  end

  def output(png, filename)
    png.save(filename, :fast_rgba)
  end

  def dump(png)
    return png.to_datastream.to_blob
  end
end
