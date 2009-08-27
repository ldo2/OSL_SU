# Copyright 2009 Levchenko Denis.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name        :   OSL SU Selection Additions 1.0 alpha
# Description :   This file defines some additional methods for Sketchup::Selection
# Menu Item   :   NONE
# Context Menu:   NONE
# Usage       :   
#             :   
#             :   
# Date        :   27.08.2009
# Type        :   Utils
#-----------------------------------------------------------------------------

#
# При написании ruby-сценариев часто необходимо выбрать некоторые объекты 
# из выделения; например грани (faces), ребра (edges) и т.д. 
# Поэтому, чтобы не дублировать код подобных выборок в ruby-сценариях,
# добавлены соответствующие методы в класс Sketchup::Selection.
#

class Sketchup::Selection

  # Метод возвращает массив ребер (Sketchup::Edge), принадлежащих 
  # выделению. Если ни одно ребро не выделено, то в результате 
  # работы метода будет получен пустой массив [].
  def selected_edges
    edges = Array.new
    
    each do |element|
      edges << element if element.kind_of?(Sketchup::Edge)
    end
    
    edges
  end
  
  # Если в выделении присутствует единственное ребро, то метод вернет его,
  # иначе, если ребер было 2 и более или не было вовсе, возвращается nil.
  def selected_edge
    edge = nil
    
    each do |element|
      if edge.nil? && element.kind_of?(Sketchup::Edge)
        edge = element
      elsif element.kind_of?(Sketchup::Edge)
        edge = nil
        break
      end
    end
    
    edge
  end
  
  # Метод возвращает массив граней (Sketchup::Face), принадлежащих 
  # выделению. Если ни одна грань не выделена, то в результате 
  # работы метода будет получен пустой массив [].
  def selected_faces
    faces = Array.new
    
    each do |element|
      faces << element if element.kind_of?(Sketchup::Face)
    end
    
    faces
  end
  
  # Если в выделении присутствует единственная грань, то метод вернет ее,
  # иначе, если граней было 2 и более или не было вовсе, возвращается nil.
  def selected_face
    face = nil
    
    each do |element|
      if face.nil? && element.kind_of?(Sketchup::Face)
        face = element
      elsif element.kind_of?(Sketchup::Face)
        face = nil
        break
      end
    end
    
    face
  end
  
  # Метод возвращает массив объектов распознаваемых переданным блоком, 
  # принадлежащих выделению. 
  def selected_all
    objects = Array.new
    
    each do |element|
      objects << element if yield(element)
    end
    
    objects
  end
  
  # Если в выделении присутствует единственный объект распознаваемый 
  # переданным блоком, то метод вернет его, иначе, если объектов было 
  # два и более или не было вовсе, возвращается nil.
  def selected_one
    object = nil
    
    each do |element|
      is_element_included = yield(element)
      if object.nil? && is_element_included
        object = element
      elsif is_element_included
        object = nil
        break
      end
    end
    
    object
  end
  
end # of class Sketchup::Selection

