require "crsfml"

module Animatis
  class Bonus
    def self.map(n : Float64, start1 : Float64, stop1 : Float64, start2 : Float64, stop2 : Float64)
      return stop1 if (n > stop1)
      return ((n - start1) / (stop1 - start1)) * (stop2 - start2) + start2
    end
  end

  struct Kolor
    property red, green, blue, alpha

    def initialize(@red : Int32 = 255, @green : Int32 = 255, @blue : Int32 = 255, @alpha : Int32 = 255)
      @red %= 256
      @green %= 256
      @blue %= 256
      @alpha %= 256
    end

    def hex
      "#{@red.to_s(16)}#{@green.to_s(16)}#{@blue.to_s(16)}"
    end

    def initialize(hex : String)
      raise "Not a valid hex value" if (hex.size != 6)
      @red = hex[0..1].to_i(16)
      @green = hex[2..3].to_i(16)
      @blue = hex[0..1].to_i(16)
      @alpha = 255
    end

    def self.hsv_new(h : Int32 = 360, s : Int32 = 100, v : Int32 = 100) : Kolor
      h %= 360
      s /= 100
      v /= 100

      c = v * s
      x = c * (1 - ((h / 60) % 2 - 1).abs)
      m = v - c

      r = g = b = 0

      if (h < 60)
        r, g, b = c, x, 0
      elsif (h < 120)
        r, g, b = x, c, 0
      elsif (h < 180)
        r, g, b = 0, c, x
      elsif (h < 240)
        r, g, b = 0, x, c
      elsif (h < 360)
        r, g, b = c, 0, x
      end

      red = ((r + m) * 255).to_i32
      green = ((g + m) * 255).to_i32
      blue = ((b + m) * 255).to_i32

      Kolor.new(red, green, blue)
    end

    def rgb
      {@red, @green, @blue}
    end

    def rgba
      {@red, @green, @blue, @alpha}
    end
  end

  class Kanvas
    property fill_color : Kolor = Kolor.new, stroke_color : Kolor = Kolor.new
    property no_fill : Bool = false, no_stroke : Bool = false
    property stroke_weight : Float32 = 0
    property fps : Int32 = 60
    property sleeping : Bool = false

    @each_frame : (Array(SF::Event)) -> = ->(events : Array(SF::Event)) {}
    @elapsed_time_since_last_update : Int64 = 0
    @translated_x = 0
    @translated_y = 0

    def initialize(width : Int32, height : Int32)
      @window = SF::RenderWindow.new(SF::VideoMode.new(width, height), "Animation")
    end

    def start
      clock = SF::Clock.new
      # run the program as long as the window is open
      # @window.clear(SF::Color::Black)
      while @window.open?
        events = [] of SF::Event
        # check all the window's events that were triggered since the last iteration of the loop
        while event = @window.poll_event
          case event
          when .is_a? SF::Event::Closed # "close requested" event: we close the window
            @window.close
          end
          events << event
        end

        elapsed = clock.restart
        update_game(elapsed.as_microseconds, events)
      end
    end

    protected def update_game(dt : Int64, events : Array(SF::Event))
      return if @sleeping

      @elapsed_time_since_last_update += dt

      timeToTotalWait = (1000000 / @fps).to_i64

      if (@elapsed_time_since_last_update >= timeToTotalWait)
        # clear the canvas
        @each_frame.call(events)

        @translated_x = 0
        @translated_y = 0

        # end the current frame
        @window.display

        @elapsed_time_since_last_update = 0
      end

      # while (@elapsed_time_since_last_update >= timeToTotalWait)
      #   # clear the canvas
      #   @each_frame.call(events)

      #   @translated_x = 0
      #   @translated_y = 0

      #   # end the current frame
      #   @window.display

      #   @elapsed_time_since_last_update -= timeToTotalWait
      # end
    end

    def background(color : Kolor)
      @window.clear(SF::Color.new(*color.rgba))
    end

    def each_frame(&block : Array(SF::Event) ->)
      @each_frame = block
    end

    def rectangle(x : Int32, y : Int32, width : Int32, height : Int32)
      rectangle = SF::RectangleShape.new SF.vector2(width, height)
      rectangle.position = SF.vector2(x + @translated_x, y + @translated_y)
      update_shape(rectangle)
      @window.draw rectangle
    end

    def circle(x : Int32, y : Int32, radius : Int32)
      circle = SF::CircleShape.new(radius)
      circle.position = SF.vector2(x + @translated_x, y + @translated_y)
      update_shape(circle)
      @window.draw circle
    end

    protected def update_shape(shape : SF::Shape)
      shape.outline_color = SF::Color.new(*@stroke_color.rgba)
      shape.outline_thickness = @no_stroke ? 0 : @stroke_weight

      shape.fill_color = @no_fill ? SF::Color::Transparent : SF::Color.new(*@fill_color.rgba)
    end

    def translate(@translated_x : Int32, @translated_y : Int32)
    end
  end

  struct Vector2D
    property x : Float64 = 0
    property y : Float64 = 0

    def initialize(@x : Float64, @y : Float64)
    end

    def initialize(angle : Float64)
      calculate_pos(angle, 1)
    end

    protected def calculate_pos(dir : Float64, inputMag : Float64) : Vector2D
      x = Math.cos(dir) * inputMag
      y = Math.sin(dir) * inputMag
      Vector2D.new(x, y)
    end

    def mag : Float64
      Math.sqrt(@x * @x + @y * @y)
    end

    def heading : Float64
      if (@x == 0)
        return 0.0 if (y == 0)
        return Math::PI if (y > 0)
        return Math::PI * 2 if (y < 0)
      end

      dir = Math.atan(@y / @x)

      if (@x > 0 && @y >= 0)
      elsif (@x < 0 && @y > 0)
        dir += Math::PI
      elsif (@x < 0 && @y <= 0)
        dir += Math::PI
      elsif (@x > 0 && @y < 0)
        dir += Math::PI * 2
      end

      return dir % (Math::PI * 2)
    end

    def limit(max : Float64) : Vector2D
      return set_mag(max) if mag > max
      Vector2D.new(@x, @y)
    end

    def set_mag(inputMag : Float64) : Vector2D
      calculate_pos(heading, inputMag)
    end

    def rotate(angle : Float64) : Vector2D
      newAngle = (heading + angle) % (Math::PI * 2)
      calculate_pos(newAngle, mag)
    end

    def +(otherV : Vector2D) : Vector2D
      Vector2D.new(@x + otherV.x, @y + otherV.y)
    end

    def -(otherV : Vector2D) : Vector2D
      Vector2D.new(@x - otherV.x, @y - otherV.y)
    end

    def *(otherV : Vector2D) : Vector2D
      Vector2D.new(@x * otherV.x, @y * otherV.y)
    end

    def /(otherV : Vector2D) : Vector2D
      Vector2D.new(@x / otherV.x, @y / otherV.y)
    end
  end

  struct ComplexNumber
    property a : Float64, b : Float64

    # Complex number: a + bi

    def initialize(@a : Float64, @b : Float64)
    end

    def self.polar_new(abs : Float64, arg : Float64) : ComplexNumber
      a = abs * Math.cos(arg)
      b = abs * Math.sin(arg)
      ComplexNumber.new(a, b)
    end

    def ==(otherC : ComplexNumber) : Bool
      (@a == otherC.a && @b == otherC.b)
    end

    def !=(otherC : ComplexNumber) : Bool
      (@a != otherC.a || @b != otherC.b)
    end

    # gets the complex conjugate
    def conjugate : ComplexNumber
      ComplexNumber.new(@a, -@b)
    end

    def abs : Float64
      Math.sqrt(@a * @a + @b * @b)
    end

    def arg : Float64
      value : Float64 = 0
      if (@a > 0 || @b != 0)
        value += (2 * Math.atan(@b / (abs + @a)))
      elsif (@a < 0 && @b == 0)
        value += Math::PI
      elsif (@a == 0 && @b == 0)
        value += 0
      end
      value += 2 * Math::PI if (value < 0)
      return value
    end

    def +(otherC : ComplexNumber) : ComplexNumber
      ComplexNumber.new(@a + otherC.a, @b + otherC.b)
    end

    def -(otherC : ComplexNumber) : ComplexNumber
      ComplexNumber.new(@a - otherC.a, @b - otherC.b)
    end

    def *(otherC : ComplexNumber) : ComplexNumber
      ComplexNumber.new((@a * otherC.a - @b * otherC.b), (@a * otherC.b + @b * otherC.a))
    end

    def **(power : Int32) : ComplexNumber
      res = self
      while power > 1
        res = res * self
        power -= 1
      end
      res
    end

    def reciprocal : ComplexNumber
      part : Float64 = @a * @a + @b * @b
      ComplexNumber.new(@a / part, -@b / part)
    end

    def /(otherC : ComplexNumber) : ComplexNumber
      self * otherC.reciprocal
    end

    def sqrt : ComplexNumber
      return ComplexNumber.new(Math.sqrt(@a), 0) if (@b == 0)
      gamma = Math.sqrt((@a + abs) / 2)
      sigma = @b.sign * Math.sqrt((-@a + abs) / 2)
      ComplexNumber.new(gamma, sigma)
    end

    def self.mandelbrot(c : ComplexNumber, limit : Int32) : Int32
      i : Int32 = 0
      z = ComplexNumber.new(0, 0)
      while i < limit
        z = (z * z) + c
        i += 1
        return i if (z.abs > 2)
      end
      return -1
    end
  end
