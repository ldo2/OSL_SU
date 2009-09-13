# Copyright 2009 Levchenko Denis.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name        :   OSL SU Bezier Triangle Surface 1.0 alpha
# Description :   Bezier triangle surface class definition, than implements some basic methods for it
# Menu Item   :   NONE
# Context Menu:   NONE
# Usage       :
#             :
#             :
# Date        :   13.09.2009
# Type        :   Utils
#-----------------------------------------------------------------------------

require 'sketchup.rb'

require 'osl_su_core/bezier_surface.rb'
#~require 'osl_su_core/class_language_handler.rb'
require 'osl_su_core/math/binomial_coefficient.rb'

#
# Класс поверхностей Безье
# Класс пока не реализован полностью
#
class BezierTriangle < BezierSurface 
  #~# подмешиваем обработчик текстовых надписей
  #~include ClassLanguageHandler

  def validate_points
    # not implemented
    true
  end

  def validate_steps
    # not implemented
    true
  end

  def face_mesh
    mesh = Geom::PolygonMesh.new

    du, dv = 1.0/@steps_u, 1.0/@steps_v
    u, v = 0.0, 0.0

    points = Array.new(@steps_u + 1) do |i|
      v = 0.0
      v_points = Array.new(@steps_v + 1 - i) do
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
          mesh.point_index(points[i][j+1]),
          mesh.point_index(points[i+1][j])
        )
        unless points[i+1][j+1].nil?
          mesh.add_polygon(
            mesh.point_index(points[i+1][j]),
            mesh.point_index(points[i][j+1]),
            mesh.point_index(points[i+1][j+1])
          )
        end
      end
    end

    mesh
  end

  def calculate_point(u, v)
    # TODO
    raise "not implemented now, comming soon"
  end

end


#
# Класс кубических треугольников Безье, барицентрических поверхностей Безье 3-го порядка
# В данном классе внесены некоторые упрощения
#
class BicubicBezierTriangle < BezierTriangle
  
  def degree_u
    3
  end

  def degree_v
    3
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
    # (a*v+b*t+g*u)^3 | 0<v<1, 0<t<1, 0<u<1, v+t+u = 1
    # P(u, v) = b^3*t^3 + 3*a*b^2*v*t^2 + 3*b^2*g*t^2*u + 
    # 3*a^2*b*v^2*t + 6*a*b*g*v*t*u + 3*b*g^2*t*u^2 + a^3*v^3 + 
    # 3*a^2*g*v^2*u + 3*a*g^2*v*u^2 + g^3*u^3
    # где t = 1-u-v, a^3, b^3, g^3, a^2*b, a*b^2, b^2*g, 
    # b*g^2, a*g^2, a^2*g и a*b*g контрольные точки треугольника.
    t = 1.0 - u - v
    tt, vv, uu = t*t, v*v, u*u
    coefs = tt*t, 3.0*v*tt, 3.0*tt*u, 3.0*vv*t, 6.0*v*t*u, 3.0*t*uu, vv*v, 3.0*vv*u, 3.0*v*uu, u*uu

    x, y, z = 0.0, 0.0, 0.0

    coefs.each_index do |i|
      x += @points[i].x*coefs[i]
      y += @points[i].y*coefs[i]
      z += @points[i].z*coefs[i]
    end

    Geom::Point3d.new(x, y, z)
  end
end
