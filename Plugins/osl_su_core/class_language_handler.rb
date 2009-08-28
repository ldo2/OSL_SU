# Copyright 2009 Levchenko Denis.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name        :   OSL SU ClassLanguageHandler 1.0 alpha
# Description :   Describes a module that loads string-file automaticly for 
#             : class in which it was included and defines <get_string> method for it
# Menu Item   :   NONE
# Context Menu:   NONE
# Usage       :
#             :
#             :
# Date        :   27.08.2009
# Type        :   Utils
#-----------------------------------------------------------------------------

require 'sketchup.rb'
require 'langhandler.rb'

#
# После подмешивания данного модуля в класс 
# можно использовать метод класса или метод 
# экземпляра <get_string> для получения строк
# из strings-файла с именем определяемым 
# в методе класса <strings_file> или, если
# такой метод не определен, совпадающим 
# с именем класса
#
module ClassLanguageHandler

  module ClassMethods
    def create_language_handler
      str_file_name =  self.methods.include?("strings_file") ? self.strings_file : self.name
      LanguageHandler.new(str_file_name + (str_file_name =~ /\.strings$/ ? "" : ".strings"))
    end

    def get_string(str)
      begin
        @@strings ||= create_language_handler
        @@strings.GetString(str)
      rescue
        str
      end
    end 
  end
  
  def self.included(base)
    base.extend(ClassLanguageHandler::ClassMethods)
  end

  def get_string(str)
    self.class.get_string(str)
  end

end