end

CANVAS_SIZE = 1000

cube_size = 5
zoom = 1
limit = 100

off_set_x = 0
off_set_y = 0

canvas = Animatis::Kanvas.new(CANVAS_SIZE, CANVAS_SIZE)
canvas.background(Animatis::Kolor.new("000000"))
canvas.no_stroke = true

canvas.each_frame do |events|
  events.each do |event|
    case event
    when SF::Event::KeyPressed
      case event.code
      when SF::Keyboard::Left, SF::Keyboard::A
        off_set_x -= 0.5 / zoom
      when SF::Keyboard::Right, SF::Keyboard::D
        off_set_x += 0.5 / zoom
      when SF::Keyboard::Up, SF::Keyboard::W
        off_set_y -= 0.5 / zoom
      when SF::Keyboard::Down, SF::Keyboard::S
        off_set_y += 0.5 / zoom
      when SF::Keyboard::Add
        cube_size -= 1
      when SF::Keyboard::Subtract
        cube_size += 1
      when SF::Keyboard::Multiply
        limit = (limit * 1.5).to_i
      when SF::Keyboard::Divide
        limit = (limit * 0.5).to_i
      end
    when SF::Event::MouseWheelScrolled
      zoom += zoom * (event.delta / 5)
    end
  end

  canvas.background(Animatis::Kolor.new("000000"))

  y = 0
  while (y <= CANVAS_SIZE - cube_size)
    x = 0
    while (x <= CANVAS_SIZE - cube_size)
      a = Animatis::Bonus.map(x.to_f64, 0.0, CANVAS_SIZE.to_f64, -2.0 / zoom + off_set_x, 2.0 / zoom + off_set_x)
      b = Animatis::Bonus.map(y.to_f64, 0.0, CANVAS_SIZE.to_f64, -2.0 / zoom + off_set_y, 2.0 / zoom + off_set_y)

      z = Animatis::ComplexNumber.new(a, b)

      i = Animatis::ComplexNumber.mandelbrot(z, limit)

      if (i == -1)
        canvas.fill_color = Animatis::Kolor.new(0, 0, 0)
      else
        color = Animatis::Bonus.map(i.to_f64, 0.0, limit.to_f64, 0.0, 1.0)
        color = Animatis::Bonus.map(Math.sqrt(color), 0.0, 1.0, 0.0, 360)
        canvas.fill_color = Animatis::Kolor.hsv_new(color.to_i, 100, 100)
      end

      canvas.rectangle(x, y, cube_size, cube_size)
      x += cube_size
    end
    y += cube_size
  end
end

canvas.start
