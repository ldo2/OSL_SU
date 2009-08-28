# Copyright 2009 Levchenko Denis.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name        :   OSL SU Bezier Curves 1.0 alpha
# Description :   Bezier curves class definition, than implements some basic methods for it
# Menu Item   :   NONE
# Context Menu:   NONE
# Usage       :
#             :
#             :
# Date        :   26.08.2009
# Type        :   Utils
#-----------------------------------------------------------------------------

require 'sketchup.rb'

require 'osl_su_core/class_language_handler.rb'
require 'osl_su_core/math/binomial_coefficient.rb'

#
# Класс кривых Безье
#
class BezierCurve 
  # подмешиваем обработчик текстовых надписей
  include ClassLanguageHandler
  
  # кол-во ребер кривой отображаемых по умолчанию	
  DEFAULT_STEPS_COUNT = 16

  # Перечисляем атрибуты доступные для чтения
  attr_reader :steps_count, :points

  # конструктор класса
  # args - список контрольных точек, заданных объектами Geom::Point3d 
  #        или масссивами вида [x, y, z], также в конце можно указать 
  #        кол-во ребер, которым должна быть отображена кривая
  def initialize(*args)
    last_arg = args.pop
    
    # бросаем исключительную ситуацию, если передано неверное кол-во аргументов
    if args.size < 2 && last_arg.kind_of?(Fixnum)
      raise ArgumentError.new("Not enough points - at least 2 required")
    end   
    # проверяем заданное кол-во отображаемых ребер
    if last_arg.kind_of?(Fixnum) && last_arg < 1
      raise ArgumentError.new("Wrong steps count for creating a curve - at least 1 required")
    end
    
    @points = Array.new
    @steps_count = DEFAULT_STEPS_COUNT
    
    args.each do |point|
      @points << Geom::Point3d.new(point)
    end
    
    # в зависимости от того, является ли последний аргумент числом или нет
    # устанавливаем кол-во отображаемых ребер или добавляем еще одну контрольную точку
    if last_arg.kind_of?(Fixnum)
      @steps_count = last_arg
    else
      @points << Geom::Point3d.new(last_arg)
    end
  end
  
  # Создать кривую Безье в SketchUp'е
  def draw
    model = Sketchup.active_model
    entities = model.entities
    
    model.start_operation(get_string("Draw" + self.class.name))
    
    edges = entities.add_curve(curve_points)
    save(edges.first.curve)
    
    model.commit_operation
    
    edges
  end
  
  def curve_points
    # определяем шаг изменения параметра кривой
    # в зависимости от кол-ва точек
    param_step = 1.0/@steps_count
    # устанавливаем начальное значение параметра
    # (прим. параметр изменяется от 0.0 до 1.0 
    #  с шагом 1.0/@steps_count)
    param = 0.0
    # создаем массив возвращаемых точек
    Array.new(@steps_count+1) do
      point = calculate_point(param)
      param += param_step
      point
    end
  end
  
  def calculate_point(t)
    # преобразуем аргумент в дробное число
    t = t.to_f if t.class.method_defined?(:to_f)
    
    # проверка правильности типа аргумента
    #~ if !t.kind_of?(Float)
    #~   raise ArgumentError.new("Cannot convert argument to Float")
    #~ end

    # получаем степень кривой Безье
    degree = @points.size - 1
    if degree < 1
      raise TypeError.new("Wrong #{self.class.name} object - invalid control points array")
    end

    # Вычисляем координаты точки по параметризации:
    # B(t)= \sum^n_{i=0} [ P_i * C(n, i) * t^i * (1-t)^(n-i) ] , 0<t<1, 
    # где C(n, i) - число сочетаний из n по i (биномиальный коэффициент).
    # B(t) вычисляем по схеме Горнера, как полином, зависящий от q = 1-t,
    # степени t при этом относим к коэффициентам, а для эффективности 
    # сохраняем значение степени на предыдущей итерации в переменной power_t
    q = 1.0 - t
    power_t = 1.0
    x, y, z = 0, 0, 0
    @points.each_with_index do |point, i|
      b_i = BinomialCoefficient.coefficient(degree, i)*power_t
      x = x*q + b_i*point.x
      y = y*q + b_i*point.y
      z = z*q + b_i*point.z
      power_t *= t 
    end

    Geom::Point3d.new(x, y, z)
  end

  def save(curve)
    return false if !curve.kind_of?(Sketchup::Curve)
    # сохраняем переменные
    curve.set_attribute("osl", "class", self.class.name)
    curve.set_attribute("osl", "points", @points)
    curve.set_attribute("osl", "steps_count", @steps_count)
    return true
  end
  
  def self.load(curve)
    if !curve.kind_of?(Sketchup::Curve) || curve.get_attribute("osl", "class") != self.name
      return nil 
    end
    # создаем кривую по сохраненным данным
    args = curve.get_attribute("osl", "points")
    args << curve.get_attribute("osl", "steps_count")
    self.new(*args)
  end
  
end

#
# Класс кубических кривых Безье
# В данном классе внесены некоторые упрощения
#
class CubicBezierCurve < BezierCurve
  def initialize(start_point, start_control, end_control, end_point, steps_count = DEFAULT_STEPS_COUNT)
    super(start_point, start_control, end_control, end_point, steps_count)
  end

  def calculate_point(t)
    # преобразуем аргумент в дробное число
    t = t.to_f if t.class.method_defined?(:to_f)
    
    # проверка правильности типа аргумента
    #~ if !t.kind_of?(Float)
    #~   raise ArgumentError.new("Cannot convert argument to Float")
    #~ end

    # Вычисляем координаты точки по параметризации:
    # B(t)= P_0*q^3 + 3*P_1*q^2*t + 3*P_2*q*t^2 + P_3*t^3 , 0<t<1, 
    # где C(n, i) - число сочетаний из n по i (биномиальный коэффициент).
    q = 1.0 - t
    tt, qq = t*t, q*q
    c1, c2, c3, c4 = qq*q, 3.0*t*qq, 3.0*tt*q, tt*t
    
    Geom::Point3d.new(
      @points[0].x*c1 + @points[1].x*c2 + @points[2].x*c3 + @points[3].x*c4,
      @points[0].y*c1 + @points[1].y*c2 + @points[2].y*c3 + @points[3].y*c4,
      @points[0].z*c1 + @points[1].z*c2 + @points[2].z*c3 + @points[3].z*c4
    )
  end
end

