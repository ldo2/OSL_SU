# Copyright 2009 Levchenko Denis.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name        :   OSL SU Bezier Surface 1.0 alpha
# Description :   Bezier surface class definition, than implements some basic methods for it
# Menu Item   :   NONE
# Context Menu:   NONE
# Usage       :
#             :
#             :
# Date        :   28.08.2009
# Type        :   Utils
#-----------------------------------------------------------------------------

require 'sketchup.rb'

require 'osl_su_core/class_language_handler.rb'
require 'osl_su_core/math/binomial_coefficient.rb'

#
# Класс поверхностей Безье
#
class BezierSurface 
  # подмешиваем обработчик текстовых надписей
  include ClassLanguageHandler
  
  # кол-во шагов по UV карте при отображении используемое по умолчанию	
  DEFAULT_STEPS_COUNT = 16

  # конструктор класса, получает следующие возможные аргументы:
  #   1. Ассоциативный массив (Хэш) вида <имя_поля> => <значение>
  #   2. Двумерный массив контрольных точек, и необязательные аргументы
  #      кол-во шагов по оси U и кол-во шагов по оси V
  #   3. Список массивов контрольных точек и необязательные аргументы
  #      кол-во шагов по оси U и кол-во шагов по оси V
  def initialize(*args)
    if args.size == 1 && args.first.kind_of?(Hash)
      initialize_from_hash(args.first)
    else if (1..3).include?(args.size) && args.first.kind_of?(Array) && args.first[0].kind_of?(Array)
      initialize_from_array(*args)
    else if args.size >= 2 
      initialize_from_list(*args)
    end
  end

  private

  # private-методы инициализирующие объект от разных аргументов

  def initialize_from_hash(hash)
    @points = hash["points"]
    @steps_u = hash["steps_u"] || DEFAULT_STEPS_COUNT
    @steps_v = hash["steps_v"] || DEFAULT_STEPS_COUNT

    unless validate_points
      raise ArgumentError.new("Wrong control points array in hash constructor type")
    end

    unless validate_steps
      raise ArgumentError.new("Wrong U or V steps in hash constructor type")
    end
  end

  def initialize_from_array(array, steps_u = DEFAULT_STEPS_COUNT, steps_v = DEFAULT_STEPS_COUNT)
    @points = array
    @steps_u = steps_u
    @steps_v = steps_v

    unless validate_points
      raise ArgumentError.new("Wrong control points array in array constructor type")
    end

    unless validate_steps
      raise ArgumentError.new("Wrong U or V steps in array constructor type")
    end
  end

  def initialize_from_list(*args)
    @steps_u = DEFAULT_STEPS_COUNT
    @steps_v = DEFAULT_STEPS_COUNT

    @steps_u = args.pop if args.last.kind_of?(Fixnum)
    @steps_u, @steps_v = args.pop, @steps_u if args.last.kind_of?(Fixnum) 

    @points = args

    unless validate_points
      raise ArgumentError.new("Wrong control points array in list constructor type")
    end

    unless validate_steps
      raise ArgumentError.new("Wrong U or V steps in list constructor type")
    end
  end

  public

  def validate_points
    # not implemented
    true
  end

  def validate_steps
    # not implemented
    true
  end

  def draw
    model = Sketchup.active_model
    entities = model.entities
    
    model.start_operation(get_string("Draw" + self.class.name))
    
    face = entities.add_faces_from_mesh(face_mesh)
    save(face)
    
    model.commit_operation
    
    face
  end

  def face_mesh
    mesh = Geom::PolygonMesh.new

    du, dv = 1.0/@steps_u, 1.0/@steps_v
    u, v = 0.0, 0.0

    points = Array.new(@steps_u + 1) do
      v = 0.0
      v_points = Array.new(@steps_v + 1) do
        point = calculate_point(u, v)
        mesh.add_point(point)
        v += dv
        point
      end
      u += du
      v_points
    end

    for i in 0 ... @steps_u
      for j in 0 ... @steps_v
        mesh.add_polygon(
          mesh.point_index(points[i][j]),
          mesh.point_index(points[i+1][j]),
          mesh.point_index(points[i+1][j+1])
        )
        mesh.add_polygon(
          mesh.point_index(points[i][j]),
          mesh.point_index(points[i+1][j+1]),
          mesh.point_index(points[i][j+1])
        )
      end
    end

    mesh
  end

  def calculate_point(u, v)
    # преобразуем аргументы в дробные числа
    u = u.to_f if u.class.method_defined?(:to_f)
    v = v.to_f if v.class.method_defined?(:to_f)
    
    # проверка правильности типов аргументов
    #~ if !u.kind_of?(Float)
    #~   raise ArgumentError.new("Cannot convert argument to Float")
    #~ end
    #~ if !v.kind_of?(Float)
    #~   raise ArgumentError.new("Cannot convert argument to Float")
    #~ end

    # Вычисляем координаты точки по параметризации:
    # P(u, v) = \sum^n_{i=0} { C(n, i)*u^i*u^(n-i) * 
    #             \sum^m_{j=0} [ C(m, j)*v^j*v^(m-j)*P_{i,j}]},
    # где 0<u<1, 0<v<1, n и m - степени поверхности по u и v соответственно, 
    # а C(n, k) - число сочетаний из n по k (биномиальный коэффициент).
    x, y, z = 0.0, 0.0, 0.0

    t, s = 1.0 - u, 1.0 - v
    power_u, power_v = 1.0, 1.0
    u_degree, v_degree = @points.size-1, @points.first.size-1

    @points.each_with_index do |points_row, i|
      x_sum_j, y_sum_j, z_sum_j = 0.0, 0.0, 0.0
      power_v = 1.0
      points_row.each_with_index do |point, j|
        b_j = BinomialCoefficient.coefficient(v_degree, j)*power_v
        x_sum_j = x_sum_j*s + b_j*point.x
        y_sum_j = y_sum_j*s + b_j*point.y
        z_sum_j = z_sum_j*s + b_j*point.z
        power_v *= v 
      end

      b_i = BinomialCoefficient.coefficient(u_degree, i)*power_u
      x, y, z = x*t + b_i*x_sum_j, y*t + b_i*y_sum_j, z*t + b_i*z_sum_j
      power_u *= u 
    end

    Geom::Point3d.new(x, y, z)
  end

  def save(face)
    return false if !face.kind_of?(Sketchup::Face)
    # сохраняем переменные
    face.set_attribute("osl", "class", self.class.name)
    face.set_attribute("osl", "points", @points)
    face.set_attribute("osl", "steps_u", @steps_u)
    face.set_attribute("osl", "steps_v", @steps_v)
    return true
  end
  
  def self.load(face)
    if !face.kind_of?(Sketchup::Face) || face.get_attribute("osl", "class") != self.name
      return nil 
    end
    # создаем поверхность по сохраненным данным
    self.new(face.attribute_dictionary("osl"))
  end

end

#
# Класс бикубических поверхностей Безье
# В данном классе внесены некоторые упрощения
#
class BicubicBezierSurface < BezierSurface
end
