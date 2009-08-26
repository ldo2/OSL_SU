# Copyright 2009 Levchenko Denis

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------

# Ядро библиотеки, содержащее модули, классы и методы, используемые в 
# плагинах, инструментах и расширениях.

require 'sketchup.rb'
require 'extensions.rb'
require 'LangHandler.rb'

$osl_su_core_strings = LanguageHandler.new("osl_su_core.strings")

osl_su_core_ext = SketchupExtension.new($osl_su_core_strings.GetString("OSL SU Core"), "osl_su_core/osl_su_core.rb")
                    
osl_su_core_ext.description = $osl_su_core_strings.GetString("Adds modules, classes and methods from Open Scripts Library for Google SketchUp.")
                        
Sketchup.register_extension(osl_su_core_ext, false)

