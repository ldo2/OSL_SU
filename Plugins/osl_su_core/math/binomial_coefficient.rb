# Copyright 2009 Levchenko Denis.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name        :   OSL SU Binomial Coefficient 1.0 alpha
# Description :   Defines module that able to calculate binomial cooefficients
# Menu Item   :   NONE
# Context Menu:   NONE
# Usage       :
#             :
#             :
# Date        :   27.08.2009
# Type        :   Utils
#-----------------------------------------------------------------------------

module BinomialCoefficient

  @@pascal_triangle = [[1, 0]]

  # Метод увеличивающий кол-во строк треугольника Паскаля до n
  def self.extend_pascal_triangle(n)
    rownum = @@pascal_triangle.size
    while rownum <= n
      @@pascal_triangle[rownum] = Array.new(rownum+2) do |i|
        (i == rownum+1 ? 0 : @@pascal_triangle[rownum-1][i-1] + @@pascal_triangle[rownum-1][i])
      end
      rownum += 1
    end

    @@pascal_triangle.size
  end

  # Метод возвращающий биномиальный коэффициент
  # C(n, k) - число сочетаний из n по k.
  def self.coefficient(n, k)
    return 0 if k > n
    self.extend_pascal_triangle(n) if @@pascal_triangle.size <= n
    @@pascal_triangle[n][k]
  end
end