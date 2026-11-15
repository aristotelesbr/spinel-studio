# A faceted red gem, the program's nod to Ruby: drawn with the Canvas,
# brighter facets on the crown, darker on the pavilion, over a white
# outline. Not the Ruby logo, a gem of its own.
module RubyGem
  OUTLINE = 0xFFFFFFFF
  # Crown (left, table, right), then pavilion (left, middle, right).
  FACETS = [0xFFF0566A, 0xFFFF8A94, 0xFFD8304A, 0xFFB01830, 0xFFCC2240, 0xFF8C0F24].freeze

  BODY = 0xFFC0203A   # under the facets, so no seam shows between them

  # The gem centered on (x, y), width wide.
  def self.draw(canvas, x, y, width)
    outline = width * 0.1
    canvas.fill_polygon(silhouette(x, y, width + outline * 2, outline), OUTLINE)
    canvas.fill_polygon(silhouette(x, y, width, 0.0), BODY)
    facets(x, y, width, 0.0).each_with_index { |points, index| canvas.fill_polygon(points, FACETS[index]) }
  end

  # The gem's outline: girdle corners, table corners and the tip.
  def self.silhouette(x, y, width, grow)
    corners = facets(x, y, width, grow)
    [corners[0][0], corners[1][0], corners[1][1], corners[2][1], corners[3][2]]
  end

  # The six facets of a gem width wide, its girdle a little above y.
  def self.facets(x, y, width, grow)
    half = width / 2
    top = y - width * 0.34
    girdle = y - width * 0.1
    bottom = y + width * 0.42 + grow * 0.4
    table = width * 0.3
    inner = width * 0.17
    left = [x - half, girdle]
    right = [x + half, girdle]
    table_left = [x - table, top]
    table_right = [x + table, top]
    inner_left = [x - inner, girdle]
    inner_right = [x + inner, girdle]
    tip = [x, bottom]
    # each listed clockwise on screen, as Canvas#fill_polygon takes them
    [[left, table_left, inner_left], [table_left, table_right, inner_right, inner_left], [table_right, right, inner_right],
     [left, inner_left, tip], [inner_left, inner_right, tip], [inner_right, right, tip]]
  end

end
