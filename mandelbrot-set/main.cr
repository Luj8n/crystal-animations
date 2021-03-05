require "animatis"

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
